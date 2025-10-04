-- Fix the gebruikers table structure
-- Add missing columns if they don't exist

-- Add gebr_tipe column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'gebruikers' 
                   AND column_name = 'gebr_tipe') THEN
        ALTER TABLE public.gebruikers ADD COLUMN gebr_tipe VARCHAR(50) DEFAULT 'Gewoon';
    END IF;
END $$;

-- Add other missing columns if needed
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'gebruikers' 
                   AND column_name = 'gebr_naam') THEN
        ALTER TABLE public.gebruikers ADD COLUMN gebr_naam VARCHAR(255);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'gebruikers' 
                   AND column_name = 'gebr_van') THEN
        ALTER TABLE public.gebruikers ADD COLUMN gebr_van VARCHAR(255);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'gebruikers' 
                   AND column_name = 'gebr_geslag') THEN
        ALTER TABLE public.gebruikers ADD COLUMN gebr_geslag VARCHAR(10);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'gebruikers' 
                   AND column_name = 'gebr_telefoon') THEN
        ALTER TABLE public.gebruikers ADD COLUMN gebr_telefoon VARCHAR(20);
    END IF;
END $$;

-- Insert the new user
INSERT INTO public.gebruikers (
    gebr_id,
    gebr_epos,
    gebr_naam,
    gebr_van,
    gebr_geslag,
    gebr_telefoon,
    gebr_tipe,
    admin_tipe_id
) VALUES (
    'a624574f-fd42-4deb-b4b9-741ba5df33e9',
    'debeermichael17+qr@gmail.com',
    'Michael',
    'de Beer',
    'Man',
    NULL,
    'Gewoon',
    NULL
) ON CONFLICT (gebr_id) DO UPDATE SET
    gebr_epos = EXCLUDED.gebr_epos,
    gebr_naam = EXCLUDED.gebr_naam,
    gebr_van = EXCLUDED.gebr_van,
    gebr_geslag = EXCLUDED.gebr_geslag,
    gebr_telefoon = EXCLUDED.gebr_telefoon,
    gebr_tipe = EXCLUDED.gebr_tipe;

-- Make this user an admin for QR testing
UPDATE public.gebruikers 
SET admin_tipe_id = (
    SELECT admin_tipe_id 
    FROM public.admin_tipes 
    WHERE admin_tipe_naam = 'Tersiêr'
)
WHERE gebr_id = 'a624574f-fd42-4deb-b4b9-741ba5df33e9';

-- Verify the user was created
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
