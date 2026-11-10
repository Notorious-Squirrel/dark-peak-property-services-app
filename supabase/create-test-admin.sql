-- One List: grant admin access to a separately created Supabase Auth test user.
-- 1. In Supabase Dashboard > Authentication > Users, create a test user with
--    an email address you control and a strong, unique password.
-- 2. Replace the email below with that exact address.
-- 3. Run this script in Supabase SQL Editor.
-- 4. Sign in through docs/admin.html with the test user's credentials.
-- IMPORTANT: never share passwords or put them in SQL, GitHub, or frontend code.
do $$
declare
  test_user_id uuid;
begin
  select id into test_user_id
  from auth.users
  where lower(email) = lower('REPLACE_WITH_TEST_ADMIN_EMAIL');
  if test_user_id is null then
    raise exception 'Test account not found. Create it in Authentication > Users first and replace the email placeholder.';
  end if;
  insert into public.admin_users (user_id) values (test_user_id)
  on conflict (user_id) do nothing;
end $$;

-- To revoke admin access later, replace the email and run:
-- delete from public.admin_users
-- where user_id in (select id from auth.users where lower(email)=lower('REPLACE_WITH_TEST_ADMIN_EMAIL'));
