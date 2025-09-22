# Beursie Funksionaliteit Toets Gids

## 🧪 Hoe Om Die Beursie Funksionaliteit Te Toets

### 1. **Start Die Mobile App**
```bash
cd /Users/michaeldebeer/Projects/capstone
melos run run:mobile
```

### 2. **Navigeer Na Beursie Bladsy**
- Klik op die "Beursie" tab in die onderste navigasie
- Jy sal die huidige beursie balans sien (moet R0.00 wees vir nuwe gebruikers)

### 3. **Toets Beursie Oplaai**
1. **Kies 'n Bedrag:**
   - Klik op een van die vinnige bedrae (R50, R100, R200, R500)
   - OF voer 'n eie bedrag in (tussen R10 en R1000)

2. **Kies Betaalmetode:**
   - Bankkaart (oranje knoppie)
   - SnapScan (wit knoppie)
   - EFT (wit knoppie)

3. **Laai Beursie Op:**
   - Klik "Laai R[bedrag]" knoppie
   - Wag vir die betaling simulasie (2 sekondes)
   - Jy sal 'n suksesboodskap sien: "R[bedrag] suksesvol bygevoeg aan jou beursie!"

### 4. **Kontroleer Opgedateerde Balans**
- Die beursie balans moet nou opdateer wees
- Byvoorbeeld: As jy R100 bygevoeg het, moet die balans R100.00 wees

### 5. **Toets Transaksie Geskiedenis**
- Wissel na die "Geskiedenis" tab
- Jy sal die nuwe transaksie sien met:
  - Groen pijl (vir inbetaling)
  - Bedrag en beskrywing
  - Datum en tyd

### 6. **Toets Bestelling Met Beursie**
1. **Navigeer Na Kos Bladsy:**
   - Klik op "Tuis" tab
   - Voeg items by jou mandjie

2. **Gaan Na Mandjie:**
   - Klik op die mandjie ikoon
   - Klik "Bestel" knoppie

3. **Kontroleer Beursie Aftrekking:**
   - Die bestelling moet jou beursie balans verminder
   - Jy sal 'n nuwe transaksie sien in die geskiedenis (rooi pijl vir uitbetaling)

## 🔍 **Wat Om Te Kontroleer**

### ✅ **Suksesvolle Toetsing:**
- [ ] Beursie balans laai korrek uit database
- [ ] Top-up werk met alle betaalmetodes
- [ ] Balans opdateer na top-up
- [ ] Transaksie verskyn in geskiedenis
- [ ] Bestelling verminder beursie balans
- [ ] Alle boodskappe is in Afrikaans
- [ ] Loading states werk korrek
- [ ] Foutafhandeling werk

### ❌ **Moenie Toets Nie:**
- Regte betalings (alles is gesimuleer)
- Betaling verifikasie
- Betaling geskiedenis

## 🐛 **Troubleshooting**

### **As Beursie Balans Nie Opdateer Nie:**
1. Kontroleer of jy aangemeld is
2. Probeer die app herlaai
3. Kontroleer die terminal vir foute

### **As Transaksies Nie Verskyn Nie:**
1. Wissel tussen tabs
2. Trek af om te refresh
3. Kontroleer of die database migrasie toegepas is

### **As Top-up Fails:**
1. Kontroleer of die bedrag tussen R10 en R1000 is
2. Maak seker jy het 'n geldige bedrag ingevoer
3. Probeer 'n ander betaalmetode

## 📱 **Verwagte Gedrag**

### **Voor Top-up:**
- Beursie balans: R0.00
- Geen transaksies in geskiedenis

### **Na Top-up van R100:**
- Beursie balans: R100.00
- 1 transaksie in geskiedenis (groen, +R100.00)

### **Na Bestelling van R60:**
- Beursie balans: R40.00
- 2 transaksies in geskiedenis:
  - Groen: +R100.00 (top-up)
  - Rooi: -R60.00 (bestelling)

## 🎯 **Toets Scenario's**

### **Scenario 1: Eerste Top-up**
1. Gaan na Beursie
2. Kies R50
3. Kies Bankkaart
4. Klik "Laai R50"
5. Kontroleer balans is R50.00

### **Scenario 2: Groot Top-up**
1. Voer R500 in
2. Kies SnapScan
3. Klik "Laai R500"
4. Kontroleer balans is R550.00

### **Scenario 3: Bestelling Met Beursie**
1. Gaan na Tuis
2. Voeg items by (totaal ~R60)
3. Bestel
4. Kontroleer beursie balans verminder

### **Scenario 4: Onvoldoende Fondse**
1. Probeer bestel met R0.00 balans
2. Jy moet 'n foutboodskap sien
3. Laai beursie op
4. Probeer weer bestel

## ✅ **Sukses Kriterie**

Die beursie funksionaliteit is suksesvol as:
- [ ] Alle top-ups werk
- [ ] Balans opdateer korrek
- [ ] Transaksies word gestoor
- [ ] Bestellings verminder balans
- [ ] Geen foute in terminal
- [ ] Alle UI elemente werk
- [ ] Afrikaanse boodskappe verskyn

## 🚀 **Volgende Stappe**

Na suksesvolle toetsing:
1. Implementeer regte betaling integrasie
2. Voeg betaling verifikasie by
3. Verbeter foutafhandeling
4. Voeg meer betaalmetodes by
