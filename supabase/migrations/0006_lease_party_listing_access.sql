-- 0006: a lease's tenant can always read the listing behind their lease, so
-- the agent's name stays visible after the listing is archived or sold.
create or replace function public.is_tenant_of_property(p_property uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.leases l
    where l.property_id = p_property and l.tenant_id = (select auth.uid())
  );
$$;

drop policy if exists "properties_select_visible" on public.properties;

create policy "properties_select_visible"
  on public.properties for select to authenticated
  using (
    status = 'published'
    or agent_id = (select auth.uid())
    or public.is_admin()
    or public.is_tenant_of_property(id)
  );