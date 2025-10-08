-- Check the structure of the gebruikers table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'gebruikers' 
AND table_schema = 'public'
ORDER BY ordinal_position;
