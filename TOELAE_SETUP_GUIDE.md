# Toelae Stelsel - Opset Gids

## Vinnige Begin

### Stap 1: Stel Maandelikse Toelaes
1. Gaan na **Toelae** in die sidebar
2. Klik op **Gebruiker Tipes** tab
3. Gebruik die vinnige knoppies:
   - **"Stel Student → R1000"** - Stel studente se toelae op R1000
   - **"Stel Personeel → R15000"** - Stel personeel se toelae op R15000
4. Of klik op die **Wysig** knoppie vir enige tipe om 'n custom bedrag in te voer

### Stap 2: Distribueer Toelaes
1. Druk die groot groen knoppie: **"Distribueer Maandelikse Toelaes"**
2. Bevestig die aksie
3. Die stelsel sal:
   - Loop deur alle aktiewe gebruikers
   - Voeg die toelae bedrag by volgens hulle gebruiker tipe
   - Log elke transaksie in `beursie_transaksie`

### Stap 3: Individuele Aanpassings
1. Gaan na **Individueel** tab
2. Kies 'n gebruiker
3. Voeg by of trek af indien nodig

## Outomatiese Maandelikse Distribusie

### Opsie 1: Supabase Cron Job (Aanbeveel)

Gaan na Supabase Dashboard → Database → Extensions → pg_cron

Voeg hierdie toe:

```sql
-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule monthly allowance distribution (1st of every month at 00:00)
SELECT cron.schedule(
    'distribute-monthly-allowances',
    '0 0 1 * *', -- At 00:00 on day 1 of every month
    $$SELECT distribute_monthly_toelae()$$
);

-- View scheduled jobs
SELECT * FROM cron.job;
```

### Opsie 2: Supabase Edge Function

Skep 'n Edge Function wat elke maand loop:

```typescript
// supabase/functions/distribute-monthly-allowances/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data, error } = await supabase.rpc('distribute_monthly_toelae')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

Stel 'n cron job in GitHub Actions of Vercel Cron om dit elke maand te roep.

### Opsie 3: Manuele Distribusie

As jy nie outomatiese distribusie nodig het nie, druk net die knoppie elke maand!

## Probleemoplossing

### "0 gebruikers gekrediteer met R0.00"

**Oorsaak:** Geen gebruikers het toelaes gestel nie.

**Oplossing:**
1. Gaan na **Gebruiker Tipes** tab
2. Stel toelaes vir elke tipe:
   - Klik **"Stel Student → R1000"**
   - Klik **"Stel Personeel → R15000"**
   - Of gebruik die **Wysig** knoppie

3. Probeer weer:
   - Druk **"Distribueer Maandelikse Toelaes"**
   - Jy sal sien: "X gebruikers gekrediteer met RY.YY"

### Hoe om te verifieer

1. **Check gebruiker_tipes tabel:**
```sql
SELECT gebr_tipe_naam, gebr_toelaag 
FROM gebruiker_tipes;
```

2. **Check aktiewe gebruikers:**
```sql
SELECT g.gebr_naam, g.gebr_van, gt.gebr_tipe_naam, gt.gebr_toelaag, g.beursie_balans
FROM gebruikers g
JOIN gebruiker_tipes gt ON g.gebr_tipe_id = gt.gebr_tipe_id
WHERE g.is_aktief = TRUE;
```

3. **Check transaksies:**
```sql
SELECT bt.*, g.gebr_naam, tt.trans_tipe_naam
FROM beursie_transaksie bt
JOIN gebruikers g ON bt.gebr_id = g.gebr_id
JOIN transaksie_tipe tt ON bt.trans_tipe_id = tt.trans_tipe_id
WHERE tt.trans_tipe_naam = 'toelae_inbetaling'
ORDER BY bt.trans_geskep_datum DESC;
```

## Toelae Vloei

```
1. Admin stel gebr_toelaag per gebruiker_tipe
   └→ Student: R1000
   └→ Personeel: R15000

2. Admin druk "Distribueer Maandelikse Toelaes"
   └→ Loop deur alle aktiewe gebruikers
   └→ Kry hulle gebruiker_tipe se gebr_toelaag
   └→ Voeg by aan gebruiker se beursie_balans
   └→ Log transaksie met trans_tipe = 'toelae_inbetaling'

3. Gebruiker sien balans in Wallet
   └→ Een totale balans (toelae + self-gelaaide)
   └→ Kan filter transaksies per tipe

4. Gebruiker gebruik balans vir bestellings
   └→ Geen verskil tussen toelae en wallet nie
   └→ Een balans veld
```

## Best Practices

1. **Stel toelaes vroeg in die maand** - Begin van maand
2. **Verifieer gebruiker tipes** - Maak seker alle tipes het korrekte bedrae
3. **Monitor transaksies** - Check dat distribusie suksesvol was
4. **Individuele aanpassings** - Gebruik slegs vir uitsonderings
5. **Outomatiese distribusie** - Stel 'n cron job op vir konsekwentheid

## Belangrike Notes

⚠️ **Geen aparte toelae_balans** - Alles is een `beursie_balans`  
⚠️ **Trans_tipe onderskei** - `toelae_inbetaling` vs `inbetaling`  
⚠️ **Aktiewe gebruikers slegs** - Slegs `is_aktief = TRUE` ontvang toelaes  
⚠️ **NULL toelaes** - Gebruiker tipes met `gebr_toelaag = NULL` word oorgeslaan  

