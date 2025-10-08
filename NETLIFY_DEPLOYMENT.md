# Netlify Deployment Gids vir Spys Admin

## Stappe om op Netlify te deploy

### 1. Push jou kode na Git
Maak seker al jou veranderinge is ge-commit en gepush na GitHub:
```bash
git add netlify.toml build.sh NETLIFY_DEPLOYMENT.md
git commit -m "Add Netlify deployment configuration"
git push origin main
```

### 2. Netlify Konfigurasie

Wanneer jy die Netlify deployment opstel, gebruik die volgende instellings:

**Team:** Michael

**Project name:** spysadmin (of jou voorkeur naam)

**Branch to deploy:** main

**Base directory:** (los leeg - die netlify.toml lêer bepaal dit)

**Build command:** (los leeg - die netlify.toml lêer bepaal dit)

**Publish directory:** (los leeg - die netlify.toml lêer bepaal dit)

**Environment variables:** Nie nodig nie (credentials is reeds hardcoded)

### 3. Deploy
Kliek op "Deploy spysadmin" knoppie.

Die eerste deployment sal omtrent 10-15 minute neem omdat Flutter afgelaai moet word.

### Belangrik
- Die `netlify.toml` lêer in die repo root bepaal alle build instellings
- Die `build.sh` script hanteer die Flutter installasie en build proses
- Geen environment variables is nodig nie
- Netlify sal outomaties rebuild wanneer jy na die `main` branch push

## Troubleshooting

As die build faal:
1. Kyk na die build logs in Netlify
2. Maak seker die build.sh script uitvoerbaar is
3. Verifieer dat die netlify.toml lêer korrek is

## Build Tyd Optimisering

Om vinniger builds te kry, kan jy oorweeg om:
- 'n Netlify build plugin vir Flutter te gebruik
- Flutter cache in Netlify Build Cache te stoor

## Live URL

Na suksesvolle deployment sal jou app beskikbaar wees by:
https://spysadmin.netlify.app

(Of die URL wat Netlify genereer)

