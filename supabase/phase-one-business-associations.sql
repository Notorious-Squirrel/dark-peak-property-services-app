-- ONE LIST PHASE 1: run in Supabase SQL Editor AFTER existing customer-bookings,
-- customer-feedback, customer-planner and theme-settings migrations.
-- Run the separate multi-business-foundation.sql first. This migration is idempotent.
begin;
alter table public.businesses add column if not exists theme_accent text not null default '#f28c28';
alter table public.businesses add column if not exists theme_background text not null default '#171a1d';
alter table public.businesses add column if not exists theme_surface text not null default '#292e31';
update public.businesses b set
 theme_accent=coalesce(d.theme_accent,'#f28c28'),
 theme_background=coalesce(d.theme_background,'#171a1d'),
 theme_surface=coalesce(d.theme_surface,'#292e31')
from public.business_details d where d.id=1 and b.slug='dark-peak-property-services';
create table if not exists public.customer_businesses(
 customer_id uuid not null references auth.users(id) on delete cascade,
 business_id uuid not null references public.businesses(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(customer_id,business_id)
);
alter table public.customer_businesses enable row level security;
drop policy if exists "Customers see own associations" on public.customer_businesses;
create policy "Customers see own associations" on public.customer_businesses for select to authenticated
 using(customer_id=(select auth.uid()) or exists(select 1 from public.business_members m where m.business_id=customer_businesses.business_id and m.user_id=(select auth.uid())));
drop policy if exists "Customers join published businesses" on public.customer_businesses;
create policy "Customers join published businesses" on public.customer_businesses for insert to authenticated
 with check(customer_id=(select auth.uid()) and exists(select 1 from public.businesses b where b.id=business_id and b.published));
alter table public.booking_requests add column if not exists business_id uuid references public.businesses(id);
update public.booking_requests set business_id=(select id from public.businesses where slug='dark-peak-property-services') where business_id is null;
alter table public.booking_requests alter column business_id set not null;
create index if not exists booking_requests_business_created_idx on public.booking_requests(business_id,created_at desc);
insert into public.customer_businesses(customer_id,business_id)
 select distinct customer_id,business_id from public.booking_requests
 on conflict do nothing;
drop policy if exists "Admins view all bookings" on public.booking_requests;
drop policy if exists "Admins update bookings" on public.booking_requests;
drop policy if exists "Customers create own requests" on public.booking_requests;
create policy "Customers create own requests" on public.booking_requests for insert to authenticated
 with check(customer_id=(select auth.uid()) and status='requested' and confirmed_date is null and confirmed_time is null
 and exists(select 1 from public.businesses b where b.id=business_id and b.published));
create policy "Members view business bookings" on public.booking_requests for select to authenticated
 using(exists(select 1 from public.business_members m where m.business_id=booking_requests.business_id and m.user_id=(select auth.uid())));
create policy "Members update business bookings" on public.booking_requests for update to authenticated
 using(exists(select 1 from public.business_members m where m.business_id=booking_requests.business_id and m.user_id=(select auth.uid())))
 with check(exists(select 1 from public.business_members m where m.business_id=booking_requests.business_id and m.user_id=(select auth.uid())));
alter table public.customer_feedback add column if not exists business_id uuid references public.businesses(id);
update public.customer_feedback set business_id=(select id from public.businesses where slug='dark-peak-property-services') where business_id is null;
alter table public.customer_feedback alter column business_id set not null;
drop policy if exists "Admins can read customer feedback" on public.customer_feedback;
create policy "Members read business feedback" on public.customer_feedback for select to authenticated
 using(exists(select 1 from public.business_members m where m.business_id=customer_feedback.business_id and m.user_id=(select auth.uid())));
drop policy if exists "Customers can submit own feedback" on public.customer_feedback;
create policy "Customers can submit own feedback" on public.customer_feedback for insert to authenticated
 with check(customer_id=(select auth.uid()) and exists(select 1 from public.customer_businesses cb where cb.customer_id=(select auth.uid()) and cb.business_id=customer_feedback.business_id));
-- Existing feedback uniqueness was per user/job; allow distinct businesses.
alter table public.customer_feedback drop constraint if exists customer_feedback_customer_id_job_key_key;
create unique index if not exists customer_feedback_business_customer_job_uq on public.customer_feedback(business_id,customer_id,job_key);
-- Business owners may update only their own business details.
drop policy if exists "Members update own businesses" on public.businesses;
create policy "Members update own businesses" on public.businesses for update to authenticated
 using(exists(select 1 from public.business_members m where m.business_id=businesses.id and m.user_id=(select auth.uid())))
 with check(exists(select 1 from public.business_members m where m.business_id=businesses.id and m.user_id=(select auth.uid())));
commit;
