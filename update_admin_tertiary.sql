-- Update user to use the correct "Tertiary" admin type

-- Update user to be admin with "Tertiary" type
UPDATE public.gebruikers 
SET admin_tipe_id = (
    SELECT admin_tipe_id 
    FROM public.admin_tipes 
    WHERE admin_tipe_naam = 'Tertiary'
)
WHERE gebr_id = 'a624574f-fd42-4deb-b4b9-741ba5df33e9';

-- Verify the user is now admin
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
