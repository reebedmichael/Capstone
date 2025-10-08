# Hoe om 'n Domein te Verifieer vir E-pos (Resend)

## Waarom Nodig?

Resend se gratis tier laat jou net e-pos stuur aan **jou eie e-pos adres** vir testing.
Om e-pos aan **enige gebruiker** te stuur, moet jy 'n domein verifieer.

## Wat Jy Nodig Het:

- 'n Domein naam (bv. `spys.co.za`)
- Toegang tot jou domein se DNS settings (waar jy die domein gekoop het)

## Stappe:

### 1. Gaan na Resend Dashboard
- Open: https://resend.com/domains
- Klik **"Add Domain"**

### 2. Voeg Jou Domein By
- Tik in: `spys.co.za` (of jou domein)
- Klik **"Add"**

### 3. Verifieer DNS Records
Resend sal jou 3 DNS records gee om by te voeg:

**SPF Record (TXT):**
```
Name: @
Type: TXT
Value: v=spf1 include:_spf.resend.com ~all
```

**DKIM Record (TXT):**
```
Name: resend._domainkey
Type: TXT  
Value: [Resend sal dit gee]
```

**DMARC Record (TXT):**
```
Name: _dmarc
Type: TXT
Value: v=DMARC1; p=none;
```

### 4. Voeg die Records by Jou DNS Provider
- Gaan na waar jy jou domein gekoop het (bv. GoDaddy, Namecheap, Cloudflare)
- Gaan na DNS Settings
- Voeg die 3 TXT records by
- Wag 10-30 minute vir propagation

### 5. Verifieer in Resend
- Gaan terug na Resend → Domains
- Klik **"Verify"** langs jou domein
- As alles korrek is, sal dit groen wys: "Verified ✓"

### 6. Verander die "From" Adres
In Supabase Edge Function, verander:

**Van:**
```typescript
from: 'Spys <noreply@resend.dev>',
```

**Na:**
```typescript
from: 'Spys <noreply@spys.co.za>', // Gebruik jou domein
```

Deploy weer die function in Supabase Dashboard.

### 7. Aktiveer E-pos
Verander in die kode:
```dart
stuurEmail: false,  // Van dit
```
na:
```dart
stuurEmail: true,   // Na dit
```

Rebuild die app en e-pos sal werk vir alle gebruikers!

---

## Alternatief: Gebruik 'n Gratis Subdomain

As jy nie 'n domein het nie, kan jy:
1. Gebruik Netlify of Vercel (hulle gee gratis subdomains)
2. Kry 'n gratis domein by Freenom
3. Gebruik jou Resend testing adres net vir jou eie testing

---

## Koste

- **Met geverifieerde domein:** 100 emails/dag gratis, 3,000/maand
- **Sonder domein:** Net testing emails aan jou eie adres

