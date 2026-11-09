-- One List customer accounts and shared booking approvals. Run once in Supabase SQL Editor.
create table if not exists public.booking_requests (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
 customer_name text not null,
 customer_email text not null,
 phone text not null,
 postcode text not null,
 notes text not null default '',
 preferred_date date not null,
 preferred_time text not null default 'Flexible',
 jobs jsonb not null,
 indicative_total numeric(12,2) not null default 0,
 status text not null default 'requested' check (status in ('requested','confirmed','declined')),
 confirmed_date date,
 confirmed_time text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint valid_jobs check (jsonb_typeof(jobs) = 'array')
);
alter table public.booking_requests enable row level security;
drop policy if exists "Customers view own bookings" on public.booking_requests;
create policy "Customers view own bookings" on public.booking_requests for select to authenticated using (customer_id = (select auth.uid()));
drop policy if exists "Customers create own requests" on public.booking_requests;
create policy "Customers create own requests" on public.booking_requests for insert to authenticated with check (customer_id = (select auth.uid()) and status = 'requested' and confirmed_date is null and confirmed_time is null);
drop policy if exists "Admins view all bookings" on public.booking_requests;
create policy "Admins view all bookings" on public.booking_requests for select to authenticated using (exists(select 1 from public.admin_users where user_id = (select auth.uid())));
drop policy if exists "Admins update bookings" on public.booking_requests;
create policy "Admins update bookings" on public.booking_requests for update to authenticated using (exists(select 1 from public.admin_users where user_id = (select auth.uid()))) with check (exists(select 1 from public.admin_users where user_id = (select auth.uid())));
create index if not exists booking_requests_customer_created_idx on public.booking_requests(customer_id,created_at desc);
create index if not exists booking_requests_date_idx on public.booking_requests(preferred_date);
-- Do not run the deferred multi-business migration yet; this table currently serves the Dark Peak single-business pilot.
