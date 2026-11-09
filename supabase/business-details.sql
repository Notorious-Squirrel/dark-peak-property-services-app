-- One List: business details (single-business version)
create table if not exists public.business_details (
 id integer primary key default 1 check (id = 1),
 company_name text not null default 'Dark Peak Property Services',
 updated_at timestamptz not null default now()
);
insert into public.business_details (id, company_name) values (1, 'Dark Peak Property Services') on conflict (id) do nothing;
alter table public.business_details enable row level security;
drop policy if exists "Public can view business details" on public.business_details;
create policy "Public can view business details" on public.business_details for select to anon, authenticated using (true);
drop policy if exists "Admin can add business details" on public.business_details;
create policy "Admin can add business details" on public.business_details for insert to authenticated with check (exists (select 1 from public.admin_users where user_id = (select auth.uid())));
drop policy if exists "Admin can edit business details" on public.business_details;
create policy "Admin can edit business details" on public.business_details for update to authenticated using (exists (select 1 from public.admin_users where user_id = (select auth.uid()))) with check (exists (select 1 from public.admin_users where user_id = (select auth.uid())));
