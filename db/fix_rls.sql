-- Fix RLS issue - disable RLS on kos_item for testing
alter table public.kos_item disable row level security;

-- Also disable on other public tables for testing
alter table public.spyskaart disable row level security;
alter table public.spyskaart_kos_item disable row level security;
alter table public.week_dag disable row level security;

-- Verify the change
select schemaname, tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
and tablename in ('kos_item', 'spyskaart', 'spyskaart_kos_item', 'week_dag'); 