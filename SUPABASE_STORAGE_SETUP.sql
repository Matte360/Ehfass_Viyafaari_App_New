-- VIYAFAARI TOWN SUPABASE STORAGE SETUP
-- Run this in Supabase Dashboard > SQL Editor.
-- It keeps product/business images public, while payment receipts use a
-- separate private bucket and temporary signed URLs.

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
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'payment-proofs',
  'payment-proofs',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Viyafaari public media uploads" on storage.objects;
create policy "Viyafaari public media uploads"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in ('businesses', 'catalog', 'profiles', 'quotation_attachments')
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

drop policy if exists "Viyafaari public media updates" on storage.objects;
create policy "Viyafaari public media updates"
on storage.objects
for update
to anon, authenticated
using (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in ('businesses', 'catalog', 'profiles', 'quotation_attachments')
)
with check (
  bucket_id = 'business-media'
  and (storage.foldername(name))[1] in ('businesses', 'catalog', 'profiles', 'quotation_attachments')
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

drop policy if exists "Viyafaari receipt uploads" on storage.objects;
create policy "Viyafaari receipt uploads"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'payment-proofs'
  and (storage.foldername(name))[1] = 'receipts'
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

-- Needed by the app to generate a temporary signed URL when the linked
-- business owner opens a receipt. Firestore rules protect the receipt path.
drop policy if exists "Viyafaari receipt signed reads" on storage.objects;
create policy "Viyafaari receipt signed reads"
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'payment-proofs'
  and (storage.foldername(name))[1] = 'receipts'
);
