# Kennisgewings Bestuur - Toets Gids

## Oorsig

Die kennisgewingbestuur stelsel is nou volledig geïmplementeer vir die admin paneel. Administrateurs het volledige beheer oor die skep, wysiging, afsluiting en verwydering van kennisgewings.

## Funksionaliteit Geïmplementeer

### ✅ Admin Paneel Funksies

1. **Skep Kennisgewings**
   - Stuur aan alle gebruikers
   - Stuur aan spesifieke groepe (Admins, Studente, Personeel)
   - Kies kennisgewingtipe (Info, Waarskuwing, Sukses, Fout)
   - Voeg boodskap by

2. **Wysig Bestaande Kennisgewings**
   - Redigeer boodskap
   - Verander tipe
   - Opdateer word onmiddellik weerspieël

3. **Verwyder Kennisgewings**
   - Verwyder individuele kennisgewings
   - Bevestigingsdialoog voorkom onbedoelde verwydering

4. **Bestuur en Filter**
   - Filter op soort (Alles, Gebruiker, Globaal)
   - Filter op tipe (Alles, Info, Waarskuwing, Sukses, Fout)
   - Sien statistieke (Totaal, Gebruiker, Globaal, Waarskuwings)
   - Bekyk besonderhede van elke kennisgewing

5. **Sinchronisasie**
   - Alle veranderinge is onmiddellik in databasis
   - Mobiele app kry outomaties die nuutste kennisgewings

### ✅ Mobiele App Funksies

1. **Ontvang Kennisgewings**
   - Kry alle kennisgewings vir die ingetekende gebruiker
   - Sien ongelees/gelees status
   - Filter op tipe en status

2. **Markeer as Gelees**
   - Individuele kennisgewings
   - Alle kennisgewings op een slag

3. **Statistieke**
   - Totaal kennisgewings
   - Ongelees telling
   - Gelees telling

## Database Strukture

### Tabelle

#### 1. `kennisgewings`
Individuele kennisgewings vir spesifieke gebruikers.

| Veld | Tipe | Beskrywing |
|------|------|------------|
| `kennis_id` | uuid | Primêre sleutel |
| `gebr_id` | uuid | Gebruiker wat die kennisgewing ontvang |
| `kennis_beskrywing` | text | Boodskap inhoud |
| `kennis_gelees` | boolean | Of gebruiker dit gelees het |
| `kennis_geskep_datum` | timestamp | Wanneer dit geskep is |
| `kennis_tipe_id` | uuid | Verwysing na kennisgewing tipe |

#### 2. `globale_kennisgewings`
Globale kennisgewings (nie meer aktief gebruik nie - vervang deur gebruiker-spesifieke kennisgewings aan almal).

| Veld | Tipe | Beskrywing |
|------|------|------------|
| `glob_kennis_id` | uuid | Primêre sleutel |
| `glob_kennis_beskrywing` | text | Boodskap inhoud |
| `glob_kennis_geskep_datum` | timestamp | Wanneer dit geskep is |
| `kennis_tipe_id` | uuid | Verwysing na kennisgewing tipe |

#### 3. `kennisgewing_tipes`
Beskikbare kennisgewingtipes.

| Veld | Tipe | Beskrywing |
|------|------|------------|
| `kennis_tipe_id` | uuid | Primêre sleutel |
| `kennis_tipe_naam` | text | Tipe naam (info, waarskuwing, sukses, fout) |

## API Metodes (KennisgewingRepository)

### Skep Kennisgewings

```dart
// Stuur aan spesifieke gebruiker
Future<bool> skepKennisgewing({
  required String gebrId,
  required String beskrywing,
  required String tipeNaam,
  String? titel,
  bool stuurEmail = false,
})

// Stuur aan alle gebruikers
Future<bool> stuurAanAlleGebruikers({
  required String beskrywing,
  required String tipeNaam,
  String? titel,
  bool stuurEmail = false,
})

// Stuur aan spesifieke gebruikers
Future<bool> stuurAanSpesifiekeGebruikers({
  required List<String> gebrIds,
  required String beskrywing,
  required String tipeNaam,
  String? titel,
  bool stuurEmail = false,
})
```

### Lees Kennisgewings

```dart
// Kry kennisgewings vir spesifieke gebruiker
Future<List<Map<String, dynamic>>> kryKennisgewings(String gebrId)

// Kry ongelees kennisgewings
Future<List<Map<String, dynamic>>> kryOngeleesKennisgewings(String gebrId)

// Kry alle kennisgewings vir admin
Future<List<Map<String, dynamic>>> kryAlleKennisgewingsVirAdmin()

// Kry statistieke
Future<Map<String, int>> kryKennisgewingStatistieke(String gebrId)
```

### Opdateer Kennisgewings

```dart
// Opdateer gebruiker kennisgewing
Future<bool> opdateerKennisgewing({
  required String kennisId,
  String? beskrywing,
  String? tipeNaam,
})

// Opdateer globale kennisgewing
Future<bool> opdateerGlobaleKennisgewing({
  required String globKennisId,
  String? beskrywing,
  String? tipeNaam,
})

// Markeer as gelees
Future<bool> markeerAsGelees(String kennisId)

// Markeer alles as gelees
Future<bool> markeerAllesAsGelees(String gebrId)
```

### Verwyder Kennisgewings

```dart
// Verwyder gebruiker kennisgewing
Future<bool> verwyderKennisgewing(String kennisId)

// Verwyder globale kennisgewing
Future<bool> verwyderGlobaleKennisgewing(String globKennisId)
```

## Toets Scenario's

### Scenario 1: Skep Nuwe Kennisgewing aan Almal

**Stappe:**
1. Teken in op admin paneel
2. Navigeer na "Kennisgewings" in die sidebar
3. Klik op "Skep Kennisgewing" knoppie
4. Voer boodskap in: "Welkom by die nuwe semester!"
5. Kies tipe: "Info"
6. Kies doelgroep: "Alle Gebruikers"
7. Klik "Stuur Kennisgewing"

**Verwagte Resultaat:**
- Suksesboodskap wys
- Kennisgewing verskyn in die lys
- Alle gebruikers ontvang die kennisgewing
- Mobiele app wys die kennisgewing vir alle gebruikers

### Scenario 2: Redigeer Bestaande Kennisgewing

**Stappe:**
1. Navigeer na "Kennisgewings" bladsy
2. Klik op "Redigeer" knoppie op 'n kennisgewing
3. Verander die boodskap na: "Opgdateerde boodskap"
4. Verander tipe na "Waarskuwing"
5. Klik "Opdateer"

**Verwagte Resultaat:**
- Suksesboodskap wys
- Kennisgewing se boodskap en tipe is opgedateer
- Veranderinge is onmiddellik sigbaar
- Mobiele app wys die opgedateerde boodskap

### Scenario 3: Verwyder Kennisgewing

**Stappe:**
1. Navigeer na "Kennisgewings" bladsy
2. Klik op "Verwyder" knoppie op 'n kennisgewing
3. Bevestig verwydering in die dialoog

**Verwagte Resultaat:**
- Suksesboodskap wys
- Kennisgewing is verwyder uit die lys
- Kennisgewing is nie meer in databasis nie
- Mobiele app wys nie meer die kennisgewing nie

### Scenario 4: Filter Kennisgewings

**Stappe:**
1. Navigeer na "Kennisgewings" bladsy
2. Klik op "Soort" dropdown
3. Kies "Slegs Gebruiker"
4. Klik op "Tipe" dropdown
5. Kies "Waarskuwing"

**Verwagte Resultaat:**
- Slegs gebruiker-spesifieke waarskuwings word gewys
- Telling by onder word aangepas
- Ander kennisgewings word gefiltreer uit

### Scenario 5: Mobiele App Ontvang Kennisgewing

**Stappe:**
1. Admin stuur 'n nuwe kennisgewing
2. Open mobiele app
3. Navigeer na kennisgewings bladsy

**Verwagte Resultaat:**
- Nuwe kennisgewing verskyn in die lys
- Ongelees badge wys
- Gebruiker kan kennisgewing lees
- Gebruiker kan kennisgewing as gelees markeer

### Scenario 6: Stuur aan Spesifieke Groep

**Stappe:**
1. Navigeer na "Kennisgewings" bladsy
2. Klik op "Skep Kennisgewing"
3. Voer boodskap in: "Admin vergadering môre om 10:00"
4. Kies tipe: "Info"
5. Kies doelgroep: "Slegs Admins"
6. Klik "Stuur Kennisgewing"

**Verwagte Resultaat:**
- Slegs admin gebruikers ontvang die kennisgewing
- Ander gebruikers sien dit nie
- Admin paneel wys die kennisgewing met ontvanger inligting

## Toets Lys

- [ ] Skep kennisgewing aan alle gebruikers
- [ ] Skep kennisgewing aan admins
- [ ] Skep kennisgewing aan studente
- [ ] Skep kennisgewing aan personeel
- [ ] Redigeer bestaande kennisgewing se boodskap
- [ ] Redigeer bestaande kennisgewing se tipe
- [ ] Verwyder kennisgewing
- [ ] Filter op soort (gebruiker/globaal)
- [ ] Filter op tipe (info/waarskuwing/sukses/fout)
- [ ] Bekyk kennisgewing besonderhede
- [ ] Mobiele app ontvang nuwe kennisgewings
- [ ] Mobiele app markeer as gelees
- [ ] Mobiele app markeer alles as gelees
- [ ] Mobiele app filter kennisgewings
- [ ] Statistieke is korrek op admin paneel
- [ ] Statistieke is korrek op mobiele app
- [ ] Sinchronisasie tussen admin en mobiel werk

## Bekende Beperkinge

1. **Geen Push Kennisgewings**: Die stelsel gebruik tans net databasis kennisgewings. Firebase Cloud Messaging (FCM) is nog nie geïntegreer nie, so gebruikers moet die app oopmaak om nuwe kennisgewings te sien.

2. **Geen Gebruiker Seleksie**: Wanneer "Spesifieke Gebruiker" gekies word, moet die admin handmatig gebruiker ID's voorsien. 'n UI om gebruikers te kies is nie geïmplementeer nie.

3. **Geen Geskeduleerde Kennisgewings**: Kennisgewings word onmiddellik gestuur. Daar is geen funksionaliteit om kennisgewings vir later te skeduleer nie.

## Volgende Stappe (Opsioneel)

1. **Firebase Cloud Messaging (FCM) Integrasie**
   - Push kennisgewings na gebruikers
   - Gebruikers ontvang kennisgewings selfs as app toe is

2. **Gebruiker Seleksie UI**
   - Kies spesifieke gebruikers uit 'n lys
   - Stuur aan verskeie gebruikers gelyktydig

3. **Geskeduleerde Kennisgewings**
   - Skeduleer kennisgewings vir 'n spesifieke datum/tyd
   - Herhalende kennisgewings

4. **Kennisgewing Templaaie**
   - Skep herbruikbare kennisgewing templaaie
   - Vinnige toegang tot algemene kennisgewings

5. **Email Kennisgewings**
   - Stuur email saam met in-app kennisgewing
   - Konfigureerbare email templates

6. **Kennisgewing Prioriteit**
   - Verskillende prioriteit vlakke
   - Hoë prioriteit kennisgewings wys eerste

## Ondersteuning

Vir probleme of vrae:
1. Kyk na linter errors: `flutter analyze`
2. Kyk na databasis logs in Supabase
3. Kyk na app logs vir enige foute

## Gevolgtrekking

Die kennisgewingbestuur stelsel is nou volledig funksioneel en gereed vir gebruik. Administrateurs kan kennisgewings skep, redigeer en verwyder, en alle veranderinge word onmiddellik weerspieël in die mobiele app. Die stelsel is gebou met skaalbaarhied in gedagte en kan maklik uitgebrei word met addisionele funksies soos push kennisgewings en geskeduleerde kennisgewings.

