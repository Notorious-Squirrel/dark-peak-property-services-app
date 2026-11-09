-- Run once in the Supabase SQL editor before enabling centralised NPS feedback.
-- One submission per signed-in customer and wishlist job reference.
create table if not exists public.customer_feedback (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id) on delete cascade,
 job_key text not null check (char_length(job_key) between 1 and 200),
 job_name text not null check (char_length(job_name) between 1 and 200),
 project_name text not null default 'General' check (char_length(project_name)<=100),
 score integer not null check (score between 0 and 10),
 comment text not null default '' check (char_length(comment)<=1000),
 created_at timestamptz not null default now(),
 unique (customer_id, job_key)
);
alter table public.customer_feedback enable row level security;
drop policy if exists "Customers can submit own feedback" on public.customer_feedback;
create policy "Customers can submit own feedback" on public.customer_feedback for insert to authenticated with check (customer_id = (select auth.uid()));
drop policy if exists "Customers can read own feedback" on public.customer_feedback;
create policy "Customers can read own feedback" on public.customer_feedback for select to authenticated using (customer_id = (select auth.uid()));
drop policy if exists "Admins can read customer feedback" on public.customer_feedback;
create policy "Admins can read customer feedback" on public.customer_feedback for select to authenticated using (exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())));
create index if not exists customer_feedback_created_idx on public.customer_feedback(created_at desc);
