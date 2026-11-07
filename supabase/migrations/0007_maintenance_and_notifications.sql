-- 0007_maintenance_and_notifications.sql

-- ================================================================ notifications
create type public.notification_kind as enum (
  'inquiry_message',
  'viewing_requested', 'viewing_confirmed', 'viewing_declined', 'viewing_cancelled',
  'lease_created', 'lease_ended', 'payment_recorded', 'payment_voided',
  'maintenance_created', 'maintenance_status', 'maintenance_comment'
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind public.notification_kind not null,
  -- Meaning only (ids, titles). The app builds the sentence in the user's language.
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_idx
  on public.notifications (user_id, created_at desc);
create index notifications_unread_idx
  on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;

-- No INSERT policy: rows are created only by push_notification() below.
create policy "notifications_select_own"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy "notifications_update_own"
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- The only editable column is read_at.
revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;

-- A notification that was read stays read.
create or replace function public.guard_notification_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  new.read_at := coalesce(old.read_at, new.read_at);
  return new;
end;
$$;

create trigger notifications_guard
  before update on public.notifications
  for each row execute function public.guard_notification_update();

create or replace function public.push_notification(
  p_user uuid, p_kind public.notification_kind, p_data jsonb
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_user is null then return; end if;
  insert into public.notifications (user_id, kind, data)
  values (p_user, p_kind, p_data);
end;
$$;

-- Internal: only trigger functions (owned by the database owner) call this.
revoke execute on function
  public.push_notification(uuid, public.notification_kind, jsonb)
from public, anon, authenticated;

-- ================================================================== maintenance
create type public.maintenance_category as enum
  ('plumbing', 'electrical', 'appliance', 'pest', 'structural', 'other');
create type public.maintenance_priority as enum ('low', 'normal', 'urgent');
create type public.maintenance_status as enum
  ('open', 'in_progress', 'resolved', 'cancelled');

create table public.maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  lease_id uuid not null references public.leases (id) on delete restrict,
  -- Copied from the lease by the guard trigger; never supplied by the client.
  property_id uuid not null references public.properties (id) on delete restrict,
  tenant_id uuid not null references public.profiles (id) on delete restrict,
  property_title text not null,
  title text not null check (char_length(btrim(title)) between 3 and 120),
  description text not null default '' check (char_length(description) <= 2000),
  category public.maintenance_category not null default 'other',
  priority public.maintenance_priority not null default 'normal',
  status public.maintenance_status not null default 'open',
  resolution_note text
    check (resolution_note is null or char_length(resolution_note) <= 500),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index maintenance_lease_status_idx
  on public.maintenance_requests (lease_id, status);
create index maintenance_tenant_idx
  on public.maintenance_requests (tenant_id, updated_at desc);
create index maintenance_property_idx
  on public.maintenance_requests (property_id, updated_at desc);

create table public.maintenance_comments (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null
    references public.maintenance_requests (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null
    check (char_length(btrim(body)) >= 1 and char_length(body) <= 2000),
  created_at timestamptz not null default now()
);
create index maintenance_comments_thread_idx
  on public.maintenance_comments (request_id, created_at);

-- The tenant, or the listing's CURRENT agent.
create or replace function public.is_maintenance_party(p_request uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.maintenance_requests m
    join public.properties p on p.id = m.property_id
    where m.id = p_request
      and (m.tenant_id = (select auth.uid())
           or p.agent_id = (select auth.uid()))
  );
$$;

create or replace function public.is_maintenance_open(p_request uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.maintenance_requests
    where id = p_request and status in ('open', 'in_progress')
  );
$$;

alter table public.maintenance_requests enable row level security;
alter table public.maintenance_comments enable row level security;

create policy "maintenance_select_party"
  on public.maintenance_requests for select to authenticated
  using (public.is_maintenance_party(id) or public.is_admin());

-- The guard trigger fills tenant_id from the lease, so this proves the caller
-- really is the tenant.
create policy "maintenance_insert_tenant"
  on public.maintenance_requests for insert to authenticated
  with check (tenant_id = (select auth.uid()));

create policy "maintenance_update_party"
  on public.maintenance_requests for update to authenticated
  using (public.is_maintenance_party(id))
  with check (public.is_maintenance_party(id));

-- Only the status and the resolution note can be changed through the API.
revoke update on public.maintenance_requests from authenticated;
grant update (status, resolution_note)
  on public.maintenance_requests to authenticated;

create policy "maint_comments_select_party"
  on public.maintenance_comments for select to authenticated
  using (public.is_maintenance_party(request_id) or public.is_admin());

-- No UPDATE/DELETE policies: comments are append-only.
create policy "maint_comments_insert_party"
  on public.maintenance_comments for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_maintenance_party(request_id)
    and public.is_maintenance_open(request_id)
  );

create or replace function public.guard_maintenance_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_lease public.leases%rowtype;
  v_is_tenant boolean;
  v_is_agent boolean;
begin
  if tg_op = 'INSERT' then
    select * into v_lease from public.leases where id = new.lease_id;
    if not found then
      raise exception 'Lease not found' using errcode = 'P0002';
    end if;
    if v_uid is null or v_lease.tenant_id <> v_uid or v_lease.status <> 'active' then
      raise exception 'Only the tenant of an active lease can report problems'
        using errcode = '42501';
    end if;
    if (select count(*) from public.maintenance_requests m
        where m.lease_id = new.lease_id
          and m.status in ('open', 'in_progress')) >= 5 then
      raise exception 'Too many open requests for this lease'
        using errcode = '23514';
    end if;

    new.tenant_id := v_lease.tenant_id;
    new.property_id := v_lease.property_id;
    new.property_title := v_lease.property_title;
    new.status := 'open';
    new.resolution_note := null;
    new.resolved_at := null;
    new.created_at := now();
    new.updated_at := now();
    return new;
  end if;

  new.updated_at := now();
  if v_uid is null then
    return new; -- SQL editor maintenance
  end if;

  v_is_tenant := old.tenant_id = v_uid;
  v_is_agent := exists (
    select 1 from public.properties p
    where p.id = old.property_id and p.agent_id = v_uid
  );

  if new.status = old.status then
    if new.resolution_note is distinct from old.resolution_note then
      raise exception 'A note can only be added when resolving'
        using errcode = '42501';
    end if;
    return new;
  end if;

  if old.status = 'open' and new.status in ('in_progress', 'resolved')
     and v_is_agent then
    null;
  elsif old.status = 'in_progress' and new.status = 'resolved' and v_is_agent then
    null;
  elsif old.status in ('open', 'in_progress') and new.status = 'cancelled'
        and v_is_tenant then
    null;
  else
    raise exception 'Invalid maintenance change' using errcode = '42501';
  end if;

  if new.status = 'resolved' then
    new.resolution_note := nullif(btrim(coalesce(new.resolution_note, '')), '');
    new.resolved_at := now();
  else
    new.resolution_note := null;
    new.resolved_at := null;
  end if;
  return new;
end;
$$;

create trigger maintenance_guard
  before insert or update on public.maintenance_requests
  for each row execute function public.guard_maintenance_write();

-- ============================================================ notification triggers
create or replace function public.notify_on_inquiry_message()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_client uuid; v_agent uuid; v_title text;
begin
  select i.client_id, p.agent_id, i.property_title
  into v_client, v_agent, v_title
  from public.inquiries i
  join public.properties p on p.id = i.property_id
  where i.id = new.inquiry_id;

  perform public.push_notification(
    case when new.sender_id = v_client then v_agent else v_client end,
    'inquiry_message',
    jsonb_build_object('inquiry_id', new.inquiry_id, 'property_title', v_title)
  );
  return new;
end;
$$;

create trigger inquiry_messages_notify
  after insert on public.inquiry_messages
  for each row execute function public.notify_on_inquiry_message();

create or replace function public.notify_on_viewing()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_agent uuid; v_data jsonb;
begin
  select agent_id into v_agent from public.properties where id = new.property_id;
  v_data := jsonb_build_object(
    'viewing_id', new.id,
    'property_title', new.property_title,
    'scheduled_at', new.scheduled_at
  );

  if tg_op = 'INSERT' then
    perform public.push_notification(v_agent, 'viewing_requested', v_data);
  elsif new.status is distinct from old.status then
    if new.status = 'confirmed' then
      perform public.push_notification(new.client_id, 'viewing_confirmed', v_data);
    elsif new.status = 'declined' then
      perform public.push_notification(new.client_id, 'viewing_declined', v_data);
    elsif new.status = 'cancelled' then
      perform public.push_notification(
        case when auth.uid() = new.client_id then v_agent else new.client_id end,
        'viewing_cancelled', v_data);
    end if;
  end if;
  return new;
end;
$$;

create trigger viewings_notify
  after insert or update of status on public.viewings
  for each row execute function public.notify_on_viewing();

create or replace function public.notify_on_lease()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_data jsonb;
begin
  v_data := jsonb_build_object(
    'lease_id', new.id, 'property_title', new.property_title);
  if tg_op = 'INSERT' then
    perform public.push_notification(new.tenant_id, 'lease_created', v_data);
  elsif old.status = 'active' and new.status = 'ended' then
    perform public.push_notification(new.tenant_id, 'lease_ended', v_data);
  end if;
  return new;
end;
$$;

create trigger leases_notify
  after insert or update of status on public.leases
  for each row execute function public.notify_on_lease();

create or replace function public.notify_on_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_tenant uuid; v_title text; v_lease uuid; v_currency text; v_data jsonb;
begin
  select l.tenant_id, l.property_title, l.id, l.currency
  into v_tenant, v_title, v_lease, v_currency
  from public.rent_charges c
  join public.leases l on l.id = c.lease_id
  where c.id = new.charge_id;

  v_data := jsonb_build_object(
    'lease_id', v_lease, 'property_title', v_title,
    'amount', new.amount::text, 'currency', v_currency);

  if tg_op = 'INSERT' then
    perform public.push_notification(v_tenant, 'payment_recorded', v_data);
  elsif old.voided_at is null and new.voided_at is not null then
    perform public.push_notification(v_tenant, 'payment_voided', v_data);
  end if;
  return new;
end;
$$;

create trigger rent_payments_notify
  after insert or update of voided_at on public.rent_payments
  for each row execute function public.notify_on_payment();

create or replace function public.notify_on_maintenance()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_agent uuid; v_data jsonb;
begin
  select agent_id into v_agent from public.properties where id = new.property_id;
  v_data := jsonb_build_object(
    'request_id', new.id, 'property_title', new.property_title,
    'title', new.title, 'status', new.status::text);

  if tg_op = 'INSERT' then
    perform public.push_notification(v_agent, 'maintenance_created', v_data);
  elsif new.status is distinct from old.status then
    perform public.push_notification(
      case when auth.uid() = new.tenant_id then v_agent else new.tenant_id end,
      'maintenance_status', v_data);
  end if;
  return new;
end;
$$;

create trigger maintenance_notify
  after insert or update of status on public.maintenance_requests
  for each row execute function public.notify_on_maintenance();

create or replace function public.on_maintenance_comment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare r public.maintenance_requests%rowtype; v_agent uuid;
begin
  select * into r from public.maintenance_requests where id = new.request_id;
  select agent_id into v_agent from public.properties where id = r.property_id;

  perform public.push_notification(
    case when new.sender_id = r.tenant_id then v_agent else r.tenant_id end,
    'maintenance_comment',
    jsonb_build_object(
      'request_id', r.id, 'property_title', r.property_title, 'title', r.title));

  -- Keeps the request near the top of its inbox.
  update public.maintenance_requests set updated_at = now() where id = r.id;
  return new;
end;
$$;

create trigger maintenance_comments_after_insert
  after insert on public.maintenance_comments
  for each row execute function public.on_maintenance_comment();