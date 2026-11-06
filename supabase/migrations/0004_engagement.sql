-- 0004_engagement.sql: favorites, inquiries (threads), viewings, name lookup

create or replace function public.is_client()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'client'
  );
$$;

create or replace function public.is_property_agent(p_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.properties
    where id = p_id and agent_id = (select auth.uid())
  );
$$;

-- ---------------------------------------------------------------- favorites
create table public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, property_id)
);
create index favorites_user_idx on public.favorites (user_id, created_at desc);

alter table public.favorites enable row level security;

create policy "favorites_select_own"
  on public.favorites for select to authenticated
  using (user_id = (select auth.uid()));

create policy "favorites_insert_own"
  on public.favorites for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and public.is_client()
    and exists (
      select 1 from public.properties p
      where p.id = property_id and p.status = 'published'
    )
  );

create policy "favorites_delete_own"
  on public.favorites for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------- inquiries
create type public.inquiry_status as enum ('open', 'closed');

create table public.inquiries (
  id uuid primary key default gen_random_uuid(),
  -- restrict: history must not vanish when a listing is deleted
  property_id uuid not null references public.properties (id) on delete restrict,
  client_id uuid not null references public.profiles (id) on delete cascade,
  property_title text not null,
  status public.inquiry_status not null default 'open',
  last_message_at timestamptz not null default now(),
  last_message_preview text not null default '',
  last_sender_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create unique index inquiries_one_open_per_client_property
  on public.inquiries (property_id, client_id) where status = 'open';
create index inquiries_client_idx
  on public.inquiries (client_id, last_message_at desc);
create index inquiries_property_idx
  on public.inquiries (property_id, last_message_at desc);

create table public.inquiry_messages (
  id uuid primary key default gen_random_uuid(),
  inquiry_id uuid not null references public.inquiries (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null
    check (char_length(btrim(body)) >= 1 and char_length(body) <= 2000),
  created_at timestamptz not null default now()
);
create index inquiry_messages_thread_idx
  on public.inquiry_messages (inquiry_id, created_at);

-- Participants: the client, and whoever is the property's CURRENT agent.
create or replace function public.is_inquiry_participant(p_inquiry uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.inquiries i
    join public.properties p on p.id = i.property_id
    where i.id = p_inquiry
      and (i.client_id = (select auth.uid())
           or p.agent_id = (select auth.uid()))
  );
$$;

alter table public.inquiries enable row level security;
alter table public.inquiry_messages enable row level security;

-- No INSERT policy on inquiries: they are created only by create_inquiry().
create policy "inquiries_select_participant"
  on public.inquiries for select to authenticated
  using (public.is_inquiry_participant(id) or public.is_admin());

create policy "inquiries_update_participant"
  on public.inquiries for update to authenticated
  using (public.is_inquiry_participant(id))
  with check (public.is_inquiry_participant(id));

-- Only `status` may be changed by API callers (closing). Everything else is
-- frozen by column privileges; the message trigger below runs as the owner.
revoke update on public.inquiries from authenticated;
grant update (status) on public.inquiries to authenticated;

create policy "messages_select_participant"
  on public.inquiry_messages for select to authenticated
  using (public.is_inquiry_participant(inquiry_id) or public.is_admin());

-- No UPDATE/DELETE policies: messages are append-only.
create policy "messages_insert_participant"
  on public.inquiry_messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_inquiry_participant(inquiry_id)
    and exists (
      select 1 from public.inquiries i
      where i.id = inquiry_id and i.status = 'open'
    )
  );

create or replace function public.guard_inquiry_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is not null
     and new.status is distinct from old.status
     and not (old.status = 'open' and new.status = 'closed') then
    raise exception 'Inquiries can only be closed' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger inquiries_guard
  before update on public.inquiries
  for each row execute function public.guard_inquiry_update();

create or replace function public.on_inquiry_message_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.inquiries
  set last_message_at = new.created_at,
      last_message_preview = left(btrim(new.body), 120),
      last_sender_id = new.sender_id
  where id = new.inquiry_id;
  return new;
end;
$$;

create trigger inquiry_messages_after_insert
  after insert on public.inquiry_messages
  for each row execute function public.on_inquiry_message_insert();

-- Creating an inquiry = two rows that must exist together, so one transaction.
create or replace function public.create_inquiry(p_property_id uuid, p_body text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_body text := btrim(coalesce(p_body, ''));
  v_title text;
  v_inquiry uuid;
begin
  if v_uid is null or not public.is_client() then
    raise exception 'Only clients can send inquiries' using errcode = '42501';
  end if;
  if char_length(v_body) not between 1 and 2000 then
    raise exception 'Message must be 1 to 2000 characters' using errcode = '23514';
  end if;

  select title into v_title from public.properties
  where id = p_property_id and status = 'published';
  if not found then
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;

  -- A second open inquiry for the same listing violates the partial unique index.
  insert into public.inquiries (property_id, client_id, property_title)
  values (p_property_id, v_uid, v_title)
  returning id into v_inquiry;

  insert into public.inquiry_messages (inquiry_id, sender_id, body)
  values (v_inquiry, v_uid, v_body);

  return v_inquiry;
end;
$$;

revoke execute on function public.create_inquiry(uuid, text) from public, anon;
grant execute on function public.create_inquiry(uuid, text) to authenticated;

-- ----------------------------------------------------------------- viewings
create type public.viewing_status as enum
  ('requested', 'confirmed', 'declined', 'cancelled', 'completed');

create table public.viewings (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete restrict,
  client_id uuid not null references public.profiles (id) on delete cascade,
  property_title text not null default '',
  scheduled_at timestamptz not null,
  status public.viewing_status not null default 'requested',
  decline_reason text
    check (decline_reason is null or char_length(decline_reason) <= 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index viewings_one_active_per_client_property
  on public.viewings (property_id, client_id)
  where status in ('requested', 'confirmed');
create index viewings_client_idx on public.viewings (client_id, scheduled_at);
create index viewings_property_idx on public.viewings (property_id, scheduled_at);

alter table public.viewings enable row level security;

create policy "viewings_select_participant"
  on public.viewings for select to authenticated
  using (
    client_id = (select auth.uid())
    or public.is_property_agent(property_id)
    or public.is_admin()
  );

create policy "viewings_insert_client"
  on public.viewings for insert to authenticated
  with check (client_id = (select auth.uid()) and public.is_client());

create policy "viewings_update_participant"
  on public.viewings for update to authenticated
  using (client_id = (select auth.uid()) or public.is_property_agent(property_id))
  with check (
    client_id = (select auth.uid()) or public.is_property_agent(property_id)
  );

revoke update on public.viewings from authenticated;
grant update (status, decline_reason) on public.viewings to authenticated;

create or replace function public.guard_viewing_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_title text;
  v_is_client boolean;
  v_is_agent boolean;
begin
  if tg_op = 'INSERT' then
    select title into v_title from public.properties
    where id = new.property_id and status = 'published';
    if not found then
      raise exception 'Listing not found' using errcode = 'P0002';
    end if;
    if new.scheduled_at < now() + interval '1 hour'
       or new.scheduled_at > now() + interval '90 days' then
      raise exception 'Choose a time between 1 hour and 90 days from now'
        using errcode = '23514';
    end if;
    new.property_title := v_title;
    new.status := 'requested';
    new.decline_reason := null;
    new.created_at := now();
    new.updated_at := now();
    return new;
  end if;

  new.updated_at := now();
  if v_uid is null then
    return new; -- SQL editor maintenance
  end if;

  v_is_client := old.client_id = v_uid;
  v_is_agent := exists (
    select 1 from public.properties p
    where p.id = old.property_id and p.agent_id = v_uid
  );

  if new.status = old.status then
    if new.decline_reason is distinct from old.decline_reason then
      raise exception 'A reason can only be set when declining'
        using errcode = '42501';
    end if;
    return new;
  end if;

  if old.status = 'requested' and new.status = 'confirmed' and v_is_agent then
    if old.scheduled_at <= now() then
      raise exception 'The requested time has already passed'
        using errcode = '42501';
    end if;
  elsif old.status = 'requested' and new.status = 'declined' and v_is_agent then
    if new.decline_reason is null or btrim(new.decline_reason) = '' then
      raise exception 'A reason is required' using errcode = '23514';
    end if;
  elsif old.status = 'requested' and new.status = 'cancelled' and v_is_client then
    null;
  elsif old.status = 'confirmed' and new.status = 'cancelled'
        and (v_is_client or v_is_agent) then
    null;
  elsif old.status = 'confirmed' and new.status = 'completed' and v_is_agent then
    if old.scheduled_at > now() then
      raise exception 'The viewing has not happened yet' using errcode = '42501';
    end if;
  else
    raise exception 'Invalid viewing change' using errcode = '42501';
  end if;

  if new.status <> 'declined' then
    new.decline_reason := null;
  end if;
  return new;
end;
$$;

create trigger viewings_guard
  before insert or update on public.viewings
  for each row execute function public.guard_viewing_write();

-- --------------------------------------------------------------- name lookup
-- A deliberate, narrow window into `profiles`: id and name only, and only for
-- people the caller has a legitimate relationship with. Never the email.
create or replace function public.visible_names(p_ids uuid[])
returns table (id uuid, full_name text)
language sql stable security definer set search_path = '' as $$
  select p.id, p.full_name
  from public.profiles p
  where p.id = any (p_ids[1:200])
    and (
      p.id = (select auth.uid())
      or public.is_admin()
      or (p.role = 'agent' and exists (
            select 1 from public.properties x
            where x.agent_id = p.id and x.status = 'published'))
      or exists (
            select 1 from public.inquiries i
            join public.properties x on x.id = i.property_id
            where (i.client_id = p.id and x.agent_id = (select auth.uid()))
               or (x.agent_id = p.id and i.client_id = (select auth.uid())))
      or exists (
            select 1 from public.viewings v
            join public.properties x on x.id = v.property_id
            where (v.client_id = p.id and x.agent_id = (select auth.uid()))
               or (x.agent_id = p.id and v.client_id = (select auth.uid())))
    );
$$;

revoke execute on function public.visible_names(uuid[]) from public, anon;
grant execute on function public.visible_names(uuid[]) to authenticated;