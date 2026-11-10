-- One List private per-customer planner storage. Run once in Supabase SQL Editor.
create table if not exists public.customer_planner (
 customer_id uuid primary key references auth.users(id) on delete cascade,
 planner jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 constraint customer_planner_object check (jsonb_typeof(planner)='object')
);
alter table public.customer_planner enable row level security;
drop policy if exists "Customer reads own planner" on public.customer_planner;
create policy "Customer reads own planner" on public.customer_planner for select to authenticated using (customer_id=(select auth.uid()));
drop policy if exists "Customer inserts own planner" on public.customer_planner;
create policy "Customer inserts own planner" on public.customer_planner for insert to authenticated with check (customer_id=(select auth.uid()));
drop policy if exists "Customer updates own planner" on public.customer_planner;
create policy "Customer updates own planner" on public.customer_planner for update to authenticated using (customer_id=(select auth.uid())) with check (customer_id=(select auth.uid()));
