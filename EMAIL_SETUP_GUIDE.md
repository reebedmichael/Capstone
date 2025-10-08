# E-pos Opstelling Gids vir Spys

## Oorsig
Hierdie gids sal jou help om e-pos funksionaliteit op te stel sodat gebruikers e-pos ontvang wanneer hul bestelling status opdateer.

## Stap 1: Registreer by Resend (Gratis)

1. Gaan na https://resend.com
2. Klik op "Sign Up" 
3. Registreer met jou Gmail adres
4. Verifieer jou e-pos adres
5. **Gratis tier:** 100 emails per dag, 3,000 per maand

## Stap 2: Kry Jou API Key

1. Log in by Resend Dashboard
2. Gaan na **API Keys** in die linker menu
3. Klik **Create API Key**
4. Gee dit 'n naam: `Spys Production`
5. Kies **Full Access** (of **Sending Access**)
6. **Kopieer die API key** - jy sal dit net een keer sien!

## Stap 3: Installeer Supabase CLI

As jy dit nie reeds het nie:

```bash
# macOS
brew install supabase/tap/supabase

# Of met npm
npm install -g supabase
```

## Stap 4: Login by Supabase

```bash
supabase login
```

Dit sal 'n browser oop maak - login met jou Supabase account.

## Stap 5: Link Jou Project

```bash
cd /Users/michaeldebeer/Projects/capstone
supabase link --project-ref fdtjqpkrgstoobgkmvva
```

## Stap 6: Stel die API Key Op

```bash
supabase secrets set RESEND_API_KEY=re_jou_api_key_hier
```

Vervang `re_jou_api_key_hier` met die API key wat jy in Stap 2 gekry het.

## Stap 7: Deploy die Edge Function

```bash
supabase functions deploy send-email
```

## Stap 8: Aktiveer E-pos in die Kode

Ek het reeds die kode verander om `stuurEmail: false` te wees. Wanneer die Edge Function deployed is:

1. Open: `packages/spys_api_client/lib/src/admin_bestellings_repository.dart`
2. Verander reël 503 van:
   ```dart
   stuurEmail: false, // TODO: Enable when send-email Edge Function is deployed
   ```
   na:
   ```dart
   stuurEmail: true, // Email sending enabled!
   ```

## Stap 9: Rebuild die Apps

```bash
# Clean en rebuild
flutter clean
cd apps/admin_web
flutter run -d chrome
```

## Toets E-pos Funksionaliteit

1. Log in as admin
2. Gaan na Bestellings
3. Opdateer 'n bestelling se status
4. Die gebruiker moet:
   - ✅ 'n Kennisgewing in die app kry
   - ✅ 'n E-pos by hul Gmail kry

## Belangrike Nota oor "From" Adres

Die Edge Function gebruik tans `noreply@resend.dev` as die "from" adres. Dit werk vir testing.

**Vir produksie**, moet jy jou eie domein verifieer:
1. Gaan na Resend Dashboard → **Domains**
2. Voeg jou domein by (bv. `spys.co.za`)
3. Verifieer dit met DNS rekords
4. Verander die "from" adres in `supabase/functions/send-email/index.ts`:
   ```typescript
   from: 'Spys <noreply@spys.co.za>',
   ```
5. Deploy weer: `supabase functions deploy send-email`

## Troubleshooting

### "RESEND_API_KEY not found"
- Hardloop weer: `supabase secrets set RESEND_API_KEY=jou_key`
- Verifieer: `supabase secrets list`

### "CORS Error"
- Die Edge Function het reeds CORS headers
- Maak seker die function is deployed

### "Email not arriving"
- Check jou Gmail spam folder
- Verifieer die API key is korrek
- Kyk na Resend Dashboard → **Logs** om te sien of die email gestuur is

## Koste

- **Gratis Tier:** 100 emails/dag, 3,000/maand
- **As jy meer nodig het:** Paid plans begin by $20/maand vir 50,000 emails

## Alternatiewe Providers

As jy 'n ander provider wil gebruik:

### SendGrid (100 emails/dag gratis)
```typescript
const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')

const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SENDGRID_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    personalizations: [{ to: [{ email: to }] }],
    from: { email: 'noreply@yourdomain.com' },
    subject: subject,
    content: [{ type: 'text/html', value: html }],
  }),
})
```

### Mailgun (100 emails/dag gratis)
Soortgelyk aan Resend, maar met hul eie API.

---

## Vinnige Opdrag Opsomming

```bash
# 1. Install Supabase CLI (as nodig)
brew install supabase/tap/supabase

# 2. Login
supabase login

# 3. Link project
cd /Users/michaeldebeer/Projects/capstone
supabase link --project-ref fdtjqpkrgstoobgkmvva

# 4. Set API key (gebruik jou eie key)
supabase secrets set RESEND_API_KEY=re_jou_resend_api_key

# 5. Deploy function
supabase functions deploy send-email

# 6. Verander stuurEmail na true in die kode
# 7. Rebuild app: flutter clean && cd apps/admin_web && flutter run -d chrome
```

Volg hierdie stappe en e-pos sal werk! 🎉

