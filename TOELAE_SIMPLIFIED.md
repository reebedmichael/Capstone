# Toelae (Allowance) Stelsel - Vereenvoudig

## Hoe Dit Werk

### 1. **Groep-gebaseerde Toelaes**
- Gebruik die bestaande `gebruiker_tipes` tabel
- Die `gebr_toelaag` veld bevat die maandelikse toelae bedrag vir elke groep
- Byvoorbeeld:
  - Studente: R1,000 per maand
  - Personeel: R15,000 per maand

### 2. **Een Balans Veld**
- `gebruikers.beursie_balans` = Totale beskikbare balans
- Geen aparte toelae_balans veld nie
- Toelae en self-gelaaide geld word saam gestoor

### 3. **Transaksie Tipes**
Die `beursie_transaksie` tabel gebruik verskillende `trans_tipe_id` waardes:
- `toelae_inbetaling` (a1e58a24-1a1d-4940-8855-df4c35ae5d5f) = Admin voeg toelae by
- `toelae_uitbetaling` (a2e58a24-1a1d-4940-8855-df4c35ae5d5f) = Toelae gebruik
- `inbetaling` = Self gelaai deur gebruiker
- `uitbetaling` = Gebruik in bestelling

## Database Struktuur

### Gebruik Bestaande Tabelle:
- `gebruiker_tipes.gebr_toelaag` - Maandelikse toelae vir groep
- `gebruikers.beursie_balans` - Totale balans (toelae + self-gelaaide)
- `beursie_transaksie` - Alle transaksies (toelae EN wallet)
- `transaksie_tipe` - Onderskei transaksie tipes

### Nuwe Funksies:
1. **`add_toelae(p_gebr_id, p_bedrag, p_beskrywing)`**
   - Admin voeg toelae by vir spesifieke gebruiker
   - Voeg by aan `beursie_balans`
   - Log in `beursie_transaksie` met `toelae_inbetaling` tipe

2. **`deduct_toelae(p_gebr_id, p_bedrag, p_beskrywing)`**
   - Trek toelae af (indien nodig)
   - Trek af van `beursie_balans`
   - Log in `beursie_transaksie` met `toelae_uitbetaling` tipe

3. **`distribute_monthly_toelae()`**
   - Distribueer maandelikse toelaes outomaties
   - Loop deur alle aktiewe gebruikers
   - Voeg `gebr_toelaag` by volgens hulle `gebruiker_tipe`
   - Skep transaksies vir elkeen

## Admin Funksionaliteit

### 1. Stel Groep Toelaes
- Navigeer na Gebruiker Tipes
- Stel `gebr_toelaag` vir elke tipe:
  - Student: R1000
  - Personeel: R15000
  - etc.

### 2. Individuele Toelae Bestuur
- Gaan na "Toelae" bladsy
- Kies 'n gebruiker
- Voeg by of trek af
- Bekyk geskiedenis (filter op `toelae_inbetaling` en `toelae_uitbetaling`)

### 3. Maandelikse Distribusie
- Druk "Distribueer Maandelikse Toelaes" knoppie
- Stelstel gee outomaties vir alle gebruikers volgens hulle groep

## Mobile Gebruiker Ervaring

### Wallet Display:
- Wys totale balans (`beursie_balans`)
- Geen aparte toelae balans nie
- Tabs:
  1. **Laai Beursie** - Self laai met kaart/EFT
  2. **Transaksies** - Alle transaksies (wallet EN toelae saam)
  3. Filter: Toon slegs toelae transaksies indien nodig

### Checkout:
- Gebruik totale balans
- Geen verskil tussen toelae en self-gelaaide geld nie
- Transaksie word gerekord met `uitbetaling` tipe

## Implementasie

### Stappe:
1. **Pas migrasie toe** in Supabase SQL Editor:
   - Gaan na: https://supabase.com/dashboard/project/fdtjqpkrgstoobgkmvva/sql/new
   - Kopieer en run: `db/migrations/0006_add_toelae_transaction_types.sql`

2. **Stel gebruiker_tipes toelaes**:
   - UPDATE gebruiker_tipes SET gebr_toelaag = 1000 WHERE gebr_tipe_naam = 'Student';
   - UPDATE gebruiker_tipes SET gebr_toelaag = 15000 WHERE gebr_tipe_naam = 'Personeel';

3. **Admin kan gebruik**:
   - Individueel byvoeg/aftrek via Admin Web
   - Maandelikse distribusie met een knoppie

4. **Gebruikers sien**:
   - Totale balans in Wallet
   - Transaksie geskiedenis (kan filter op toelae)

## Voordele

✅ **Eenvoudig** - Gebruik bestaande tabelle  
✅ **Groep-gebaseer** - Stel een keer per tipe  
✅ **Outomaties** - Maandelikse distribusie funksie  
✅ **Flexibel** - Admin kan steeds individueel byvoeg  
✅ **Geen duplika

sie** - Een balans veld, onderskei met trans_tipe  
✅ **Maklike geskiedenis** - Alles in `beursie_transaksie`  

## Toekoms

- Cron job vir outomatiese maandelikse distribusie
- Email notifikasies wanneer toelae ontvang
- Rapporte oor toelae gebruik
- Limiet hoeveel toelae gebruikers kan spaar

