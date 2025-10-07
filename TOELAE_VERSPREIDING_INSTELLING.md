# Toelae Verspreiding Instelling Feature

## Oorsig

Hierdie feature laat admins toe om die dag van die maand te verander waarop maandelikse toelae outomaties versprei word. Die verspreiding gebeur outomaties deur middel van 'n Supabase `pg_cron` skedule.

## Wat is Nuut

### Database Komponente

1. **Nuwe Tabel: `stelsel_instellings`**
   - Stoor stelsel-wye konfigurasie instellings
   - Bevat die `toelae_verspreiding_dag` instelling (standaard: dag 1)
   - RLS enabled met leestoegang vir alle gebruikers en skryftoegang vir admins

2. **Nuwe Funksies:**
   - `get_instelling(p_sleutel TEXT)` - Kry 'n instelling waarde
   - `update_instelling(p_sleutel TEXT, p_waarde TEXT)` - Update 'n instelling (admin only)
   - `update_toelae_cron_schedule(p_dag INTEGER)` - Update die cron skedule en instelling (admin only)

### Admin Web UI

Die Toelae Bestuur bladsy het nou 'n nuwe **Toelae Instellings** kaart bo-aan die bladsy wat:
- Die huidige verspreiding dag wys
- 'n "Verander" knoppie het om die dag te verander
- 'n dialog vertoon met 'n dropdown vir dae 1-28

## Installasie

### Stap 1: Verseker pg_cron is geaktiveer

Jy moet reeds hierdie uitgevoer het (soos jy genoem het):

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'distribute-monthly-allowances',
    '0 0 1 * *',
    $$SELECT distribute_monthly_toelae()$$
);
```

### Stap 2: Pas die Migrasie Toe

Gebruik die skripsie om die migrasie toe te pas:

```bash
cd /Users/michaeldebeer/Projects/capstone
./scripts/apply_toelae_settings.sh
```

Of pas dit direk toe in jou Supabase SQL Editor:

```sql
-- Kopieer die inhoud van db/migrations/0008_add_toelae_settings.sql
```

## Hoe om te Gebruik

### Vir Admins

1. **Open die Admin Web App**
   ```bash
   cd apps/admin_web
   flutter run -d chrome
   ```

2. **Navigeer na Toelae Bestuur**
   - Klik op "Toelae" in die navigasie

3. **Verander die Verspreiding Dag**
   - Kyk na die "Toelae Instellings" kaart bo-aan die bladsy
   - Klik op die "Verander" knoppie
   - Kies 'n dag tussen 1-28 uit die dropdown
   - Klik "Stoor"

4. **Bevestiging**
   - Jy sal 'n groene sukses boodskap sien
   - Die nuwe dag sal dadelik vertoon word
   - Die cron skedule is outomaties opgedateer

### Programaties Gebruik

As jy die instelling programaties wil lees of verander:

```dart
// Kry die InstellingsRepository
final instellingsRepo = sl<InstellingsRepository>();

// Lees die huidige dag
final dag = await instellingsRepo.kryToelaeVerspreidingDag();
print('Toelae word versprei op dag $dag');

// Verander die dag (admin only)
await instellingsRepo.updateToelaeVerspreidingDag(15);
print('Dag verander na 15');
```

## Tegniese Details

### Cron Schedule Formaat

Die funksie gebruik die standaard cron formaat:
```
0 0 <dag> * *
```

Waar:
- Eerste `0` = minute (middernag)
- Tweede `0` = uur (middernag)  
- `<dag>` = dag van die maand (1-28)
- Eerste `*` = elke maand
- Tweede `*` = elke dag van die week

Voorbeeld: `0 0 15 * *` beteken "op dag 15 van elke maand om middernag"

### Waarom 1-28?

Om te verseker die skedule werk vir alle maande (insluitend Februarie), is die maksimum dag beperk tot 28.

### Sekuriteit

- Net gebruikers met 'n `admin_tipe_id` kan die instelling verander
- Die RLS beleid verseker slegs admins kan die tabel opdateer
- Die `update_toelae_cron_schedule` funksie valideer die dag is tussen 1-28

## Toetsing

### Handmatige Toets

1. **Toets die UI:**
   - Open die admin web app
   - Gaan na Toelae Bestuur
   - Verander die dag na bv. 15
   - Herlaai die bladsy en bevestig die dag is steeds 15

2. **Toets die Cron Job:**
   ```sql
   -- Kyk na die cron jobs
   SELECT * FROM cron.job WHERE jobname = 'distribute-monthly-allowances';
   
   -- Jy moet die opgedateerde schedule sien
   -- Bv. "0 0 15 * *" as jy dag 15 gekies het
   ```

3. **Toets die Verspreiding Funksie:**
   ```sql
   -- Roep die funksie handmatig om te toets
   SELECT distribute_monthly_toelae();
   
   -- Dit sal onmiddellik toelae versprei (nuttig vir toetsing)
   ```

### Verwagde Uitset

Na suksesvolle toepassing:
- Die `stelsel_instellings` tabel bestaan met die `toelae_verspreiding_dag` record
- Die admin UI wys die huidige dag
- Wanneer jy die dag verander, word die cron job outomaties opgedateer
- Toelae word versprei op die gekose dag van elke maand

## Probleemoplossing

### Fout: "Only admins can update system settings"

- Verseker jou gebruiker het 'n `admin_tipe_id` wat nie NULL is nie
- Kontroleer in die `gebruikers` tabel

### Fout: "relation stelsel_instellings does not exist"

- Die migrasie is nie toegepas nie
- Hardloop `./scripts/apply_toelae_settings.sh`

### Cron Job Werk Nie

- Kontroleer of `pg_cron` extension geaktiveer is
- Kyk na cron logs:
  ```sql
  SELECT * FROM cron.job_run_details 
  WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'distribute-monthly-allowances')
  ORDER BY start_time DESC 
  LIMIT 10;
  ```

## Lêer Veranderinge

### Nuwe Lêers
- `db/migrations/0008_add_toelae_settings.sql` - Database migrasie
- `packages/spys_api_client/lib/src/instellings_repository.dart` - Repository vir instellings
- `scripts/apply_toelae_settings.sh` - Skripsie om migrasie toe te pas
- `TOELAE_VERSPREIDING_INSTELLING.md` - Hierdie dokumentasie

### Aangepaste Lêers
- `apps/admin_web/lib/features/toelae/presentation/toelae_bestuur_page.dart` - UI bygevoeg
- `apps/admin_web/lib/locator.dart` - InstellingsRepository geregistreer
- `packages/spys_api_client/lib/spys_api_client.dart` - InstellingsRepository ge-export

## Toekomstige Uitbreidings

Moontlike verbeteringe:
1. E-pos kennisgewing aan admins voor verspreiding
2. Geskiedenis van wanneer die dag verander is
3. Ondersteuning vir verskillende skedulesse vir verskillende gebruiker tipes
4. Dashboard met volgende verspreiding datum

## Ondersteuning

As jy enige probleme ondervind, kontroleer:
1. Supabase logs vir foute
2. Browser console vir foutboodskappe
3. Die `cron.job_run_details` tabel vir cron uitvoering foute

