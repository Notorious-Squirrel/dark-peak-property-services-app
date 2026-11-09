-- Run in Supabase SQL Editor after creating your project.
create table if not exists public.services (
 id bigint generated always as identity primary key,
 category text not null,
 name text not null,
 description text not null default '',
 price numeric(10,2) not null default 0 check (price >= 0),
 price_type text not null default 'fixed' check (price_type in ('fixed','item','from','survey')),
 sort_order integer not null default 0,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.admin_users (
 user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.services enable row level security;
alter table public.admin_users enable row level security;
drop policy if exists "Anyone can read active services" on public.services;
create policy "Anyone can read active services" on public.services for select to anon, authenticated using (active = true or exists(select 1 from public.admin_users where user_id = (select auth.uid())));
drop policy if exists "Admins manage services" on public.services;
create policy "Admins manage services" on public.services for all to authenticated using (exists(select 1 from public.admin_users where user_id = (select auth.uid()))) with check (exists(select 1 from public.admin_users where user_id = (select auth.uid())));
-- No client-accessible policies on admin_users: admin membership is managed in SQL Editor.
-- After creating your user in Authentication > Users, grant access by running:
-- insert into public.admin_users(user_id) values ('YOUR-AUTH-USER-UUID');
-- IMPORTANT: Only use the publishable/anon key in the web app. Never use the service_role/secret key.
