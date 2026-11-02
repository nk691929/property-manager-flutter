-- 0003_property_photos.sql

-- Bucket: public read (URLs are unguessable), limits enforced by Storage.
insert into storage.buckets
  (id, name, public, file_size_limit, allowed_mime_types)
values (
  'property-photos', 'property-photos', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Who may change a property's photos: admins, or the owning agent while the
-- listing is still editable (same lock as listing content).
create or replace function public.can_manage_property_photos(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.properties p
    where p.id = p_id
      and (
        public.is_admin()
        or (
          public.is_agent()
          and p.agent_id = (select auth.uid())
          and p.status in ('draft', 'rejected')
        )
      )
  );
$$;

-- Property id from a storage path like '<uuid>/<file>'. The CASE guarantees the
-- uuid cast only runs on a well-formed folder name.
create or replace function public.photo_folder_property_id(object_name text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when object_name ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/'
    then split_part(object_name, '/', 1)::uuid
  end;
$$;

create table public.property_photos (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  storage_path text not null unique,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  -- The file must live in this property's folder (storage policies rely on it).
  check (storage_path like property_id::text || '/%')
);

create index property_photos_property_idx
  on public.property_photos (property_id, position);

alter table public.property_photos enable row level security;

-- Visible exactly when the property is. The subquery runs as the caller, so the
-- properties RLS policy decides.
create policy "photos_select_visible"
  on public.property_photos for select to authenticated
  using (exists (
    select 1 from public.properties p where p.id = property_id
  ));

create policy "photos_insert_manage"
  on public.property_photos for insert to authenticated
  with check (public.can_manage_property_photos(property_id));

create policy "photos_update_manage"
  on public.property_photos for update to authenticated
  using (public.can_manage_property_photos(property_id))
  with check (public.can_manage_property_photos(property_id));

create policy "photos_delete_manage"
  on public.property_photos for delete to authenticated
  using (public.can_manage_property_photos(property_id));

-- At most 10 photos per listing. SECURITY DEFINER so the count ignores RLS.
create or replace function public.guard_photo_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.property_photos
      where property_id = new.property_id) >= 10 then
    raise exception 'A listing can have at most 10 photos'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger property_photos_guard
  before insert on public.property_photos
  for each row execute function public.guard_photo_insert();

-- Storage: only people who may manage the property can upload or delete its
-- files. Reads go through the public bucket URL, so there is no broad SELECT
-- policy (nobody can list the bucket). The narrow SELECT below lets the Storage
-- API find the object when deleting it.
create policy "photos_storage_select"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'property-photos'
    and public.can_manage_property_photos(
      public.photo_folder_property_id(name))
  );

create policy "photos_storage_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'property-photos'
    and public.can_manage_property_photos(
      public.photo_folder_property_id(name))
  );

create policy "photos_storage_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'property-photos'
    and public.can_manage_property_photos(
      public.photo_folder_property_id(name))
  );