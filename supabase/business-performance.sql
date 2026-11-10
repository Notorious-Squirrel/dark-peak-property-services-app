-- One List contractor performance tracking. Run once in Supabase SQL Editor.
alter table public.booking_requests add column if not exists completed_at timestamptz;
alter table public.booking_requests add column if not exists actual_income numeric(12,2);
alter table public.booking_requests drop constraint if exists booking_actual_income_nonnegative;
alter table public.booking_requests add constraint booking_actual_income_nonnegative check(actual_income is null or actual_income >= 0);
-- Existing business-scoped booking RLS policies continue to apply.
-- Income is recorded manually when a contractor marks a booking completed.
