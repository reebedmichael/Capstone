-- =======================================
-- FINAL PERMISSION FIX FOR ANON ROLE
-- =======================================

-- 1. Grant USAGE on public schema
GRANT USAGE ON SCHEMA public TO anon;

-- 2. Grant permissions on all existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;

-- 3. Grant permissions on all sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 4. Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon;

-- 5. Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO anon;

-- 6. Grant CREATE on public schema (if needed)
GRANT CREATE ON SCHEMA public TO anon;

-- 7. Verify the grants
SELECT 
    grantee,
    object_schema,
    privilege_type
FROM information_schema.usage_privileges 
WHERE grantee = 'anon' 
AND object_schema = 'public';

-- 8. Test a simple query
SELECT COUNT(*) FROM public.kos_item;
