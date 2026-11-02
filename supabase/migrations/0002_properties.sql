-- 0002_properties.sql
create type public.listing_type as enum ('rent', 'sale');
create type public.property_type as enum
  ('house', 'apartment', 'room', 'commercial', 'plot');
create type public.area_unit as enum ('sqft', 'sqm', 'marla', 'kanal');
create type public.property_status as enum
  ('draft', 'pending_review', 'published', 'rejected', 'archived');

-- Platform rules: a single row. A boolean primary key that must be true
-- makes a second row impossible.
create table public.app_settings (
  id boolean primary key default true check (id),
  require_listing_approval boolean not null default true,
  updated_at timestamptz not null default now()
);
insert into public.app_settings default values;

alter table public.app_settings enable row level security;

create policy "settings_select_authenticated"
  on public.app_settings for select to authenticated using (true);

create policy "settings_update_admin"
  on public.app_settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create or replace function public.touch_app_settings()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger app_settings_touch
  before update on public.app_settings
  for each row execute function public.touch_app_settings();

create or replace function public.is_agent()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'agent'
  );
$$;

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  -- restrict: an agent with listings can't be deleted until reassigned
  agent_id uuid not null references public.profiles (id) on delete restrict,
  title text not null check (char_length(title) between 5 and 120),
  description text not null default '' check (char_length(description) <= 5000),
  listing_type public.listing_type not null,
  property_type public.property_type not null,
  price numeric(14, 2) not null check (price > 0),
  currency text not null default 'PKR' check (char_length(currency) = 3),
  bedrooms smallint check (bedrooms between 0 and 50),
  bathrooms smallint check (bathrooms between 0 and 50),
  area_value numeric(12, 2) check (area_value > 0),
  area_unit public.area_unit,
  city text not null check (char_length(city) between 2 and 80),
  address text not null default '' check (char_length(address) <= 200),
  status public.property_status not null default 'draft',
  rejection_reason text,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((area_value is null) = (area_unit is null))
);

create index properties_status_published_idx
  on public.properties (status, published_at desc);
create index properties_agent_idx on public.properties (agent_id);
create index properties_city_idx on public.properties (lower(city));
create index properties_price_idx on public.properties (price);

alter table public.properties enable row level security;

create policy "properties_select_visible"
  on public.properties for select to authenticated
  using (
    status = 'published'
    or agent_id = (select auth.uid())
    or public.is_admin()
  );

create policy "properties_insert_agent_or_admin"
  on public.properties for insert to authenticated
  with check (
    public.is_admin()
    or (public.is_agent() and agent_id = (select auth.uid()))
  );

create policy "properties_update_owner_or_admin"
  on public.properties for update to authenticated
  using (
    public.is_admin()
    or (public.is_agent() and agent_id = (select auth.uid()))
  )
  with check (
    public.is_admin()
    or (public.is_agent() and agent_id = (select auth.uid()))
  );

-- Hard delete is for drafts only; everything else is archived.
create policy "properties_delete_drafts"
  on public.properties for delete to authenticated
  using (
    status = 'draft'
    and (
      public.is_admin()
      or (public.is_agent() and agent_id = (select auth.uid()))
    )
  );

-- What an owner agent may do. Admins may do anything.
create or replace function public.agent_can_transition(
  old_status public.property_status,
  new_status public.property_status,
  approval_required boolean
) returns boolean
language sql immutable as $$
  select case
    when old_status = new_status then true
    when old_status in ('draft', 'rejected') and new_status = 'pending_review'
      then approval_required
    when old_status in ('draft', 'rejected') and new_status = 'published'
      then not approval_required
    when old_status = 'pending_review' and new_status = 'draft' then true
    when old_status = 'published' and new_status in ('draft', 'archived')
      then true
    when old_status in ('draft', 'rejected') and new_status = 'archived'
      then true
    when old_status = 'archived' and new_status = 'draft' then true
    else false
  end;
$$;

-- auth.uid() is null in the SQL editor, so seeding and fixes still work there.
create or replace function public.guard_property_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin boolean := auth.uid() is null or public.is_admin();
  v_approval boolean;
begin
  select require_listing_approval into v_approval from public.app_settings;
  new.updated_at := now();

  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.rejection_reason := null;
    new.published_at := null;
    return new;
  end if;

  if new.agent_id is distinct from old.agent_id and not v_admin then
    raise exception 'Only admins can reassign listings' using errcode = '42501';
  end if;

  if not v_admin then
    if not public.agent_can_transition(old.status, new.status, v_approval) then
      raise exception 'Invalid status change: % -> %', old.status, new.status
        using errcode = '42501';
    end if;

    if (new.title, new.description, new.listing_type, new.property_type,
        new.price, new.currency, new.bedrooms, new.bathrooms,
        new.area_value, new.area_unit, new.city, new.address)
       is distinct from
       (old.title, old.description, old.listing_type, old.property_type,
        old.price, old.currency, old.bedrooms, old.bathrooms,
        old.area_value, old.area_unit, old.city, old.address)
       and old.status not in ('draft', 'rejected') then
      raise exception 'Unpublish the listing before editing it'
        using errcode = '42501';
    end if;

    -- Review fields are server-controlled for agents.
    new.rejection_reason := old.rejection_reason;
    new.published_at := old.published_at;
  end if;

  if new.status is distinct from old.status then
    if new.status = 'rejected'
       and (new.rejection_reason is null or btrim(new.rejection_reason) = '') then
      raise exception 'A rejection reason is required' using errcode = '23514';
    end if;
    if new.status = 'published' then
      new.published_at := now();
    end if;
    if new.status <> 'rejected' then
      new.rejection_reason := null;
    end if;
  end if;

  return new;
end;
$$;

create trigger properties_guard
  before insert or update on public.properties
  for each row execute function public.guard_property_write();