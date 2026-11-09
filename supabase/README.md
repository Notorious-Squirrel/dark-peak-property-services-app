# Dark Peak service admin – Supabase setup

The customer app is currently published through GitHub Pages. To activate live service editing:

1. Create a Supabase project at https://supabase.com/dashboard.
2. In SQL Editor, run `supabase/schema.sql`.
3. Under Authentication > Users, create an admin account (or sign up through a configured authentication flow).
4. Copy the user's UUID and run the admin grant statement at the bottom of the schema.
5. In Project Settings > API, find your **Project URL** and **publishable/anon key**. These are designed for use in the browser with RLS; **never share the secret/service_role key**.
6. Configure the web app with the project URL and publishable key. The admin interface can then sign in using Supabase Auth and manage services.
7. Seed the current catalogue in the services table before switching the customer catalogue to the live data source.

Security: Public users can only read active services; only members of `admin_users` can change services. No database writes are authorised by a password embedded in the website.

The GitHub Pages site cannot itself securely store passwords or act as an authentication server. Supabase Auth and row-level security handle that responsibility.
