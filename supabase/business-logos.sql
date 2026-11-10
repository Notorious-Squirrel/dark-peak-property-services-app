-- Run once in Supabase SQL Editor to enable contractor logos.
alter table public.businesses add column if not exists logo_path text;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('business-logos','business-logos',true,2097152,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=true,file_size_limit=2097152,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Public read business logos" on storage.objects;
create policy "Public read business logos" on storage.objects for select to anon,authenticated
using(bucket_id='business-logos');
drop policy if exists "Business members upload own logos" on storage.objects;
create policy "Business members upload own logos" on storage.objects for insert to authenticated
with check(bucket_id='business-logos' and exists(select 1 from public.business_members m where m.user_id=(select auth.uid()) and m.business_id::text=split_part(name,'/',1)));
drop policy if exists "Business members replace own logos" on storage.objects;
create policy "Business members replace own logos" on storage.objects for update to authenticated
using(bucket_id='business-logos' and exists(select 1 from public.business_members m where m.user_id=(select auth.uid()) and m.business_id::text=split_part(name,'/',1)))
with check(bucket_id='business-logos' and exists(select 1 from public.business_members m where m.user_id=(select auth.uid()) and m.business_id::text=split_part(name,'/',1)));
