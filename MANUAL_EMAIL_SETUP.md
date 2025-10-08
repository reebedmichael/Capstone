# Manual E-pos Opstelling (As die script nie werk nie)

## Hardloop Elke Opdrag Een-vir-Een

### 1. Login by Supabase
```bash
supabase login
```
Dit sal 'n browser oopmaak - login met jou Supabase account.

### 2. Link Jou Project
```bash
cd /Users/michaeldebeer/Projects/capstone
supabase link --project-ref fdtjqpkrgstoobgkmvva
```

### 3. Stel Resend API Key Op
```bash
supabase secrets set RESEND_API_KEY=re_jou_resend_api_key_hier
```

**VERVANG** `re_jou_resend_api_key_hier` met die werklike key van Resend!

### 4. Deploy die Edge Function
```bash
supabase functions deploy send-email
```

### 5. Rebuild die App
```bash
flutter clean
cd apps/admin_web
flutter run -d chrome
```

## Toets E-pos

1. Log in as admin
2. Gaan na Bestellings
3. Opdateer 'n bestelling status
4. Kyk in die gebruiker se Gmail vir die e-pos!

## As Iets Foutgaan

### Fout: "Authorization failed"
- Hardloop: `supabase login` weer
- Maak seker jy login met die korrekte Supabase account

### Fout: "Function deployment failed"
- Kyk of die file bestaan: `supabase/functions/send-email/index.ts`
- Maak seker jy is in die regte directory: `/Users/michaeldebeer/Projects/capstone`

### Fout: "Email not sending"
- Kyk in Resend Dashboard → Logs
- Kyk of die API key korrek is
- Verifieer dat `stuurEmail: true` in die kode is

