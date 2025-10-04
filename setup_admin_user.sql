-- Run this SQL in your Supabase SQL Editor
-- This sets up an admin user for QR scanning

-- 1. Create admin type if it doesn't exist
INSERT INTO public.admin_tipes (admin_tipe_naam) 
VALUES ('Tersiêr')
ON CONFLICT DO NOTHING;

-- 2. Make your current user an admin (replace with your actual email)
UPDATE public.gebruikers 
SET admin_tipe_id = (
  SELECT admin_tipe_id 
  FROM public.admin_tipes 
  WHERE admin_tipe_naam = 'Tersiêr'
)
WHERE gebr_epos = 'debeermichael17@gmail.com';  -- REPLACE THIS WITH YOUR ACTUAL EMAIL

-- 3. Verify the admin setup
SELECT 
  gebr_epos,
  admin_tipes.admin_tipe_naam
FROM public.gebruikers 
LEFT JOIN public.admin_tipes ON gebruikers.admin_tipe_id = admin_tipes.admin_tipe_id
WHERE gebr_epos = 'debeermichael17@gmail.com';  -- REPLACE THIS WITH YOUR ACTUAL EMAIL
