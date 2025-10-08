-- Check if admin_tipes table exists and has Tersiêr
SELECT * FROM public.admin_tipes;

-- If table doesn't exist, create it
CREATE TABLE IF NOT EXISTS public.admin_tipes (
    admin_tipe_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_tipe_naam VARCHAR(50) NOT NULL UNIQUE,
    admin_tipe_beskrywing TEXT
);

-- Insert Tersiêr admin type if it doesn't exist
INSERT INTO public.admin_tipes (admin_tipe_naam, admin_tipe_beskrywing) 
VALUES ('Tersiêr', 'Tertiary Admin - Can scan QR codes')
ON CONFLICT (admin_tipe_naam) DO NOTHING;

-- Show all admin types
SELECT * FROM public.admin_tipes;
