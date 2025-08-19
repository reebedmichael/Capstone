-- Comprehensive fix for all permission issues
-- Run this in Supabase SQL Editor

-- 1. Grant schema permissions to anon role
GRANT USAGE ON SCHEMA public TO anon;

-- 2. Grant table permissions to anon role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;

-- 3. Grant sequence permissions to anon role
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 4. Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon;

-- 5. Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO anon;

-- 6. Disable RLS for all tables temporarily for testing
ALTER TABLE public.gebruikers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.kos_item DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.spyskaart DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.spyskaart_kos_item DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.mandjie DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.bestelling DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.bestelling_kos_item DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.beursie_transaksie DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.week_dag DISABLE ROW LEVEL SECURITY;

-- 7. Verify the changes
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    hasselect,
    hasinsert,
    hasupdate,
    hasdelete
FROM pg_tables t
JOIN information_schema.table_privileges p ON t.tablename = p.table_name
WHERE t.schemaname = 'public' 
    AND p.grantee = 'anon'
ORDER BY t.tablename;

-- 8. Test query to verify permissions
SELECT COUNT(*) as kos_item_count FROM public.kos_item;
