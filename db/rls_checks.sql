-- RLS Quality Gate Checks
select count(*) from public.kos_item;
select * from pg_policies where schemaname='public' order by tablename, policyname;

-- Create/ensure a user row for current auth.uid()
insert into public.gebruikers (gebr_id, gebr_epos, is_aktief)
values (auth.uid(), 'test@example.com', true)
on conflict (gebr_id) do update set is_aktief = excluded.is_aktief; 