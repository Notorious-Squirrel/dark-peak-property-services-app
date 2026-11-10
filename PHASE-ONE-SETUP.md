# One List — Phase 1 activation

Phase 1 is a **business-specific catalogue**. Customers arrive via a contractor's shared link, browse without an account, then sign in/register to request work. A business UUID (not the owner's email address) is attached to the booking. Contractors see only their own business's enquiries and services. Private wishlists, projects and snag lists remain private to the customer until submitted.

## Database activation — do this in order
1. Ensure `supabase/customer-bookings.sql`, `supabase/customer-feedback.sql`, `supabase/customer-planner.sql` and `supabase/theme-settings.sql` have been applied.
2. Run `supabase/multi-business-foundation.sql` in Supabase SQL Editor. It migrates existing Dark Peak services and existing admin users into a business account.
3. Run `supabase/phase-one-business-associations.sql` in SQL Editor. It adds contractor/customer associations and business-specific booking/feedback security policies.
4. Test Dark Peak at `https://notorious-squirrel.github.io/dark-peak-property-services-app/?business=dark-peak-property-services`. Log in to `admin.html` to find the shareable catalogue URL.
5. Create a test booking from a separate customer account, then verify it appears only in the correct contractor admin dashboard.

**Important:** SQL files are committed but **not executed** in Supabase by GitHub deployment. Do not invite other businesses before the SQL is run and tested. Existing users are backfilled into Dark Peak based on their bookings. Existing customer wishlists remain per customer, not automatically shared with a contractor.

## Adding another contractor (manual pilot onboarding)
1. Create an email/password user in Supabase Authentication → Users using an email the contractor controls. Do not put passwords in SQL or GitHub.
2. Run the following SQL in SQL Editor, replacing the slug, name, email and service area. The contractor's Auth user must already exist:

```sql
do $$
declare new_business uuid;
declare owner_user uuid;
begin
  select id into owner_user from auth.users where lower(email)=lower('contractor@example.com');
  if owner_user is null then raise exception 'Create the contractor in Authentication first'; end if;
  insert into public.businesses(slug,company_name,contact_email,service_area,published)
  values('example-joinery','Example Joinery','contractor@example.com','Greater Manchester',true)
  returning id into new_business;
  insert into public.business_members(business_id,user_id,role)
  values(new_business,owner_user,'owner');
end $$;
```

3. Contractor logs in at `admin.html`, adds their own services and shares their business-specific URL.
4. For security, **do not** grant the contractor a record in the legacy global `admin_users` table.

## Phase 1 boundaries
- Contractor self-service signup and automated business provisioning are **not yet implemented**. Pilot onboarding is manual via the SQL above.
- The public marketplace is hidden from the customer app; `marketplace.html` remains in the repository as a future prototype.
- Customer planner data is private to the customer's account and not automatically exposed to contractors.
- Job photos are still device-local.
- The legacy Dark Peak fallback exists until the database migration is applied; do not onboard other contractors before activation.
- A full end-to-end multi-account security test in Supabase is still required.
