-- Fix admin user setup (without description column)

-- 1. Insert Tersiêr admin type if it doesn't exist (without description)
INSERT INTO public.admin_tipes (admin_tipe_naam) 
VALUES ('Tersiêr')
ON CONFLICT (admin_tipe_naam) DO NOTHING;

-- 2. Update user to be admin
UPDATE public.gebruikers 
SET admin_tipe_id = (
    SELECT admin_tipe_id 
    FROM public.admin_tipes 
    WHERE admin_tipe_naam = 'Tersiêr'
)
WHERE gebr_id = 'a624574f-fd42-4deb-b4b9-741ba5df33e9';

-- 3. Verify the user is now admin
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
