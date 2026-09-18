# Todo Synology handmatige uitrol

## Doel
De printfunctionaliteit voor de stamboom handmatig op de Synology zetten zonder Git.

## Alleen FE nodig
Deze wijziging is client-side frontend functionaliteit.

Niet nodig:
- geen wijziging in MW
- geen wijziging in BE
- geen Python `requirements.txt`
- geen database release-script

## Bestanden handmatig kopieren naar de Syno
Kopieer vanuit de lokale map `FE/` in ieder geval deze bestanden naar dezelfde map op de Synology:

- `FE/src/components/FamilyTreeCanvas.jsx`
- `FE/package.json`
- `FE/package-lock.json`

Als je zeker wilt zijn dat de container exact dezelfde build krijgt als lokaal, kopieer dan liever de hele map `FE/`.

## Waarom package.json en package-lock.json mee moeten
Voor de printfunctionaliteit wordt een frontend package gebruikt:

- `jspdf`

Die dependency moet tijdens de Docker build in de FE image worden geinstalleerd.
Dat gebeurt via `npm ci` in de FE Docker build.
Daarom moeten `package.json` en `package-lock.json` op de Synology up-to-date zijn.

## Wat de FE Docker build doet
De FE Dockerfile gebruikt:

1. `COPY package.json package-lock.json ./`
2. `RUN npm ci --silent`
3. `COPY . .`
4. `RUN npm run build`

Dus: zonder bijgewerkte `package.json` en `package-lock.json` komt `jspdf` niet in de container.

## Stappen op de Synology
1. Stop eventueel de bestaande FE container.
2. Kopieer de gewijzigde FE bestanden naar de FE projectmap op de Synology.
3. Rebuild de FE image.
4. Start de FE container opnieuw.
5. Open Familiez in de browser en test de printknop.

## Verwachte functionele uitkomst
Na rebuild moet de printfunctie:

- een PDF genereren in de browser
- de volledige stamboom exporteren, niet alleen het zichtbare schermdeel
- de PDF niet breder maken dan nodig voor de boom

## Snelle controle na deploy
Controleer na de rebuild:

1. De app opent zonder frontend foutmelding.
2. De knop `Print` staat onder `Reset view`.
3. Klik op `Print` maakt direct een PDF bestand.
4. De PDF toont de volledige boom.

## Als de Syno nog de oude versie laat zien
Doe dan ook dit:

1. Browser hard refresh
2. Eventueel FE container opnieuw starten
3. Eventueel Docker build zonder cache uitvoeren

## Opmerking
`html2canvas` is voor deze uiteindelijke implementatie niet meer functioneel nodig; `jspdf` is de relevante package voor deze wijziging.