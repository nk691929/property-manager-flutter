-- DEV ONLY. Sample listings for browsing and search.
with owner as (
  select coalesce(
    (select id from public.profiles where role = 'agent' limit 1),
    (select id from public.profiles where role = 'admin' limit 1)
  ) as id
)
insert into public.properties
  (agent_id, title, description, listing_type, property_type, price,
   bedrooms, bathrooms, area_value, area_unit, city, address)
select owner.id, v.*
from owner, (values
  ('Modern 5 Marla House near Canal Road',
   'Corner house with parking, near schools and markets.',
   'sale'::public.listing_type, 'house'::public.property_type,
   18500000, 3, 3, 5, 'marla'::public.area_unit, 'Faisalabad', 'Canal Road'),
  ('Two-Bedroom Apartment in Gulberg',
   'Third floor, lift, secure parking. Rent is per month.',
   'rent', 'apartment', 65000, 2, 2, 1100, 'sqft', 'Lahore', 'Gulberg III'),
  ('Ground-Floor Shop on Main Boulevard',
   'High footfall commercial shop. Rent is per month.',
   'rent', 'commercial', 120000, null, 1, 450, 'sqft', 'Faisalabad', 'D Ground'),
  ('1 Kanal Residential Plot, Sector E',
   'Level plot, possession ready, near the main road.',
   'sale', 'plot', 42000000, null, null, 1, 'kanal', 'Islamabad', 'Sector E-11'),
  ('10 Marla Family House with Garden',
   'Five bedrooms, double kitchen, servant quarter.',
   'sale', 'house', 65000000, 5, 4, 10, 'marla', 'Lahore', 'DHA Phase 5'),
  ('Furnished Room for Working Professional',
   'Attached bath, WiFi included. Rent is per month.',
   'rent', 'room', 25000, 1, 1, null, null, 'Faisalabad', 'Peoples Colony No. 1')
) as v(title, description, listing_type, property_type, price,
       bedrooms, bathrooms, area_value, area_unit, city, address);

update public.properties
set status = 'published'
where created_at > now() - interval '1 minute';