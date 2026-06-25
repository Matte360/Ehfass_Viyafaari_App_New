-- VIYAFAARI TOWN - ADMIN HOME ADVERTISEMENT STORAGE SETUP
-- Run this in Supabase SQL Editor.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'business-media',
  'business-media',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "Allow admin home advertisement uploads" on storage.objects;
drop policy if exists "Allow admin home advertisement updates" on storage.objects;
drop policy if exists "Allow admin home advertisement deletes" on storage.objects;

create policy "Allow admin home advertisement uploads"
on storage.objects
for insert
to anon
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] = 'admin_ads'
);

create policy "Allow admin home advertisement updates"
on storage.objects
for update
to anon
using (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] = 'admin_ads'
)
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] = 'admin_ads'
);

create policy "Allow admin home advertisement deletes"
on storage.objects
for delete
to anon
using (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] = 'admin_ads'
);
