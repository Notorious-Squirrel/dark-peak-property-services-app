-- Extend the single-business One List profile.
alter table public.business_details
 add column if not exists bio text not null default '',
 add column if not exists company_registration_number text not null default '',
 add column if not exists public_liability_value text not null default '',
 add column if not exists trade_qualifications text not null default '',
 add column if not exists public_liability_certificate_path text;

-- Public certificate storage: only administrators can upload/change files.
-- Documents in this bucket are publicly accessible by URL; do not upload
-- certificates containing private home addresses or other sensitive details.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('business-certificates', 'business-certificates', true, 10485760,
 array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Admins upload business certificates" on storage.objects;
create policy "Admins upload business certificates" on storage.objects
for insert to authenticated
with check (bucket_id = 'business-certificates' and exists (
 select 1 from public.admin_users where user_id = (select auth.uid())
));

drop policy if exists "Admins update business certificates" on storage.objects;
create policy "Admins update business certificates" on storage.objects
for update to authenticated
using (bucket_id = 'business-certificates' and exists (
 select 1 from public.admin_users where user_id = (select auth.uid())
))
with check (bucket_id = 'business-certificates' and exists (
 select 1 from public.admin_users where user_id = (select auth.uid())
));

drop policy if exists "Admins delete business certificates" on storage.objects;
create policy "Admins delete business certificates" on storage.objects
for delete to authenticated
using (bucket_id = 'business-certificates' and exists (
 select 1 from public.admin_users where user_id = (select auth.uid())
));
