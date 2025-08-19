-- =======================================
-- FIX TABLE NAMES - USE LOWERCASE
-- =======================================

-- Drop existing tables if they exist (be careful!)
-- DROP TABLE IF EXISTS public."KOS_ITEM" CASCADE;
-- DROP TABLE IF EXISTS public."GEBRUIKERS" CASCADE;
-- DROP TABLE IF EXISTS public."SPYSKAART" CASCADE;
-- DROP TABLE IF EXISTS public."MANDJIE" CASCADE;
-- DROP TABLE IF EXISTS public."BESTELLING" CASCADE;
-- DROP TABLE IF EXISTS public."BESTELLING_KOS_ITEM" CASCADE;
-- DROP TABLE IF EXISTS public."BEURSIE_TRANSAKSIE" CASCADE;
-- DROP TABLE IF EXISTS public."WEEK_DAG" CASCADE;

-- =======================================
-- EXTENSIONS
-- =======================================
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- =======================================
-- BASIS TABELLE (LOWERCASE NAMES)
-- =======================================

create table if not exists public.admin_tipes (
  admin_tipe_id uuid primary key default gen_random_uuid(),
  admin_tipe_naam text not null default ''
);

create table if not exists public.kampus (
  kampus_id uuid primary key default gen_random_uuid(),
  kampus_naam text not null default '',
  kampus_ligging text default ''
);

create table if not exists public.gebruiker_tipes (
  gebr_tipe_id uuid primary key default gen_random_uuid(),
  gebr_tipe_naam text not null default '',
  gebr_tipe_beskrywing text default '',
  gebr_toelaag double precision
);

create table if not exists public.gebruikers (
  gebr_id uuid primary key default gen_random_uuid(),
  gebr_geskep_datum timestamp default now(),
  gebr_epos text default '',
  gebr_naam text default '',
  gebr_van text default '',
  gebr_selfoon text default '',
  beursie_balans double precision default 0.0,
  is_aktief boolean default true,
  gebr_tipe_id uuid references public.gebruiker_tipes(gebr_tipe_id),
  admin_tipe_id uuid references public.admin_tipes(admin_tipe_id),
  kampus_id uuid references public.kampus(kampus_id)
);

-- =======================================
-- BESTELLINGS
-- =======================================

create table if not exists public.bestelling (
  best_id uuid primary key default gen_random_uuid(),
  best_geskep_datum timestamp default now(),
  best_volledige_prys double precision default 0.0,
  gebr_id uuid references public.gebruikers(gebr_id),
  kampus_id uuid references public.kampus(kampus_id)
);

create table if not exists public.kos_item (
  kos_item_id uuid primary key default gen_random_uuid(),
  kos_item_naam text not null default '',
  kos_item_beskrywing text default '',
  kos_item_koste double precision default 0.0,
  kos_item_prentjie text,
  is_aktief boolean default true,
  kos_item_is_templaat boolean default false,
  kos_item_geskep_datum timestamp default now()
);

create table if not exists public.bestelling_kos_item (
  best_kos_id uuid primary key default gen_random_uuid(),
  best_id uuid references public.bestelling(best_id),
  kos_item_id uuid references public.kos_item(kos_item_id)
);

-- =======================================
-- MANDJIE EN SPYSKAART
-- =======================================

create table if not exists public.mandjie (
  mand_id uuid primary key default gen_random_uuid(),
  gebr_id uuid references public.gebruikers(gebr_id),
  kos_item_id uuid references public.kos_item(kos_item_id)
);

create table if not exists public.spyskaart (
  spyskaart_id uuid primary key default gen_random_uuid(),
  spyskaart_naam text not null default '',
  spyskaart_is_templaat boolean default false,
  spyskaart_datum timestamp default now()
);

create table if not exists public.week_dag (
  week_dag_id uuid primary key default gen_random_uuid(),
  week_dag_naam text not null default ''
);

create table if not exists public.spyskaart_kos_item (
  spyskaart_kos_id uuid primary key default gen_random_uuid(),
  spyskaart_kos_afsny_datum timestamp default now(),
  spyskaart_id uuid references public.spyskaart(spyskaart_id),
  kos_item_id uuid references public.kos_item(kos_item_id),
  week_dag_id uuid references public.week_dag(week_dag_id)
);

-- =======================================
-- BEURSIE
-- =======================================

create table if not exists public.beursie_transaksie (
  trans_id uuid primary key default gen_random_uuid(),
  trans_bedrag double precision not null,
  trans_tipe text not null, -- 'inbetaling' or 'uitbetaling'
  trans_beskrywing text default '',
  trans_geskep_datum timestamp default now(),
  gebr_id uuid references public.gebruikers(gebr_id)
);

-- =======================================
-- GRANT PERMISSIONS
-- =======================================

-- Grant schema permissions
GRANT USAGE ON SCHEMA public TO anon;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Set default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO anon;

-- =======================================
-- SEEDS (BASIES)
-- =======================================
insert into public.kampus (kampus_naam, kampus_ligging) values ('Centurion', 'Gauteng') on conflict do nothing;
insert into public.gebruiker_tipes (gebr_tipe_naam) values ('Student'), ('Personeel') on conflict do nothing;
insert into public.kos_item (kos_item_naam, kos_item_koste) values ('Boerewors rol', 45.00), ('Veggie wrap', 55.00) on conflict do nothing;
insert into public.week_dag (week_dag_naam) values ('Maandag'), ('Dinsdag'), ('Woensdag'), ('Donderdag'), ('Vrydag') on conflict do nothing;

-- =======================================
-- VERIFY
-- =======================================
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

SELECT COUNT(*) as kos_item_count FROM public.kos_item;
