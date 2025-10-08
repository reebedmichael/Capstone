-- Fix table name case sensitivity issues
-- Run this in Supabase SQL Editor

-- First, let's see what tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- The issue is that tables are created with UPPERCASE names
-- but the app is trying to access them with lowercase names
-- We need to either:
-- 1. Rename tables to lowercase, or
-- 2. Update the app to use uppercase names

-- For now, let's create lowercase aliases for the main tables
-- This is a quick fix without breaking existing data

-- Create views with lowercase names
CREATE OR REPLACE VIEW public.kos_item AS SELECT * FROM public."KOS_ITEM";
CREATE OR REPLACE VIEW public.gebruikers AS SELECT * FROM public."GEBRUIKERS";
CREATE OR REPLACE VIEW public.spyskaart AS SELECT * FROM public."SPYSKAART";
CREATE OR REPLACE VIEW public.spyskaart_kos_item AS SELECT * FROM public."SPYSKAART_KOS_ITEM";
CREATE OR REPLACE VIEW public.mandjie AS SELECT * FROM public."MANDJIE";
CREATE OR REPLACE VIEW public.bestelling AS SELECT * FROM public."BESTELLING";
CREATE OR REPLACE VIEW public.bestelling_kos_item AS SELECT * FROM public."BESTELLING_KOS_ITEM";
CREATE OR REPLACE VIEW public.beursie_transaksie AS SELECT * FROM public."BEURSIE_TRANSAKSIE";
CREATE OR REPLACE VIEW public.week_dag AS SELECT * FROM public."WEEK_DAG";

-- Grant permissions on views
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kos_item TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gebruikers TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.spyskaart TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.spyskaart_kos_item TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mandjie TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bestelling TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bestelling_kos_item TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.beursie_transaksie TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.week_dag TO anon;

-- Test the views
SELECT COUNT(*) as kos_item_count FROM public.kos_item;
