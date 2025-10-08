-- Fix admin user setup

-- 1. Create admin_tipes table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_tipes (
    admin_tipe_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_tipe_naam VARCHAR(50) NOT NULL UNIQUE,
    admin_tipe_beskrywing TEXT
);

-- 2. Insert Tersiêr admin type if it doesn't exist
INSERT INTO public.admin_tipes (admin_tipe_naam, admin_tipe_beskrywing) 
VALUES ('Tersiêr', 'Tertiary Admin - Can scan QR codes')
ON CONFLICT (admin_tipe_naam) DO NOTHING;

-- 3. Update user to be admin
UPDATE public.gebruikers 
SET admin_tipe_id = (
    SELECT admin_tipe_id 
    FROM public.admin_tipes 
    WHERE admin_tipe_naam = 'Tersiêr'
)
WHERE gebr_id = 'a624574f-fd42-4deb-b4b9-741ba5df33e9';

-- 4. Verify the user is now admin
SELECT 
    gebr_id,
    gebr_epos,
    gebr_naam,
    gebr_van,
    gebr_tipe,
    admin_tipes.admin_tipe_naam as admin_tipe
FROM public.gebruikers 
LEFT JOIN public.admin_tipes ON gebruikers.admin_tipe_id = admin_tipes.admin_tipe_id
WHERE gebr_id = 'a624574f-fd42-4deb-b4b9-741ba5df33e9';
