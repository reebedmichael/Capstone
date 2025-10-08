-- =======================================
-- EXTENSIONS
-- =======================================
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- =======================================
-- BASIS TABELLE
-- =======================================

create table if not exists public.ADMIN_TIPES (
  ADMIN_TIPE_ID uuid primary key default gen_random_uuid(),
  ADMIN_TIPE_NAAM text not null default ''
);

create table if not exists public.KAMPUS (
  KAMPUS_ID uuid primary key default gen_random_uuid(),
  KAMPUS_NAAM text not null default '',
  KAMPUS_LIGGING text default ''
);

create table if not exists public.GEBRUIKER_TIPES (
  GEBR_TIPE_ID uuid primary key default gen_random_uuid(),
  GEBR_TIPE_NAAM text not null default '',
  GEBR_TIPE_BESKRYWING text default '',
  GEBR_TOELAAG double precision
);

create table if not exists public.GEBRUIKERS (
  GEBR_ID uuid primary key default gen_random_uuid(),
  GEBR_GESKEP_DATUM timestamp default now(),
  GEBR_EPOS text default '',
  GEBR_NAAM text default '',
  GEBR_VAN text default '',
  BEURSIE_BALANS double precision,
  IS_AKTIEF boolean,
  GEBR_TIPE_ID uuid references public.GEBRUIKER_TIPES(GEBR_TIPE_ID),
  ADMIN_TIPE_ID uuid references public.ADMIN_TIPES(ADMIN_TIPE_ID),
  KAMPUS_ID uuid references public.KAMPUS(KAMPUS_ID)
);

-- =======================================
-- BESTELLINGS
-- =======================================

create table if not exists public.BESTELLING (
  BEST_ID uuid primary key default gen_random_uuid(),
  BEST_GESKEP_DATUM timestamp default now(),
  BEST_VOLLEDIGE_PRYS double precision,
  GEBR_ID uuid references public.GEBRUIKERS(GEBR_ID),
  KAMPUS_ID uuid references public.KAMPUS(KAMPUS_ID)
);

create table if not exists public.KOS_ITEM (
  KOS_ITEM_ID uuid primary key default gen_random_uuid(),
  KOS_ITEM_NAAM text not null default '',
  KOS_ITEM_BESKRYWING text default '',
  KOS_ITEM_KOSTE double precision,
  KOS_ITEM_PRENTJIE text,
  IS_AKTIEF boolean default true,
  KOS_ITEM_IS_TEMPLAAT boolean default false,
  KOS_ITEM_GESKEP_DATUM timestamp default now()
);

create table if not exists public.BESTELLING_KOS_ITEM (
  BEST_KOS_ID uuid primary key default gen_random_uuid(),
  BEST_ID uuid references public.BESTELLING(BEST_ID),
  KOS_ITEM_ID uuid references public.KOS_ITEM(KOS_ITEM_ID)
);

create table if not exists public.KOS_ITEM_STATUSSE (
  KOS_STAT_ID uuid primary key default gen_random_uuid(),
  KOS_STAT_NAAM text not null default ''
);

create table if not exists public.BEST_KOS_ITEM_STATUSSE (
  BEST_KOS_STAT_ID uuid primary key default gen_random_uuid(),
  BEST_KOS_WYSIG_DATUM timestamp default now(),
  BEST_KOS_ID uuid references public.BESTELLING_KOS_ITEM(BEST_KOS_ID),
  KOS_STAT_ID uuid references public.KOS_ITEM_STATUSSE(KOS_STAT_ID)
);

-- =======================================
-- FEEDBACK EN TERUGVOER
-- =======================================

create table if not exists public.TERUGVOER (
  TERUG_ID uuid primary key default gen_random_uuid(),
  TERUG_NAAM text not null default '',
  TERUG_BESKRYWING text default ''
);

create table if not exists public.BESTELLING_TERUGVOER (
  BEST_TERUG_ID uuid primary key default gen_random_uuid(),
  GESKEP_DATUM timestamp default now(),
  BEST_ID uuid references public.BESTELLING(BEST_ID),
  TERUG_ID uuid references public.TERUGVOER(TERUG_ID)
);

-- =======================================
-- BEURSIE EN TRANSAKSIES
-- =======================================

create table if not exists public.TRANSAKSIE_TIPE (
  TRANS_TIPE_ID uuid primary key default gen_random_uuid(),
  TRANS_TIPE_NAAM text not null default ''
);

create table if not exists public.BEURSIE_TRANSAKSIE (
  TRANS_ID uuid primary key default gen_random_uuid(),
  TRANS_GESKEP_DATUM timestamp default now(),
  TRANS_BEDRAG double precision,
  TRANS_BESKRYWING text default '',
  GEBR_ID uuid references public.GEBRUIKERS(GEBR_ID),
  TRANS_TIPE_ID uuid references public.TRANSAKSIE_TIPE(TRANS_TIPE_ID)
);

-- =======================================
-- DIEET EN VOORKEURE
-- =======================================

create table if not exists public.DIEET_VEREISTE (
  DIEET_ID uuid primary key default gen_random_uuid(),
  DIEET_NAAM text not null default '',
  DIEET_BESKRYWING text default ''
);

create table if not exists public.GEBRUIKER_DIEET_VEREISTES (
  GEBR_DIEET_ID uuid primary key default gen_random_uuid(),
  GEBR_ID uuid references public.GEBRUIKERS(GEBR_ID),
  DIEET_ID uuid references public.DIEET_VEREISTE(DIEET_ID)
);

create table if not exists public.KOS_ITEM_DIEET_VEREISTES (
  KOS_ITEM_DIEET_ID uuid primary key default gen_random_uuid(),
  KOS_ITEM_ID uuid references public.KOS_ITEM(KOS_ITEM_ID),
  DIEET_ID uuid references public.DIEET_VEREISTE(DIEET_ID)
);

-- =======================================
-- KENNISGEWINGS
-- =======================================

create table if not exists public.KENNISGEWING_TIPES (
  KENNIS_TIPE_ID uuid primary key default gen_random_uuid(),
  KENNIS_TIPE_NAAM text not null default ''
);

create table if not exists public.KENNISGEWINGS (
  KENNIS_ID uuid primary key default gen_random_uuid(),
  KENNIS_BESKRYWING text default '',
  KENNIS_GELEES boolean default false,
  KENNIS_GESKEP_DATUM timestamp default now(),
  GEBR_ID uuid references public.GEBRUIKERS(GEBR_ID),
  KENNIS_TIPE_ID uuid references public.KENNISGEWING_TIPES(KENNIS_TIPE_ID)
);

create table if not exists public.GLOBALE_KENNISGEWINGS (
  GLOB_KENNIS_ID uuid primary key default gen_random_uuid(),
  GLOB_KENNIS_BESKRYWING text default '',
  GLOB_KENNIS_GESKEP_DATUM timestamp default now(),
  KENNIS_TIPE_ID uuid references public.KENNISGEWING_TIPES(KENNIS_TIPE_ID)
);

-- =======================================
-- LOGGING
-- =======================================

create table if not exists public.LOG_TIPE (
  LOG_TIPE_ID uuid primary key default gen_random_uuid(),
  LOG_TIPE_NAAM text not null default ''
);

create table if not exists public.LOGBOEK (
  LOG_ID uuid primary key default gen_random_uuid(),
  LOG_BESKRYWING text default '',
  LOG_DATUM_GESKEP timestamp default now(),
  LOG_TIPE_ID uuid references public.LOG_TIPE(LOG_TIPE_ID)
);

-- =======================================
-- MANDJIE EN SPYSKAART
-- =======================================

create table if not exists public.MANDJIE (
  MAND_ID uuid primary key default gen_random_uuid(),
  GEBR_ID uuid references public.GEBRUIKERS(GEBR_ID),
  KOS_ITEM_ID uuid references public.KOS_ITEM(KOS_ITEM_ID)
);

create table if not exists public.SPYSKAART (
  SPYSKAART_ID uuid primary key default gen_random_uuid(),
  SPYSKAART_NAAM text not null default '',
  SPYSKAART_IS_TEMPLAAT boolean default false,
  SPYSKAART_DATUM timestamp default now(),
  SPYSKAART_IS_ACTIVE boolean default false,
);

create table if not exists public.WEEK_DAG (
  WEEK_DAG_ID uuid primary key default gen_random_uuid(),
  WEEK_DAG_NAAM text not null default ''
);

create table if not exists public.SPYSKAART_KOS_ITEM (
  SPYSKAART_KOS_ID uuid primary key default gen_random_uuid(),
  SPYSKAART_KOS_AFSNY_DATUM timestamp default now(),
  SPYSKAART_ID uuid references public.SPYSKAART(SPYSKAART_ID),
  KOS_ITEM_ID uuid references public.KOS_ITEM(KOS_ITEM_ID),
  WEEK_DAG_ID uuid references public.WEEK_DAG(WEEK_DAG_ID)
);

-- =======================================
-- RLS POLICIES
-- =======================================

alter table public.GEBRUIKERS enable row level security;
alter table public.MANDJIE enable row level security;
alter table public.BESTELLING enable row level security;
alter table public.BESTELLING_KOS_ITEM enable row level security;
alter table public.BEURSIE_TRANSAKSIE enable row level security;
alter table public.KOS_ITEM enable row level security;
alter table public.SPYSKAART enable row level security;
alter table public.SPYSKAART_KOS_ITEM enable row level security;
alter table public.WEEK_DAG enable row level security;

create policy p_gebr_select_self on public.GEBRUIKERS
  for select using (GEBR_ID = auth.uid());
create policy p_gebr_update_self on public.GEBRUIKERS
  for update using (GEBR_ID = auth.uid());

create policy p_mandjie_self on public.MANDJIE
  for all using (GEBR_ID = auth.uid()) with check (GEBR_ID = auth.uid());

create policy p_best_select_self on public.BESTELLING
  for select using (GEBR_ID = auth.uid());
create policy p_best_insert_self on public.BESTELLING
  for insert with check (GEBR_ID = auth.uid());
create policy p_best_update_self on public.BESTELLING
  for update using (GEBR_ID = auth.uid());

create policy p_best_item_select_self on public.BESTELLING_KOS_ITEM
  for select using (BEST_ID in (select BEST_ID from public.BESTELLING where GEBR_ID = auth.uid()));
create policy p_best_item_insert_self on public.BESTELLING_KOS_ITEM
  for insert with check (BEST_ID in (select BEST_ID from public.BESTELLING where GEBR_ID = auth.uid()));

create policy p_trans_select_self on public.BEURSIE_TRANSAKSIE
  for select using (GEBR_ID = auth.uid());

-- Public read policies for non-sensitive tables
create policy p_public_read_kos_item on public.KOS_ITEM for select using (true);
create policy p_public_read_spyskaart on public.SPYSKAART for select using (true);
create policy p_public_read_spyskaart_kos on public.SPYSKAART_KOS_ITEM for select using (true);
create policy p_public_read_week_dag on public.WEEK_DAG for select using (true);

-- =======================================
-- SEEDS (BASIES)
-- =======================================
insert into public.KAMPUS (KAMPUS_NAAM, KAMPUS_LIGGING) values ('Centurion', 'Gauteng') on conflict do nothing;
insert into public.GEBRUIKER_TIPES (GEBR_TIPE_NAAM) values ('Student'), ('Personeel') on conflict do nothing;
insert into public.KOS_ITEM (KOS_ITEM_NAAM, KOS_ITEM_KOSTE) values ('Boerewors rol', 45.00), ('Veggie wrap', 55.00) on conflict do nothing;
