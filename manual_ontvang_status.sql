-- Run this SQL in your Supabase SQL Editor
-- This adds the "Ontvang" status for QR code pickup

INSERT INTO public.kos_item_statusse (kos_stat_naam) 
SELECT 'Ontvang'
WHERE NOT EXISTS (
  SELECT 1 FROM public.kos_item_statusse WHERE kos_stat_naam = 'Ontvang'
);

-- Verify it was added
SELECT kos_stat_id, kos_stat_naam 
FROM public.kos_item_statusse 
WHERE kos_stat_naam = 'Ontvang';
