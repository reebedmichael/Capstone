-- =======================================
-- TEST SCHEMA ACCESS FOR ANON ROLE
-- =======================================

-- Check if anon role has USAGE on public schema
SELECT 
    grantee,
    object_schema,
    privilege_type
FROM information_schema.usage_privileges 
WHERE grantee = 'anon' 
AND object_schema = 'public';

-- Grant USAGE on public schema if not exists
GRANT USAGE ON SCHEMA public TO anon;

-- Test a simple query
SELECT COUNT(*) FROM public.kos_item;

-- Check current user and role
SELECT current_user, current_setting('role');

-- Check if we're connected as anon
SELECT 
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles 
WHERE rolname = 'anon';
