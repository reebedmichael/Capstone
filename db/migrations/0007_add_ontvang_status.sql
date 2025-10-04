-- =======================================
-- Migration: Add 'Ontvang' status for QR code pickup flow
-- Date: 2024-10-03
-- Description: Adds a new status 'Ontvang' to track when food items are picked up via QR code scanning
-- =======================================

-- Insert 'Ontvang' status if it doesn't already exist
INSERT INTO public.kos_item_statusse (kos_stat_naam) 
SELECT 'Ontvang'
WHERE NOT EXISTS (
  SELECT 1 FROM public.kos_item_statusse WHERE kos_stat_naam = 'Ontvang'
);

-- Verify the status was added
SELECT kos_stat_id, kos_stat_naam 
FROM public.kos_item_statusse 
WHERE kos_stat_naam = 'Ontvang';

