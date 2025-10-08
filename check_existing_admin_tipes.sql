-- Check existing admin_tipes table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'admin_tipes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check existing admin types
SELECT * FROM public.admin_tipes;
