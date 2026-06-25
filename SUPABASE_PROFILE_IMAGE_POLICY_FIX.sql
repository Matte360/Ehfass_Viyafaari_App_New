-- VIYAFAARI TOWN - PROFILE IMAGE SUPABASE STORAGE FIX
-- Run this in Supabase Dashboard > SQL Editor.
-- This fixes: StorageException: new row violates row-level security policy, 403 Unauthorized

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

-- Replace old public media policies so profile image uploads are allowed.
drop policy if exists "Viyafaari public media uploads" on storage.objects;
drop policy if exists "Viyafaari public media updates" on storage.objects;
drop policy if exists "Viyafaari public media reads" on storage.objects;

create policy "Viyafaari public media uploads"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in (
    'businesses',
    'catalog',
    'profiles',
    'admin_ads',
    'quotation_attachments'
  )
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

create policy "Viyafaari public media updates"
on storage.objects
for update
to anon, authenticated
using (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in (
    'businesses',
    'catalog',
    'profiles',
    'admin_ads',
    'quotation_attachments'
  )
)
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in (
    'businesses',
    'catalog',
    'profiles',
    'admin_ads',
    'quotation_attachments'
  )
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

create policy "Viyafaari public media reads"
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in (
    'businesses',
    'catalog',
    'profiles',
    'admin_ads',
    'quotation_attachments'
  )
);
