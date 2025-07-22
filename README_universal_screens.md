# Spys Flutter Universal Screens & Settings

## Oorsig
Hierdie projek gebruik moderne, responsiewe universal screens (Settings, About, Help/FAQ, Terms & Privacy) vir beide student- en admin-apps. Al hierdie screens is bereikbaar via die Settings-bladsy, wat as sentrale toegangspunt dien.

## Navigasie
- **Settings**: Sentrale plek vir tema, taal, kennisgewings, About, Help/FAQ, Terms & Privacy.
- **About**: App-beskrywing, weergawe, spanlede, kontak, “Rate” en “Feedback” knoppies.
- **Help/FAQ**: ExpansionTiles vir vrae/antwoorde, Contact Support modal/live chat, scroll-to-top FAB.
- **Terms & Privacy**: Placeholder met TODO vir toekomstige inhoud.
- **Responsief**: UI skaal goed op phone én tablet (multi-column waar van toepassing).
- **Moderne styl**: Padding, fonts, Cards, ExpansionTiles, animasies (slide transitions).
- **TODO-kommentaar**: Oral waar inhoud of backend later kom.

## Uitbreiding
- Voeg meer vrae/antwoorde by Help/FAQ deur ExpansionTiles te herhaal.
- Brei About uit met meer spanlede, kontak, of “legal” inligting.
- Vervang Contact Support modal met regte live chat of kontakvorm.
- Voeg animasies/hero transitions tussen universal screens vir ‘n premium gevoel.
- Gebruik LayoutBuilder vir multi-column layouts op tablet.

## TODO’s / Plekke vir Toekomstige Werk
- Backend/data-integrasie vir Contact Support, Feedback, Rate, ens.
- Volledige Terms of Service en Privacy Policy.
- Regte live chat of kontakvorm.
- Meer uitgebreide FAQ/Help.
- Animaties/hero transitions oral waar moontlik.

## Best Practices
- Gebruik altyd Theme.of(context).textTheme vir ALLE tekst.
- Gebruik Cards en ExpansionTiles vir moderne, leesbare UI.
- Gebruik Section Headers en Divider() vir groepe in Settings.
- Maak seker elke skerm het goeie padding, spacing, en AppBar met Back-knoppie.
- Voeg TODO-kommentaar waar backend/data-integrasie of inhoud later kom.

## Navigasie Voorbeeld
- Settings > About
- Settings > Help/FAQ
- Settings > Terms & Privacy
- Help/FAQ > Contact Support (modal/live chat)
- About > Rate this app / Send feedback (modal)

## Responsiwiteit
- Alle universal screens is getoets op phone én tablet.
- Layouts skaal goed, Cards/ExpansionTiles wys in twee kolomme op groot skerms.

## UI/UX-Verbeteringsvoorstelle
- Gebruik animasies/slide transitions tussen screens.
- Gebruik section headers in Settings vir groepe.
- Gebruik live chat of kontakvorm in Contact Support.
- Gebruik feedback modal vir “Send feedback”.

---

**Vrae?**
Kontak die Spys span: admin@spys.com 