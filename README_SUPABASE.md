# Supabase Setup (Afrikaanse Skema)

## Env (.env.*) – gebruik presies hierdie waardes
Plaas in elk van die volgende lêers (oor skryf indien reeds bestaan):

- apps/mobile/.env.dev
- apps/mobile/.env.prod
- apps/admin_web/.env.dev
- apps/admin_web/.env.prod

Inhoud in elkeen:

```
SUPABASE_URL=https://fdtjqpkrgstoobgkmvva.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdGpxcGtyZ3N0b29iZ2ttdnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MzkzMTksImV4cCI6MjA2NjUxNTMxOX0.mBhXEydwMYWxwUhrLR2ugVRbYFi0g1hRi3S3hzZhv-g
```

Maak seker `.env.*` is in .gitignore.

## Migrasies

Opsie A – Supabase SQL Editor:
1) Run `db/migrations/0000_drop_public.sql`
2) Run `db/migrations/0001_init_spys.sql`

Opsie B – CLI:
```
export SUPABASE_DB_URL='postgresql://USER:PASSWORD@HOST:PORT/DB?sslmode=require'
chmod +x scripts/db_apply.sh
melos run db:apply
```

## DB Test Page

- Mobile: route `/db-test` (button in Home header). Lêer: `apps/mobile/lib/pages/db_test_page.dart`
- Admin web: route `/db-test` (buttons op Dashboard). Lêer: `apps/admin_web/lib/pages/db_test_page.dart`

Wat dit doen:
- Lees `KOS_ITEM` (eerste 5) en wys as teks
- Indien ingelog en `GEBRUIKERS` ry met selfde `auth.uid()` bestaan, wys dit ook
- FAB herlaai lys

## Melos take
```
melos bootstrap
melos run build
melos run analyze   # of: melos run analyze:apps
melos run test      # toets slegs spys_api_client
```

## Bekende foute
- 401 (RLS): Voeg ’n ry in `GEBRUIKERS` vir jou `auth.uid()`:
```
insert into public.GEBRUIKERS (GEBR_ID, GEBR_EPOS, IS_AKTIEF)
values ('<AUTH_UID>', 'you@example.com', true)
on conflict do nothing;
```
- Indien `flutter analyze` faal oor warnings in apps, gebruik `melos run analyze:apps` vir nie‑fatal warnings. 