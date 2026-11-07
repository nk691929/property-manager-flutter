-- 0005_leases_and_rent.sql: leases, rent schedule, recorded payments

create type public.lease_status as enum ('active', 'ended');
create type public.payment_method as enum
  ('cash', 'bank_transfer', 'cheque', 'other');

create table public.leases (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete restrict,
  tenant_id uuid not null references public.profiles (id) on delete restrict,
  property_title text not null,
  start_date date not null,
  end_date date not null,
  monthly_rent numeric(14, 2) not null check (monthly_rent > 0),
  currency text not null default 'PKR' check (char_length(currency) = 3),
  security_deposit numeric(14, 2) not null default 0
    check (security_deposit >= 0),
  due_day smallint not null check (due_day between 1 and 28),
  status public.lease_status not null default 'active',
  ended_on date,
  created_at timestamptz not null default now(),
  check (end_date > start_date),
  check (end_date <= (start_date + interval '36 months')::date)
);

create unique index leases_one_active_per_property
  on public.leases (property_id) where status = 'active';
create index leases_tenant_idx on public.leases (tenant_id, created_at desc);
create index leases_property_idx on public.leases (property_id);

create table public.rent_charges (
  id uuid primary key default gen_random_uuid(),
  lease_id uuid not null references public.leases (id) on delete cascade,
  due_date date not null,
  amount numeric(14, 2) not null check (amount > 0),
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  unique (lease_id, due_date)
);
create index rent_charges_lease_idx on public.rent_charges (lease_id, due_date);

create table public.rent_payments (
  id uuid primary key default gen_random_uuid(),
  -- restrict: payment history must never vanish
  charge_id uuid not null references public.rent_charges (id) on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  paid_on date not null,
  method public.payment_method not null,
  reference text check (reference is null or char_length(reference) <= 100),
  recorded_by uuid not null references public.profiles (id) on delete restrict,
  voided_at timestamptz,
  void_reason text
    check (void_reason is null or char_length(void_reason) <= 300),
  created_at timestamptz not null default now(),
  check ((voided_at is null) = (void_reason is null))
);
create index rent_payments_charge_idx on public.rent_payments (charge_id);

-- ------------------------------------------------------------------ helpers
create or replace function public.lease_of_charge(p_charge uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select lease_id from public.rent_charges where id = p_charge;
$$;

-- The tenant, or the listing's CURRENT agent.
create or replace function public.is_lease_party(p_lease uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.leases l
    join public.properties p on p.id = l.property_id
    where l.id = p_lease
      and (l.tenant_id = (select auth.uid())
           or p.agent_id = (select auth.uid()))
  );
$$;

create or replace function public.is_lease_agent(p_lease uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.leases l
    join public.properties p on p.id = l.property_id
    where l.id = p_lease and p.agent_id = (select auth.uid())
  );
$$;

-- ---------------------------------------------------------------------- RLS
alter table public.leases enable row level security;
alter table public.rent_charges enable row level security;
alter table public.rent_payments enable row level security;

-- Leases and charges have NO write policies: they change only through
-- create_lease() and end_lease() below.
create policy "leases_select_party"
  on public.leases for select to authenticated
  using (public.is_lease_party(id) or public.is_admin());

create policy "charges_select_party"
  on public.rent_charges for select to authenticated
  using (public.is_lease_party(lease_id) or public.is_admin());

create policy "payments_select_party"
  on public.rent_payments for select to authenticated
  using (
    public.is_lease_party(public.lease_of_charge(charge_id))
    or public.is_admin()
  );

create policy "payments_insert_agent"
  on public.rent_payments for insert to authenticated
  with check (
    recorded_by = (select auth.uid())
    and public.is_lease_agent(public.lease_of_charge(charge_id))
  );

-- The only edit allowed is voiding.
create policy "payments_void_agent"
  on public.rent_payments for update to authenticated
  using (public.is_lease_agent(public.lease_of_charge(charge_id)))
  with check (public.is_lease_agent(public.lease_of_charge(charge_id)));

revoke update on public.rent_payments from authenticated;
grant update (voided_at, void_reason) on public.rent_payments to authenticated;

-- ----------------------------------------------------------------- triggers
create or replace function public.guard_payment_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_amount numeric;
  v_cancelled timestamptz;
  v_paid numeric;
begin
  -- Lock the charge so two simultaneous payments can't both pass the check.
  select c.amount, c.cancelled_at into v_amount, v_cancelled
  from public.rent_charges c where c.id = new.charge_id for update;
  if not found then
    raise exception 'Charge not found' using errcode = 'P0002';
  end if;
  if v_cancelled is not null then
    raise exception 'This charge was cancelled' using errcode = '55000';
  end if;
  -- One day of tolerance: the server runs in UTC, users may be ahead of it.
  if new.paid_on > current_date + 1 then
    raise exception 'Payment date cannot be in the future'
      using errcode = '23514';
  end if;

  select coalesce(sum(p.amount), 0) into v_paid
  from public.rent_payments p
  where p.charge_id = new.charge_id and p.voided_at is null;
  if v_paid + new.amount > v_amount then
    raise exception 'Payment exceeds the amount due' using errcode = '23514';
  end if;

  new.voided_at := null;
  new.void_reason := null;
  new.created_at := now();
  if v_uid is not null then new.recorded_by := v_uid; end if;
  return new;
end;
$$;

create trigger rent_payments_guard_insert
  before insert on public.rent_payments
  for each row execute function public.guard_payment_insert();

create or replace function public.guard_payment_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.voided_at is not null then
    raise exception 'This payment is already voided' using errcode = '55000';
  end if;
  if new.void_reason is null or btrim(new.void_reason) = '' then
    raise exception 'A reason is required' using errcode = '23514';
  end if;
  new.void_reason := btrim(new.void_reason);
  new.voided_at := now();
  return new;
end;
$$;

create trigger rent_payments_guard_update
  before update on public.rent_payments
  for each row execute function public.guard_payment_update();

-- ---------------------------------------------------------------- functions
create or replace function public.create_lease(
  p_property_id uuid,
  p_tenant_id uuid,
  p_start date,
  p_end date,
  p_monthly_rent numeric,
  p_due_day integer,
  p_deposit numeric default 0
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_prop public.properties%rowtype;
  v_lease uuid;
  v_due date;
begin
  if v_uid is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;

  select * into v_prop from public.properties
  where id = p_property_id for update;
  if not found then
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;
  if not (public.is_admin()
          or (public.is_agent() and v_prop.agent_id = v_uid)) then
    raise exception 'Only the listing agent can create leases'
      using errcode = '42501';
  end if;
  if v_prop.listing_type <> 'rent' then
    raise exception 'Only rental listings can be leased'
      using errcode = '23514';
  end if;
  if v_prop.status not in ('published', 'archived') then
    raise exception 'Publish the listing before creating a lease'
      using errcode = '23514';
  end if;
  if not exists (
    select 1 from public.profiles where id = p_tenant_id and role = 'client'
  ) then
    raise exception 'The tenant must be a client' using errcode = '23514';
  end if;
  -- A lease starts from a conversation the tenant began.
  if not public.is_admin()
     and not exists (
       select 1 from public.inquiries i
       where i.property_id = p_property_id and i.client_id = p_tenant_id)
     and not exists (
       select 1 from public.viewings w
       where w.property_id = p_property_id and w.client_id = p_tenant_id
         and w.status = 'completed') then
    raise exception 'The tenant has not contacted you about this listing'
      using errcode = '42501';
  end if;

  -- A second active lease violates leases_one_active_per_property (23505).
  insert into public.leases
    (property_id, tenant_id, property_title, start_date, end_date,
     monthly_rent, currency, security_deposit, due_day)
  values
    (p_property_id, p_tenant_id, v_prop.title, p_start, p_end,
     p_monthly_rent, v_prop.currency, coalesce(p_deposit, 0), p_due_day)
  returning id into v_lease;

  -- First due date on or after the start, then one per month while inside.
  -- due_day <= 28, so adding months never overflows.
  v_due := make_date(
    extract(year from p_start)::int, extract(month from p_start)::int,
    p_due_day);
  if v_due < p_start then v_due := (v_due + interval '1 month')::date; end if;
  while v_due <= p_end loop
    insert into public.rent_charges (lease_id, due_date, amount)
    values (v_lease, v_due, p_monthly_rent);
    v_due := (v_due + interval '1 month')::date;
  end loop;

  return v_lease;
end;
$$;

create or replace function public.end_lease(
  p_lease uuid,
  p_on date default current_date
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_status public.lease_status;
  v_agent uuid;
begin
  if v_uid is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;

  select l.status, p.agent_id into v_status, v_agent
  from public.leases l join public.properties p on p.id = l.property_id
  where l.id = p_lease for update of l;
  if not found then
    raise exception 'Lease not found' using errcode = 'P0002';
  end if;
  if not (public.is_admin() or v_agent = v_uid) then
    raise exception 'Only the listing agent can end a lease'
      using errcode = '42501';
  end if;
  if v_status <> 'active' then
    raise exception 'The lease has already ended' using errcode = '55000';
  end if;

  update public.leases set status = 'ended', ended_on = p_on
  where id = p_lease;

  -- Future charges nobody has paid anything towards are cancelled. Charges
  -- with a payment stay, so the history remains truthful.
  update public.rent_charges c
  set cancelled_at = now()
  where c.lease_id = p_lease
    and c.due_date > p_on
    and c.cancelled_at is null
    and not exists (
      select 1 from public.rent_payments p
      where p.charge_id = c.id and p.voided_at is null);
end;
$$;

revoke execute on function
  public.create_lease(uuid, uuid, date, date, numeric, integer, numeric),
  public.end_lease(uuid, date)
from public, anon;
grant execute on function
  public.create_lease(uuid, uuid, date, date, numeric, integer, numeric),
  public.end_lease(uuid, date)
to authenticated;

-- ------------------------------------------------------------- name lookup
-- Same window as migration 0004, extended: tenant and agent may see each
-- other's names. Still id and name only, never the email.
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
      or exists (
            select 1 from public.leases l
            join public.properties x on x.id = l.property_id
            where (l.tenant_id = p.id and x.agent_id = (select auth.uid()))
               or (x.agent_id = p.id and l.tenant_id = (select auth.uid())))
    );
$$;

revoke execute on function public.visible_names(uuid[]) from public, anon;
grant execute on function public.visible_names(uuid[]) to authenticated;