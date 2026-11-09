-- ONE LIST multi-business foundation, run once in Supabase SQL Editor.
-- Preserves the existing Dark Peak profile, services and admin account.
begin;
create table if not exists public.businesses (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
 company_name text not null,
 bio text not null default '',
 company_registration_number text not null default '',
 public_liability_value text not null default '',
 public_liability_certificate_path text,
 trade_qualifications text not null default '',
 contact_email text,
 service_area text not null default '',
 published boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.business_members (
 business_id uuid not null references public.businesses(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'owner' check (role in ('owner','admin')),
 primary key (business_id,user_id)
);
alter table public.services add column if not exists business_id uuid references public.businesses(id);
insert into public.businesses(slug,company_name,bio,company_registration_number,public_liability_value,public_liability_certificate_path,trade_qualifications,contact_email,service_area,published)
select 'dark-peak-property-services', company_name, bio, company_registration_number, public_liability_value, public_liability_certificate_path, trade_qualifications, 'dean@darkpeakpropertyservices.com','Glossop and Greater Manchester',true
from public.business_details where id=1
on conflict(slug) do nothing;
update public.services set business_id=(select id from public.businesses where slug='dark-peak-property-services') where business_id is null;
insert into public.business_members(business_id,user_id,role)
select b.id,a.user_id,'owner' from public.businesses b cross join public.admin_users a
where b.slug='dark-peak-property-services'
on conflict do nothing;
-- Do not permit unassigned services after backfill.
alter table public.services alter column business_id set not null;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
drop policy if exists "Public reads published businesses" on public.businesses;
create policy "Public reads published businesses" on public.businesses for select to anon,authenticated
using (published or exists(select 1 from public.business_members m where m.business_id=id and m.user_id=(select auth.uid())));
drop policy if exists "Members update own businesses" on public.businesses;
create policy "Members update own businesses" on public.businesses for update to authenticated
using (exists(select 1 from public.business_members m where m.business_id=id and m.user_id=(select auth.uid())))
with check (exists(select 1 from public.business_members m where m.business_id=id and m.user_id=(select auth.uid())));
drop policy if exists "Members read own memberships" on public.business_members;
create policy "Members read own memberships" on public.business_members for select to authenticated using (user_id=(select auth.uid()));
-- Replace legacy global-admin permissions with per-business permissions.
drop policy if exists "Anyone can read active services" on public.services;
drop policy if exists "Admins manage services" on public.services;
create policy "Public reads published active services" on public.services for select to anon,authenticated
using ((active and exists(select 1 from public.businesses b where b.id=business_id and b.published))
or exists(select 1 from public.business_members m where m.business_id=services.business_id and m.user_id=(select auth.uid())));
create policy "Business members insert services" on public.services for insert to authenticated
with check (exists(select 1 from public.business_members m where m.business_id=services.business_id and m.user_id=(select auth.uid())));
create policy "Business members update services" on public.services for update to authenticated
using (exists(select 1 from public.business_members m where m.business_id=services.business_id and m.user_id=(select auth.uid())))
with check (exists(select 1 from public.business_members m where m.business_id=services.business_id and m.user_id=(select auth.uid())));
create policy "Business members delete services" on public.services for delete to authenticated
using (exists(select 1 from public.business_members m where m.business_id=services.business_id and m.user_id=(select auth.uid())));
commit;
-- Future self-service business signup must use a server-side or SECURITY DEFINER
-- provisioning function, never grant anonymous inserts to businesses or memberships.
