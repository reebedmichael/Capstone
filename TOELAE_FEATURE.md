# Toelae (Allowance) Bestuurstelsel

## Oorsig

Die toelae stelsel laat admins toe om geld by te voeg aan gebruikers se beursie balans. Die verskil tussen toelae en gewone beursie betalings word bepaal deur die **transaksie tipe**, nie 'n aparte balans veld nie.

### Belangrike Konsep
- **Beursie Balans** (`beursie_balans`) = Een enkele balans vir beide toelae en self-gelaaide fondse
- **Transaksie Tipes** onderskei die tipe inbetaling:
  - `toelae_inbetaling` = Toegevoeg deur admin (toelae)
  - `inbetaling` = Self gelaai deur gebruiker
  - `toelae_uitbetaling` = Gebruik in bestelling (maar gewone `uitbetaling` word ook gebruik)

## Database Struktuur

### Nuwe Tabel: `toelae_transaksie`

```sql
CREATE TABLE toelae_transaksie (
    toelae_trans_id UUID PRIMARY KEY,
    gebr_id UUID REFERENCES gebruikers(gebr_id),
    trans_bedrag DECIMAL(10, 2),
    trans_tipe_id UUID REFERENCES transaksie_tipe(trans_tipe_id),
    trans_beskrywing TEXT,
    geskep_deur UUID REFERENCES gebruikers(gebr_id), -- Admin wat die toelae bygevoeg het
    trans_geskep_datum TIMESTAMPTZ DEFAULT NOW()
);
```

### Gebruik Bestaande Veld
- `gebruikers.beursie_balans` - Geen aparte toelae_balans veld nie!

### Nuwe Funksies

1. **`add_allowance(p_gebr_id, p_bedrag, p_beskrywing)`**
   - Slegs admins kan gebruik
   - Voeg geld by aan gebruiker se beursie_balans
   - Log transaksie in `toelae_transaksie` tabel

2. **`deduct_allowance(p_gebr_id, p_bedrag, p_beskrywing)`**
   - Gebruik vir aftrekkel (indien nodig)
   - Trek af van beursie_balans
   - Log transaksie in `toelae_transaksie` tabel

### View: `vw_toelae_transaksies`
- Volle transaksie geskiedenis met gebruiker en admin name
- Kombineer toelae_transaksie met gebruikers en transaksie_tipe

## Implementasie

### 1. spys_core (Domain Models)

**Nuwe Model:** `ToelaeTransaksie`
```dart
class ToelaeTransaksie {
  final String toelaeTransId;
  final String gebrId;
  final double transBedrag;
  final String transTipeId;
  final String? transBeskrywing;
  final String? geskreDeur;
  final String transGeskepDatum;
}
```

**Geen verandering aan `Gebruiker`** - gebruik steeds `beursieBalans`

### 2. spys_api_client (API Laag)

**Nuwe Repository:** `ToelaeRepository`

Metodes:
- `kryToelaeBalans(gebrId)` - Kry beursie_balans (selfde as wallet)
- `voegToelaeBy(gebrId, bedrag, beskrywing)` - Voeg toelae by
- `trekToelaeAf(gebrId, bedrag, beskrywing)` - Trek toelae af
- `lysToelaeTransaksies(gebrId)` - Kry toelae geskiedenis
- `lysAlleToelaeTransaksies()` - Kry alle toelae transaksies (admin)
- `hetVoldoendeToelae(gebrId, bedrag)` - Check of voldoende balans
- `kryGebruikersMetLaeToelae(drempel)` - Kry gebruikers met lae balans

### 3. Admin Web

**Nuwe Page:** `ToelaeBestuurPage` (`/toelae`)

Features:
- Voeg toelae by aan gebruikers
- Trek toelae af van gebruikers
- Filter gebruikers met lae balans
- Soek gebruikers
- Bekyk transaksie geskiedenis
- Wys alle toelae transaksies met admin wat dit bygevoeg het

Navigasie:
- Bygevoeg in sidebar onder "Gebruikers"
- Route: `/toelae`
- Auth guard vir admins

### 4. Mobile App

**Wallet Page Updates:**

Tabs:
1. **Laai Beursie** - Self laai met kaart/SnapScan/EFT
2. **Betalings** - Beursie transaksies (self gelaai)
3. **Toelae Geskiedenis** - Toelae transaksies (admin bygevoeg)

Display:
- Een balans veld (beursie_balans)
- Toelae transaksies wys in aparte tab met oranje kleur
- Transaksie tipe onderskei die bron

**Cart Page:**
- Geen verandering aan checkout logika nie
- Gebruik steeds beursie_balans
- Toelae en wallet is dieselfde balans

## Gebruik

### Admin Perspektief

1. Navigeer na **Toelae** in sidebar
2. Kies gebruiker uit lys
3. Kies "Voeg By" of "Trek Af"
4. Voer bedrag in
5. Voeg beskrywing by (opsioneel)
6. Druk "Voeg Toelae By" / "Trek Toelae Af"

### Gebruiker Perspektief

1. Gaan na **Wallet** tab
2. Sien totale balans (toelae + self-gelaaide geld)
3. Gaan na **Toelae Geskiedenis** tab om admin inbetalings te sien
4. Gebruik balans vir bestellings (geen verskil in gebruik nie)

## Transaksie Vloei

### Admin Voeg Toelae By
```
1. Admin kies gebruiker
2. Admin voer bedrag in (bv. R100)
3. Roep add_allowance() funksie
4. beursie_balans += R100
5. toelae_transaksie row geskep (trans_tipe = 'toelae_inbetaling')
6. Gebruiker sien R100 meer in wallet
```

### Gebruiker Gebruik Balans
```
1. Gebruiker plaas bestelling vir R50
2. Checkout check beursie_balans >= R50 ✓
3. beursie_balans -= R50
4. beursie_transaksie row geskep (trans_tipe = 'uitbetaling')
5. Beide toelae en self-gelaaide geld word gebruik (geen verskil)
```

## Voordele van Hierdie Benadering

✅ **Een enkele balans** - Makliker vir gebruikers om te verstaan
✅ **Transaksie histories** - Admins kan steeds sien watter toelae bygevoeg is
✅ **Geen kompleksiteit** - Geen logika om toelae eerste te gebruik nie
✅ **Bestaande kode hergebruik** - Checkout logika bly dieselfde
✅ **Duidelike audit trail** - `toelae_transaksie` tabel hou rekord van admin bydraes

## Migrasie Toepassing

### Opsie 1: Supabase SQL Editor (Aanbeveel)
1. Gaan na [Supabase Dashboard](https://supabase.com/dashboard)
2. Klik op jou projek
3. Gaan na "SQL Editor"
4. Maak nuwe query oop
5. Kopeer inhoud van `db/migrations/0006_add_allowance_system.sql`
6. Run die SQL

### Opsie 2: Supabase CLI
```bash
cd /Users/michaeldebeerhome/Capstone/Capstone
supabase db push
```

### Opsie 3: Helper Script
```bash
./scripts/apply_allowance_migration.sh
```

## Testing

### Test Admin Toelae Funksionaliteit
1. Teken in as admin
2. Gaan na Toelae bladsy
3. Kies 'n gebruiker
4. Voeg R100 toelae by
5. Verifieer dat gebruiker se balans verhoog het
6. Check transaksie geskiedenis

### Test Mobile Gebruiker Ervaring
1. Teken in as gebruiker
2. Gaan na Wallet
3. Sien toelae in "Toelae Geskiedenis" tab
4. Plaas bestelling
5. Verifieer balans verminder

## Toekoms Uitbreidings

- Bulk toelae byvoeg vir baie gebruikers
- Toelae limite per gebruiker tipe
- Outomatiese maandelikse toelae
- Toelae vervaldatum
- Rapporte oor toelae gebruik

## Belangrike Notes

⚠️ **Balans is EEN veld** - `beursie_balans` bevat beide toelae en self-gelaaide geld
⚠️ **Transaksie tipe** is hoe ons onderskei tussen bronne
⚠️ **Admin slegs** - Slegs admins kan toelae byvoeg/aftrek
⚠️ **Audit trail** - Alle toelae transaksies hou rekord van watter admin dit gedoen het

