-- Debug permissions and table existence
-- Run this in Supabase SQL Editor

-- 1. Check what tables exist
SELECT 'Tables in public schema:' as info;
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Check current user and role
SELECT 'Current user info:' as info;
SELECT current_user, session_user, current_database();

-- 3. Check anon role permissions on schema
SELECT 'Anon role schema permissions:' as info;
SELECT grantee, privilege_type 
FROM information_schema.usage_privileges 
WHERE object_schema = 'public' AND grantee = 'anon';

-- 4. Check anon role table permissions
SELECT 'Anon role table permissions:' as info;
SELECT table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE table_schema = 'public' AND grantee = 'anon'
ORDER BY table_name, privilege_type;

-- 5. Check if we can access tables as anon
SELECT 'Testing table access:' as info;

-- Try to access kos_item
SELECT 'kos_item exists:' as test, EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'kos_item'
) as exists;

-- Try to count kos_item
SELECT 'kos_item count:' as test;
SELECT COUNT(*) as count FROM public.kos_item;

-- 6. Check RLS status
SELECT 'RLS status:' as info;
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 7. Grant permissions again (in case they were lost)
SELECT 'Granting permissions...' as info;
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 8. Test again
SELECT 'Testing after granting permissions:' as info;
SELECT COUNT(*) as kos_item_count FROM public.kos_item;
