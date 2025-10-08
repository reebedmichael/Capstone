-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admin_tipes (
  admin_tipe_id uuid NOT NULL DEFAULT gen_random_uuid(),
  admin_tipe_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT admin_tipes_pkey PRIMARY KEY (admin_tipe_id)
);
CREATE TABLE public.best_kos_item_statusse (
  best_kos_stat_id uuid NOT NULL DEFAULT gen_random_uuid(),
  best_kos_wysig_datum timestamp without time zone DEFAULT now(),
  best_kos_id uuid,
  kos_stat_id uuid,
  CONSTRAINT best_kos_item_statusse_pkey PRIMARY KEY (best_kos_stat_id),
  CONSTRAINT best_kos_item_statusse_best_kos_id_fkey FOREIGN KEY (best_kos_id) REFERENCES public.bestelling_kos_item(best_kos_id),
  CONSTRAINT best_kos_item_statusse_kos_stat_id_fkey FOREIGN KEY (kos_stat_id) REFERENCES public.kos_item_statusse(kos_stat_id)
);
CREATE TABLE public.bestelling (
  best_id uuid NOT NULL DEFAULT gen_random_uuid(),
  best_geskep_datum timestamp without time zone DEFAULT now(),
  best_volledige_prys double precision,
  gebr_id uuid,
  kampus_id uuid,
  CONSTRAINT bestelling_pkey PRIMARY KEY (best_id),
  CONSTRAINT bestelling_gebr_id_fkey FOREIGN KEY (gebr_id) REFERENCES public.gebruikers(gebr_id),
  CONSTRAINT bestelling_kampus_id_fkey FOREIGN KEY (kampus_id) REFERENCES public.kampus(kampus_id)
);
CREATE TABLE public.bestelling_kos_item (
  best_kos_id uuid NOT NULL DEFAULT gen_random_uuid(),
  best_id uuid,
  kos_item_id uuid,
  item_hoev integer DEFAULT 0,
  best_datum timestamp without time zone DEFAULT now(),
  best_kos_is_liked boolean DEFAULT false,
  CONSTRAINT bestelling_kos_item_pkey PRIMARY KEY (best_kos_id),
  CONSTRAINT bestelling_kos_item_best_id_fkey FOREIGN KEY (best_id) REFERENCES public.bestelling(best_id),
  CONSTRAINT bestelling_kos_item_kos_item_id_fkey FOREIGN KEY (kos_item_id) REFERENCES public.kos_item(kos_item_id)
);
CREATE TABLE public.bestelling_kos_item_terugvoer (
  best_terug_id uuid NOT NULL DEFAULT gen_random_uuid(),
  geskep_datum timestamp without time zone DEFAULT now(),
  terug_id uuid,
  best_kos_id uuid,
  CONSTRAINT bestelling_kos_item_terugvoer_pkey PRIMARY KEY (best_terug_id),
  CONSTRAINT bestelling_kos_item_terugvoer_best_kos_id_fkey FOREIGN KEY (best_kos_id) REFERENCES public.bestelling_kos_item(best_kos_id),
  CONSTRAINT bestelling_terugvoer_terug_id_fkey FOREIGN KEY (terug_id) REFERENCES public.terugvoer(terug_id)
);
CREATE TABLE public.beursie_transaksie (
  trans_id uuid NOT NULL DEFAULT gen_random_uuid(),
  trans_geskep_datum timestamp without time zone DEFAULT now(),
  trans_bedrag double precision,
  trans_beskrywing text DEFAULT ''::text,
  gebr_id uuid,
  trans_tipe_id uuid,
  CONSTRAINT beursie_transaksie_pkey PRIMARY KEY (trans_id),
  CONSTRAINT beursie_transaksie_gebr_id_fkey FOREIGN KEY (gebr_id) REFERENCES public.gebruikers(gebr_id),
  CONSTRAINT beursie_transaksie_trans_tipe_id_fkey FOREIGN KEY (trans_tipe_id) REFERENCES public.transaksie_tipe(trans_tipe_id)
);
CREATE TABLE public.dieet_vereiste (
  dieet_id uuid NOT NULL DEFAULT gen_random_uuid(),
  dieet_naam text NOT NULL DEFAULT ''::text,
  dieet_beskrywing text DEFAULT ''::text,
  CONSTRAINT dieet_vereiste_pkey PRIMARY KEY (dieet_id)
);
CREATE TABLE public.gebruiker_dieet_vereistes (
  gebr_dieet_id uuid NOT NULL DEFAULT gen_random_uuid(),
  gebr_id uuid,
  dieet_id uuid,
  CONSTRAINT gebruiker_dieet_vereistes_pkey PRIMARY KEY (gebr_dieet_id),
  CONSTRAINT gebruiker_dieet_vereistes_gebr_id_fkey FOREIGN KEY (gebr_id) REFERENCES public.gebruikers(gebr_id),
  CONSTRAINT gebruiker_dieet_vereistes_dieet_id_fkey FOREIGN KEY (dieet_id) REFERENCES public.dieet_vereiste(dieet_id)
);
CREATE TABLE public.gebruiker_tipes (
  gebr_tipe_id uuid NOT NULL DEFAULT gen_random_uuid(),
  gebr_tipe_naam text NOT NULL DEFAULT ''::text,
  gebr_tipe_beskrywing text DEFAULT ''::text,
  gebr_toelaag double precision,
  CONSTRAINT gebruiker_tipes_pkey PRIMARY KEY (gebr_tipe_id)
);
CREATE TABLE public.gebruikers (
  gebr_id uuid NOT NULL DEFAULT gen_random_uuid(),
  gebr_geskep_datum timestamp without time zone DEFAULT now(),
  gebr_epos text DEFAULT ''::text,
  gebr_naam text DEFAULT ''::text,
  gebr_van text DEFAULT ''::text,
  beursie_balans double precision DEFAULT '0'::double precision,
  is_aktief boolean DEFAULT true,
  gebr_tipe_id uuid,
  admin_tipe_id uuid,
  kampus_id uuid,
  gebr_selfoon text,
  gebr_tipe character varying DEFAULT 'Gewoon'::character varying,
  gebr_geslag character varying,
  gebr_telefoon character varying,
  CONSTRAINT gebruikers_pkey PRIMARY KEY (gebr_id),
  CONSTRAINT gebruikers_gebr_tipe_id_fkey FOREIGN KEY (gebr_tipe_id) REFERENCES public.gebruiker_tipes(gebr_tipe_id),
  CONSTRAINT gebruikers_admin_tipe_id_fkey FOREIGN KEY (admin_tipe_id) REFERENCES public.admin_tipes(admin_tipe_id),
  CONSTRAINT gebruikers_kampus_id_fkey FOREIGN KEY (kampus_id) REFERENCES public.kampus(kampus_id)
);
CREATE TABLE public.globale_kennisgewings (
  glob_kennis_id uuid NOT NULL DEFAULT gen_random_uuid(),
  glob_kennis_beskrywing text DEFAULT ''::text,
  glob_kennis_geskep_datum timestamp without time zone DEFAULT now(),
  kennis_tipe_id uuid,
  CONSTRAINT globale_kennisgewings_pkey PRIMARY KEY (glob_kennis_id),
  CONSTRAINT globale_kennisgewings_kennis_tipe_id_fkey FOREIGN KEY (kennis_tipe_id) REFERENCES public.kennisgewing_tipes(kennis_tipe_id)
);
CREATE TABLE public.kampus (
  kampus_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kampus_naam text NOT NULL DEFAULT ''::text,
  kampus_ligging text DEFAULT ''::text,
  CONSTRAINT kampus_pkey PRIMARY KEY (kampus_id)
);
CREATE TABLE public.kennisgewing_tipes (
  kennis_tipe_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kennis_tipe_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT kennisgewing_tipes_pkey PRIMARY KEY (kennis_tipe_id)
);
CREATE TABLE public.kennisgewings (
  kennis_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kennis_beskrywing text DEFAULT ''::text,
  kennis_gelees boolean DEFAULT false,
  kennis_geskep_datum timestamp without time zone DEFAULT now(),
  gebr_id uuid,
  kennis_tipe_id uuid,
  CONSTRAINT kennisgewings_pkey PRIMARY KEY (kennis_id),
  CONSTRAINT kennisgewings_gebr_id_fkey FOREIGN KEY (gebr_id) REFERENCES public.gebruikers(gebr_id),
  CONSTRAINT kennisgewings_kennis_tipe_id_fkey FOREIGN KEY (kennis_tipe_id) REFERENCES public.kennisgewing_tipes(kennis_tipe_id)
);
CREATE TABLE public.kos_item (
  kos_item_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kos_item_naam text NOT NULL DEFAULT ''::text,
  kos_item_beskrywing text DEFAULT ''::text,
  kos_item_koste double precision,
  kos_item_prentjie text,
  is_aktief boolean DEFAULT true,
  kos_item_is_templaat boolean DEFAULT true,
  kos_item_geskep_datum timestamp without time zone DEFAULT now(),
  kos_item_bestandele ARRAY,
  kos_item_kategorie text,
  kos_item_allergene ARRAY,
  kos_item_likes integer DEFAULT 0,
  CONSTRAINT kos_item_pkey PRIMARY KEY (kos_item_id)
);
CREATE TABLE public.kos_item_dieet_vereistes (
  kos_item_dieet_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kos_item_id uuid,
  dieet_id uuid,
  CONSTRAINT kos_item_dieet_vereistes_pkey PRIMARY KEY (kos_item_dieet_id),
  CONSTRAINT kos_item_dieet_vereistes_kos_item_id_fkey FOREIGN KEY (kos_item_id) REFERENCES public.kos_item(kos_item_id),
  CONSTRAINT kos_item_dieet_vereistes_dieet_id_fkey FOREIGN KEY (dieet_id) REFERENCES public.dieet_vereiste(dieet_id)
);
CREATE TABLE public.kos_item_statusse (
  kos_stat_id uuid NOT NULL DEFAULT gen_random_uuid(),
  kos_stat_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT kos_item_statusse_pkey PRIMARY KEY (kos_stat_id)
);
CREATE TABLE public.log_tipe (
  log_tipe_id uuid NOT NULL DEFAULT gen_random_uuid(),
  log_tipe_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT log_tipe_pkey PRIMARY KEY (log_tipe_id)
);
CREATE TABLE public.logboek (
  log_id uuid NOT NULL DEFAULT gen_random_uuid(),
  log_beskrywing text DEFAULT ''::text,
  log_datum_geskep timestamp without time zone DEFAULT now(),
  log_tipe_id uuid,
  CONSTRAINT logboek_pkey PRIMARY KEY (log_id),
  CONSTRAINT logboek_log_tipe_id_fkey FOREIGN KEY (log_tipe_id) REFERENCES public.log_tipe(log_tipe_id)
);
CREATE TABLE public.mandjie (
  mand_id uuid NOT NULL DEFAULT gen_random_uuid(),
  gebr_id uuid,
  kos_item_id uuid,
  qty integer DEFAULT 1,
  created_at timestamp without time zone DEFAULT now(),
  week_dag_naam text,
  CONSTRAINT mandjie_pkey PRIMARY KEY (mand_id),
  CONSTRAINT mandjie_gebr_id_fkey FOREIGN KEY (gebr_id) REFERENCES public.gebruikers(gebr_id),
  CONSTRAINT mandjie_kos_item_id_fkey FOREIGN KEY (kos_item_id) REFERENCES public.kos_item(kos_item_id)
);
CREATE TABLE public.spyskaart (
  spyskaart_id uuid NOT NULL DEFAULT gen_random_uuid(),
  spyskaart_naam text NOT NULL DEFAULT ''::text,
  spyskaart_is_templaat boolean DEFAULT false,
  spyskaart_datum timestamp without time zone DEFAULT now(),
  spyskaart_is_active boolean DEFAULT false,
  spyskaart_beskrywing text,
  CONSTRAINT spyskaart_pkey PRIMARY KEY (spyskaart_id)
);
CREATE TABLE public.spyskaart_kos_item (
  spyskaart_kos_id uuid NOT NULL DEFAULT gen_random_uuid(),
  spyskaart_kos_afsny_datum timestamp without time zone DEFAULT now(),
  spyskaart_id uuid,
  kos_item_id uuid,
  week_dag_id uuid,
  kos_item_hoeveelheid bigint NOT NULL DEFAULT '0'::bigint,
  CONSTRAINT spyskaart_kos_item_pkey PRIMARY KEY (spyskaart_kos_id),
  CONSTRAINT spyskaart_kos_item_spyskaart_id_fkey FOREIGN KEY (spyskaart_id) REFERENCES public.spyskaart(spyskaart_id),
  CONSTRAINT spyskaart_kos_item_kos_item_id_fkey FOREIGN KEY (kos_item_id) REFERENCES public.kos_item(kos_item_id),
  CONSTRAINT spyskaart_kos_item_week_dag_id_fkey FOREIGN KEY (week_dag_id) REFERENCES public.week_dag(week_dag_id)
);
CREATE TABLE public.terugvoer (
  terug_id uuid NOT NULL DEFAULT gen_random_uuid(),
  terug_naam text NOT NULL DEFAULT ''::text,
  terug_beskrywing text DEFAULT ''::text,
  CONSTRAINT terugvoer_pkey PRIMARY KEY (terug_id)
);
CREATE TABLE public.transaksie_tipe (
  trans_tipe_id uuid NOT NULL DEFAULT gen_random_uuid(),
  trans_tipe_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT transaksie_tipe_pkey PRIMARY KEY (trans_tipe_id)
);
CREATE TABLE public.week_dag (
  week_dag_id uuid NOT NULL DEFAULT gen_random_uuid(),
  week_dag_naam text NOT NULL DEFAULT ''::text,
  CONSTRAINT week_dag_pkey PRIMARY KEY (week_dag_id)
);