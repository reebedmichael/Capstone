-- =======================================
-- ADD STATUS TABLES AND QUANTITY FIELD
-- =======================================

-- Add item_hoev field to bestelling_kos_item table
alter table public.bestelling_kos_item add column if not exists item_hoev integer default 1;

-- Create kos_item_statusse table
create table if not exists public.kos_item_statusse (
  kos_stat_id uuid primary key default gen_random_uuid(),
  kos_stat_naam text not null default ''
);

-- Create best_kos_item_statusse table
create table if not exists public.best_kos_item_statusse (
  best_kos_stat_id uuid primary key default gen_random_uuid(),
  best_kos_wysig_datum timestamp default now(),
  best_kos_id uuid references public.bestelling_kos_item(best_kos_id),
  kos_stat_id uuid references public.kos_item_statusse(kos_stat_id)
);

-- =======================================
-- SEED STATUS DATA
-- =======================================

-- Insert status types
insert into public.kos_item_statusse (kos_stat_naam) values 
  ('Wag vir afhaal'),
  ('In voorbereiding'),
  ('Afgehandel'),
  ('Gekanselleer')
on conflict do nothing;

-- =======================================
-- GRANT PERMISSIONS
-- =======================================

-- Grant permissions for new tables
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kos_item_statusse TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.best_kos_item_statusse TO anon;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- =======================================
-- VERIFY
-- =======================================

SELECT 'Status tables created successfully' as info;
SELECT kos_stat_naam FROM public.kos_item_statusse ORDER BY kos_stat_naam;
