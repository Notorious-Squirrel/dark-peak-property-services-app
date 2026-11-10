-- Run in Supabase SQL Editor before deploying the AI pricing Edge Function.
create table if not exists public.ai_pricing_usage (
 business_id uuid primary key references public.businesses(id) on delete cascade,
 used integer not null default 0 check (used between 0 and 3),
 updated_at timestamptz not null default now()
);
alter table public.ai_pricing_usage enable row level security;
revoke all on public.ai_pricing_usage from anon, authenticated;
create or replace function public.claim_free_ai_price(p_business uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare remaining integer;
begin
 if auth.uid() is null or not exists (
  select 1 from public.business_members where business_id=p_business and user_id=auth.uid()
 ) then raise exception 'Not authorised for this business'; end if;
 insert into public.ai_pricing_usage(business_id,used) values(p_business,0)
 on conflict (business_id) do nothing;
 update public.ai_pricing_usage set used=used+1,updated_at=now()
 where business_id=p_business and used<3 returning 3-used into remaining;
 if remaining is null then raise exception 'All three free AI pricing recommendations have been used'; end if;
 return remaining;
end $$;
create or replace function public.refund_free_ai_price(p_business uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
 -- Not exposed to authenticated users. Called by Edge Function service role only.
 if auth.role() <> 'service_role' then raise exception 'Not authorised'; end if;
 update public.ai_pricing_usage set used=greatest(used-1,0),updated_at=now() where business_id=p_business;
end $$;
revoke all on function public.claim_free_ai_price(uuid) from public,anon;
grant execute on function public.claim_free_ai_price(uuid) to authenticated;
revoke all on function public.refund_free_ai_price(uuid) from public,anon,authenticated;
grant execute on function public.refund_free_ai_price(uuid) to service_role;
-- Only business members can read their remaining allowance.
create policy "Members read AI allowance" on public.ai_pricing_usage for select to authenticated
using(exists(select 1 from public.business_members m where m.business_id=ai_pricing_usage.business_id and m.user_id=auth.uid()));
grant select on public.ai_pricing_usage to authenticated;
