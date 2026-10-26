ALBRIGHT JUNIOR SCHOOL — ONLINE MANAGEMENT STARTER

FILES
- index.html: website interface (online-ready starter; edit the display in the Settings tab after admin login)
- schema.sql: database tables and row-level security policies for Supabase

IMPORTANT LIMITATIONS
This is a starter build, not a fully audited production school system. Do not add real student data until the SQL is installed, access policies are tested, and the parent/teacher/bursar/admin accounts are configured. The database policies are intended to block parent access to marks unless the child's annual fees are fully paid, but they must be tested in Supabase before use.

DEPLOYMENT OVERVIEW
1. In Supabase, open SQL Editor and run schema.sql.
2. In Supabase > Project Settings > API, copy Project URL and anon/public key. Never use the service_role key in a browser.
3. Put index.html in a GitHub repository, then import that repository into Netlify to deploy.
4. Open the deployed site and enter the Supabase URL and anon/public key on the connection screen.
5. In Supabase Authentication, create the first administrator user. Then create their profile row in public.profiles and set role='admin'. Create parent/teacher/bursar profiles and parent_students links through SQL Editor or a properly secured admin workflow.
6. Test each role using test records before real use. Check that a parent cannot read marks before full payment, cannot see another family's student, and gains access only after a bursar records full payment.

SECURITY NOTE
The starter interface is not yet a complete admin user-management workflow. The first admin profile and parent links need to be configured in Supabase. Use unique passwords, enable MFA for administrators if possible, keep backups, and follow applicable Ugandan student-data privacy requirements.
