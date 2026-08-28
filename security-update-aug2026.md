# Security update Familiez - augustus 2026

## Doel

Dit document is de uitvoeringsopdracht en het hervattingslog voor het controleren en
bijwerken van security-relevante dependencies en containerbasisimages in het
Familiez-project.

Rootmap:

`/home/frans/Documenten/Dev/Familiez`

Betrokken repositories:

- `FE/` - React, Vite, MUI, React Router en npm-dependencies
- `MW/` - Python, FastAPI, SQLAlchemy, PyMySQL en overige Python-dependencies
- `BE/` - MariaDB-container en stored procedures

`MOB/` valt buiten deze opdracht, tenzij dit later expliciet wordt toegevoegd.

## Belangrijke uitvoeringsregels

- Dit document moet tijdens de uitvoering na iedere betekenisvolle stap worden bijgewerkt.
- Noteer ook mislukte commando's, conflicten, blokkades en teruggedraaide stappen.
- Controleer voor iedere wijziging de actuele branch en working tree van de betreffende repository.
- Werk per repository en per dependencygroep; combineer geen grote, ongerelateerde upgrades.
- Voer eerst een audit uit en wijzig daarna pas bestanden.
- Gebruik geen `npm audit fix --force` zonder voorafgaande beoordeling van major-upgrades en regressierisico.
- Behoud bestaande lokale wijzigingen; nooit resetten of checkouten om wijzigingen te verwijderen zonder expliciete toestemming.
- Voer build, tests en security-audit uit na iedere wijzigingsgroep.
- Commit en push alleen na expliciete toestemming van de gebruiker.
- Deploy nooit naar Synology of productie zonder afzonderlijke expliciete toestemming.
- Secrets, tokens, wachtwoorden en inhoud van `.env`-bestanden mogen niet in dit document of in logs worden opgenomen.

## Huidige bekende auditstatus

Audit uitgevoerd op 28 augustus 2026, zonder bestanden te wijzigen.

### FE

`npm audit` rapporteerde:

- 1 critical
- 17 high
- 7 moderate
- 1 low
- totaal 26 advisories

Met dev-dependencies uitgesloten bleven 9 advisories over:

- 1 critical
- 5 high
- 3 moderate

Directe aandachtspunten zijn onder andere:

- `axios` 1.6.8
- `lodash` 4.17.21
- `react-router-dom` 6.23.0
- `vite` 5.2.11

Indirecte aandachtspunten zijn onder andere `form-data`, `follow-redirects`,
`@remix-run/router`, `dompurify`, `rollup` en `esbuild`.

### MW

`MW/requirements.txt` bevat onder andere oudere versies van:

- `fastapi` 0.104.1
- `cryptography` 41.0.7
- `PyJWT` 2.8.0
- `requests` 2.31.0
- `Pillow` 10.2.0
- `python-multipart` 0.0.6

`pip check` was succesvol. Een volledige `pip-audit` kon niet worden uitgevoerd,
omdat `pip-audit` niet in de bestaande MW-venv is geinstalleerd. Eerst moet daarom
een reproduceerbare Python security-audit worden ingericht of tijdelijk beschikbaar
gemaakt. Daarna moeten de actuele advisories worden vastgesteld.

### BE

BE bevat geen vergelijkbaar npm- of Python-dependencybestand. Wel gebruikt
`BE/dockerfile` momenteel:

`FROM mariadb:latest`

Dit is een reproduceerbaarheids- en onderhoudsrisico. De image moet later worden
beoordeeld en bij voorkeur worden vervangen door een expliciet gepinde, ondersteunde
MariaDB-versie. De image moet daarna worden gescand en de stored procedures moeten
worden getest.

### GitHub-configuratie

In FE, MW en BE is geen Dependabot-configuratie of securityworkflow aangetroffen.
Beoordeel later of Dependabot en periodieke dependency- of image-scans moeten worden
toegevoegd.

## Geprioriteerde uitvoeringsopdracht

### 1. FE productie-dependencies

- Controleer actuele advisories en veilige doelversies.
- Upgrade eerst `axios`, `lodash` en `react-router-dom` gecontroleerd.
- Controleer indirecte packages zoals `form-data`, `follow-redirects`,
  `@remix-run/router` en `dompurify`.
- Draai FE-tests, `npm run build` en opnieuw `npm audit`.
- Controleer routerredirects, API-aanroepen, bestandsuploads en PDF-functionaliteit.

### 2. FE buildtoolchain

- Beoordeel `vite`, `rollup` en `esbuild` afzonderlijk.
- Houd rekening met de huidige React 18- en Vite-configuratie.
- Voer build, tests en een handmatige browsercontrole uit.
- Controleer of de Docker-build nog reproduceerbaar werkt.

### 3. MW audit inrichten

- Kies een reproduceerbare methode, bij voorkeur `pip-audit` in CI of een expliciet
  auditcommando in de MW-documentatie.
- Leg vast welke interpreter en dependencybron worden gebruikt.
- Scan zowel `requirements.txt` als de daadwerkelijk gebouwde omgeving.

### 4. MW dependencies upgraden

- Upgrade FastAPI en de bijbehorende Starlette-versie samen.
- Beoordeel daarna `cryptography`, `PyJWT`, `requests`, Pillow en
  `python-multipart`.
- Draai alle MW-pytest-tests en controleer auth, sessies, uploads en LDAP/OIDC.
- Controleer expliciet backward compatibility van de stored-procedure-aanroepen.

### 5. BE MariaDB-image

- Bepaal een ondersteunde MariaDB-versie die past bij schema en stored procedures.
- Vervang `mariadb:latest` door een expliciete versie.
- Scan de image met Docker Scout, Trivy of een gelijkwaardig hulpmiddel.
- Test initialisatie, databaseverbinding, sprocs en bestaande releasevolgorde.

### 6. Structurele GitHub-security

- Beoordeel Dependabot voor npm en Python.
- Beoordeel container image scanning voor FE/MW/BE.
- Voeg alleen workflows toe nadat branch-, secret- en deploymentgedrag is gecontroleerd.

## Per wijzigingsgroep vastleggen

Gebruik voor iedere wijzigingsgroep deze gegevens:

- Datum en tijd:
- Repository:
- Branch:
- Starting commit:
- Doel van de stap:
- Auditresultaat:
- Gewijzigde bestanden:
- Uitgevoerde commando's:
- Tests/builds/scans:
- Resultaat:
- Commit en push:
- Open risico's:
- Exacte volgende stap:

## Uitvoeringslog

### 2026-08-28 - Voorbereidende audit

- Status: audit afgerond, uitvoering nog niet gestart.
- Repository: root, FE, MW en BE gecontroleerd.
- FE: npm-audit uitgevoerd; 26 advisories totaal, 9 met dev-dependencies uitgesloten.
- MW: `pip check` succesvol; volledige `pip-audit` geblokkeerd omdat de tool niet is geinstalleerd.
- BE: `mariadb:latest` als aandachtspunt vastgesteld.
- GitHub: geen Dependabot- of securityworkflow gevonden.
- Wijzigingen uitgevoerd: geen dependency-, broncode-, configuratie- of Dockerfile-wijzigingen.
- Commits/pushes: geen.
- Volgende stap: eerst toestemming en een uitvoeringskeuze per dependencygroep bevestigen; daarna FE productie-dependencies als eerste behandelen.

### 2026-08-28 - WG-01 FE productie-dependencies

- Status: dependency-update uitgevoerd; nog niet gecommit, gepusht of gedeployed.
- Repository: FE.
- Branch: `main`.
- Starting commit: `46361bf`.
- Gewijzigde dependencies: `axios` 1.6.8 naar 1.20.0, `lodash` 4.17.21 naar 4.18.1,
  `react-router-dom` 6.23.0 naar 6.30.6.
- Indirect resultaat: `form-data` 4.0.6, `follow-redirects` 1.16.0 en
  `@remix-run/router` 1.23.4 zijn bijgewerkt.
- Productie-audit na update: 4 moderate, 0 high, 0 critical, 0 low.
- Tests: `npm test` faalde in 3 bestaande `PersonEditForm`-tests door een
  verwachtingsverschil rond `marriagePlace: null`; dit staat los van de dependency-update.
- Build: `npm run build` geslaagd. Bestaande waarschuwing over grote Vite-chunks blijft aanwezig.
- Wijzigingen: `FE/package.json` en `FE/package-lock.json` zijn aangepast; broncode is niet aangepast.
- Open risico's: `dompurify`, React Router en `yaml` rapporteren nog moderate advisories.
- Exacte volgende stap: de 3 PersonEditForm-testfailures apart beoordelen, daarna de
  resterende moderate advisories onderzoeken voordat deze wijzigingsgroep wordt gecommit.

### 2026-08-28 - WG-01 testblokkade opgelost

- Status: testverwachtingen bijgewerkt; nog niet gecommit, gepusht of gedeployed.
- Repository: FE.
- Branch: `main`.
- Oorzaak: drie `PersonEditForm`-tests verwachtten het oudere payload zonder
  `marriagePlace: null`, terwijl de component en het actuele API-contract dit veld
  correct meesturen.
- Gewijzigd bestand: `FE/src/components/PersonEditForm.test.jsx`.
- Aanpassing: alle drie verwachtingen uitgebreid met `marriagePlace: null`.
- Gerichte test: `PersonEditForm.test.jsx` 3/3 geslaagd.
- Volledige FE-testset: 3/3 geslaagd.
- Build: `npm run build` geslaagd. Bestaande waarschuwing over grote Vite-chunks blijft aanwezig.
- Open risico's: 4 moderate productie-advisories blijven over (`dompurify`, React Router
  en `yaml`); deze zijn nog niet onderzocht of aangepast.
- Exacte volgende stap: de resterende moderate advisories beoordelen en bepalen of ze
  door verdere gecontroleerde updates kunnen worden opgelost.

### 2026-08-28 - WG-01 resterende FE-advisories beoordeeld

- Status: read-only beoordeling afgerond; geen nieuwe dependency- of broncodewijzigingen.
- Repository: FE.
- Branch: `main`.
- `dompurify` 3.4.1: transitief en optioneel via `jspdf` 4.2.1; de eigen broncode
  gebruikt geen DOMPurify, `sanitize`, `innerHTML` of vergelijkbare configuratie.
  Nieuwere DOMPurify-release 3.4.14 bestaat, maar npm geeft hiervoor geen directe
  automatische fix omdat de dependencyboom via jsPDF loopt.
- React Router 6.30.6: de eigen code gebruikt alleen vaste interne paden met
  `navigate`, `Link`, `Route` en `Navigate`; er is geen aangetroffen redirect op
  gebruikersgestuurde externe URL's. De advisories worden pas volledig opgelost
  buiten de 6.x-lijn; Router 7 vereist een afzonderlijke compatibiliteitsbeoordeling.
- `yaml` 1.10.2: transitief via `@emotion`/`babel-plugin-macros` en niet door de
  applicatiecode gebruikt. `yaml` 1.10.3 bestaat; eerst testen of een gerichte npm
  `overrides`-regel compatibel is met de bestaande toolchain.
- Actuele productie-audit: 4 moderate, 0 high, 0 critical, 0 low.
- Exacte volgende stap: goedkeuring vragen voor een afzonderlijke kleine proef met
  de `yaml`-override en eventueel een expliciete DOMPurify-override; React Router 7
  niet in dezelfde wijziging meenemen. Daarna opnieuw audit, tests en build uitvoeren.

### 2026-08-28 - WG-01 overrideproef afgerond

- Status: gecontroleerde overrideproef afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: FE.
- `dompurify` is via een expliciete override bijgewerkt naar `3.4.14` en de advisory
  is daarmee verdwenen.
- De globale `yaml`-override naar `1.10.3` is getest maar verwijderd omdat deze een
  ongeldig peer-conflict veroorzaakte met Vitest/Vite 8, dat `yaml ^2.4.2` verwacht.
  De bestaande Emotion/Babel-route gebruikt zelfstandig `yaml 1.10.3` binnen zijn
  bestaande `^1.10.0`-range; Vitest gebruikt zijn eigen `yaml 2.8.3`.
- Productie-audit na de definitieve proef: 2 moderate, 0 high, 0 critical, 0 low.
  Resterend: React Router 6.30.6 en `react-router-dom` via advisories die pas buiten
  de 6.x-lijn volledig worden opgelost.
- Dependencyboom: `npm ls yaml dompurify --all` succesvol.
- Tests: volledige FE-testset 3/3 geslaagd.
- Build: `npm run build` geslaagd. Bestaande waarschuwing over grote Vite-chunks blijft aanwezig.
- Gewijzigde bestanden: `FE/package.json`, `FE/package-lock.json` en de eerder bijgewerkte
  `FE/src/components/PersonEditForm.test.jsx`.
- Exacte volgende stap: React Router 7 als afzonderlijke upgrade beoordelen, of deze
  resterende moderate advisories accepteren gezien het gebruik van uitsluitend vaste
  interne navigatiepaden. Geen verdere FE-wijziging zonder nieuwe expliciete keuze.

## Hervatten na onderbreking

Lees eerst dit document volledig en controleer daarna:

1. de laatste logsectie;
2. de actuele branch en working tree van de genoemde repository;
3. de laatst vastgelegde starting commit;
4. of de genoemde audit- en testresultaten nog reproduceerbaar zijn;
5. de exacte volgende stap uit het log.

Ga pas verder met wijzigen nadat de werkboom en branchstatus zijn vastgelegd.
