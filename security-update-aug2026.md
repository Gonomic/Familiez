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

### 2026-08-28 - WG-02 React Router 7 read-only beoordeling

- Status: compatibiliteitsanalyse afgerond; geen Router-, broncode- of Dockerfile-wijzigingen.
- Repository: FE.
- Branch: `main`.
- Huidige versie: React 18.3.1 met `react-router-dom` 6.30.6.
- Gebruikte Router-API's: `BrowserRouter`, `Routes`, `Route`, `Navigate`, `Link` en
  `useNavigate`; geen loaders, actions, SSR/hydration of data-router-API's aangetroffen.
- Router 7.18.2 ondersteunt React en React DOM vanaf 18, maar vereist Node `>=20.0.0`.
- FE gebruikt in `FE/dockerfile` momenteel `node:18-bullseye` voor de build. Een losse
  Router 7-update is daarom niet verantwoord; Node 20 moet onderdeel zijn van dezelfde
  afzonderlijke wijzigingsgroep.
- Blootstelling: alleen vaste interne navigatiepaden aangetroffen; geen externe of
  gebruikersgestuurde redirectwaarden. De SSR hydration advisory is niet van toepassing
  op de huidige statische Vite/nginx-build.
- Advies: Router 7 niet nu invoeren. Plan later een gecombineerde Node 20 plus Router 7
  wijziging met browser-, build- en deploymentcontrole, of accepteer de twee moderate
  advisories voorlopig als beheerst risico.
- Exacte volgende stap: expliciete keuze maken tussen tijdelijke risicoacceptatie of een
  aparte Node 20/Router 7-upgrade. Daarna pas MW-audit starten.

### 2026-08-28 - WG-03 MW dependency-audit

- Status: read-only audit afgerond; geen `requirements.txt`- of broncodewijzigingen.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Starting commit: `ae890cd`.
- Working tree: schoon.
- Python: 3.12.3 in de bestaande lokale venv.
- Audittool: `pip-audit` tijdelijk in de lokale venv geinstalleerd; niet toegevoegd aan
  `requirements.txt` en niet in de repository opgenomen.
- Auditresultaat: 68 bekende kwetsbaarheden in 10 pakketten bij audit van
  `requirements.txt`.
- Belangrijkste kwetsbare pakketten en minimale bekende fixes:
  - `fastapi` 0.104.1 -> 0.109.1 of hoger.
  - `starlette` 0.27.0 -> 0.47.2 of hoger voor de relevante oudere multipart-issue;
    nieuwere advisories vragen 1.0.1 tot 1.3.1. FastAPI moet hiermee compatibel worden
    geupgrade, niet Starlette los.
  - `python-multipart` 0.0.6 -> minimaal 0.0.31 voor alle in deze audit gevonden fixes.
  - `cryptography` 41.0.7 -> minimaal 49.0.0 om alle gevonden advisories te dekken.
  - `PyJWT` 2.8.0 -> minimaal 2.13.0 om alle gevonden advisories te dekken.
  - `requests` 2.31.0 -> minimaal 2.33.0 om alle gevonden advisories te dekken.
  - `Pillow` 10.2.0 -> minimaal 12.3.0 om alle gevonden advisories te dekken.
  - `PyMySQL` 1.1.0 -> 1.1.1 of hoger.
  - `python-dotenv` 1.0.0 -> 1.2.2 of hoger.
  - `pytest` 9.0.2 -> 9.0.3 of hoger; dit is test-only.
- Daadwerkelijk gebruik: MW gebruikt multipart uploads (`UploadFile`/`Form`), Pillow
  voor afbeeldingsverwerking, PyJWT voor OIDC-tokenvalidatie en Requests voor OIDC.
- `pip check`: succesvol.
- Exacte volgende stap: eerst FastAPI/Starlette en `python-multipart` als framework- en
  uploadgroep compatibel upgraden in een aparte wijzigingsgroep; daarna tests voor auth,
  sessies en uploads uitvoeren. Overige pakketten pas in aparte kleine groepen upgraden.

### 2026-08-28 - WG-03 MW framework- en multipart-update

- Status: update en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `MW/requirements.txt`.
- Updates: `fastapi` 0.104.1 naar 0.120.4, expliciet `starlette` 0.49.3 toegevoegd,
  en `python-multipart` 0.0.6 naar 0.0.31.
- Installatie: geslaagd in de lokale Python 3.12.3-venv.
- `pip check`: geslaagd.
- MW-tests: `85 passed`, 15 deprecation warnings.
- Audit na update: 56 bekende kwetsbaarheden in 8 packages volgens audit van
  `requirements.txt`. De multipart-advisories zijn verminderd; Starlette bevat nog
  advisories waarvoor Starlette 1.0.1 tot 1.3.1 als fix wordt gemeld.
- Open resterende risico's: `cryptography` 41.0.7, PyJWT 2.8.0, Requests 2.31.0,
  Pillow 10.2.0, PyMySQL 1.1.0 en `python-dotenv` 1.0.0, plus resterende Starlette
  advisories.
- Opmerking: een eerste testcommando vanuit de verkeerde gedeelde werkdirectory gaf
  ten onrechte `no tests ran`; dit is gecorrigeerd door de tests expliciet vanuit MW
  uit te voeren. Er is geen apt-installatie uitgevoerd.
- Exacte volgende stap: de overige MW-packages afzonderlijk prioriteren, te beginnen
  met `cryptography`, PyJWT en Requests; Starlette 1.x apart beoordelen wegens mogelijk
  frameworkcompatibiliteitsrisico.

### 2026-08-28 - WG-04 MW crypto-, JWT-, HTTP- en database-update

- Status: update en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `MW/requirements.txt`.
- Updates: PyMySQL `1.1.0` naar `1.1.1`, `cryptography` `41.0.7` naar `49.0.0`,
  PyJWT `2.8.0` naar `2.13.0` en Requests `2.31.0` naar `2.33.0`.
- Installatie: geslaagd in de lokale Python 3.12.3-venv.
- `pip check`: geslaagd.
- MW-tests: `85 passed`, 15 deprecation warnings.
- Audit na update: 32 bekende kwetsbaarheden in 5 packages volgens audit van
  `requirements.txt`.
- Resterend: Starlette `0.49.3`, Pillow `10.2.0`, `python-dotenv` `1.0.0` en pytest
  `9.0.2`; cryptography heeft nog één advisory met fix vanaf `50.0.0`.
- Exacte volgende stap: Pillow en `python-dotenv` afzonderlijk beoordelen en upgraden;
  daarna Starlette 1.x en de resterende frameworkrisico's apart plannen.

### 2026-08-28 - WG-05 MW Pillow- en dotenv-update

- Status: update en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `MW/requirements.txt`.
- Updates: Pillow `10.2.0` naar `12.3.0` en `python-dotenv` `1.0.0` naar `1.2.2`.
- Installatie: geslaagd in de lokale Python 3.12.3-venv.
- Compatibility check: bestaande Pillow-aanroepen (`Image.open`, `Image.new`,
  `thumbnail` en `Image.Resampling.LANCZOS`) importeren en functioneren in de testset.
- `pip check`: geslaagd.
- MW-tests: `85 passed`, 15 deprecation warnings.
- Audit na update: 9 bekende kwetsbaarheden in 3 packages volgens audit van
  `requirements.txt`.
- Resterend: Starlette `0.49.3` met advisories waarvoor 1.0.1 tot 1.3.1 wordt gemeld,
  cryptography `49.0.0` met één advisory waarvoor 50.0.0 wordt gemeld, en pytest
  `9.0.2` met één test-only advisory waarvoor 9.0.3 wordt gemeld.
- Exacte volgende stap: pytest als test-only package bijwerken en daarna bepalen of
  cryptography `50.0.0` compatibel is; Starlette 1.x blijft een afzonderlijke frameworkgroep.

### 2026-08-28 - WG-07 Starlette 1.x-migratie

- Status: frameworkmigratie en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Updates: FastAPI `0.120.4` naar `0.141.1` en Starlette `0.49.3` naar `1.6.0`.
- Installatie: geslaagd in de lokale Python 3.12.3-venv.
- `pip check`: geslaagd.
- MW-tests: `85 passed`, 16 warnings.
- Security-audit: `pip-audit -r requirements.txt` meldt geen bekende kwetsbaarheden.
- Compatibility: auth, middleware, uploads, responses, TestClient en overige MW-tests
  functioneren zonder testfailure.
- Resterende waarschuwing: Starlette meldt dat gebruik van httpx met `starlette.testclient`
  deprecated is en adviseert `httpx2`; dit wordt als aparte testtoolinggroep beoordeeld.
- Exacte volgende stap: de huidige MW-securitywijzigingen reviewen en daarna committen/pushen
  na expliciete toestemming, of eerst de httpx2-testtooling afzonderlijk onderzoeken.

### 2026-08-28 - WG-08 httpx2 read-only beoordeling

- Status: read-only onderzoek afgerond; geen requirements- of broncodewijzigingen.
- Repository: MW.
- Huidige situatie: `httpx` `0.25.2` staat in `requirements.txt`; `httpx2` is niet
  geinstalleerd.
- Starlette `1.6.0` importeert bij voorkeur `httpx2` en geeft bij fallback naar `httpx`
  een deprecation warning. `httpx2` `2.12.0` is beschikbaar en gebruikt `httpcore2`
  `2.12.0`, `anyio >=4.10`, `truststore >=0.10` en `idna >=3.18`.
- Gebruik in MW: uitsluitend `test_main.py` en `test_marriage.py` gebruiken
  `fastapi.testclient.TestClient`; productiecode gebruikt Requests voor uitgaande HTTP.
- Advies: vervang in een afzonderlijke testtoolinggroep `httpx==0.25.2` door
  `httpx2==2.12.0`, draai de twee TestClient-testbestanden en daarna de volledige
  MW-testset. Houd de wijziging test-only en controleer daarna opnieuw `pip check`.
- Open risico: `httpx2` is een aparte major package-lijn; eerst compatibiliteit testen
  voordat deze definitief in `requirements.txt` wordt opgenomen.
- Exacte volgende stap: expliciete toestemming vragen voor de httpx2-testtoolingupdate;
  daarna pas installeren, testen en het auditresultaat controleren.

### 2026-08-28 - WG-08 httpx2-testtoolingupdate

- Status: update en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `MW/requirements.txt`.
- Update: `httpx` `0.25.2` vervangen door `httpx2` `2.12.0`; de bijbehorende
  `httpcore2`, `truststore`, AnyIO- en IDNA-dependencies zijn geinstalleerd.
- Doel: Starlette 1.6.0 gebruikt nu zijn voorkeursclient `httpx2`; de fallback-
  deprecation warning voor gewoon `httpx` is verdwenen.
- Gerichte TestClient-tests: `test_main.py` en `test_marriage.py`, `56 passed`.
- Volledige MW-tests: `85 passed`.
- `pip check`: geslaagd.
- Security-audit: `pip-audit -r requirements.txt` meldt geen bekende kwetsbaarheden.
- Resterende waarschuwing: Starlette meldt een aparte deprecation voor per-request
  cookies in `test_marriage.py`; dit is geen failure en staat los van httpx2.
- Exacte volgende stap: de volledige MW-securitywijziging reviewen en daarna committen
  en pushen na expliciete toestemming. Daarna kan BE worden beoordeeld (`mariadb:latest`).

### 2026-08-28 - WG-06 MW cryptography- en pytest-update

- Status: update en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: MW.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `MW/requirements.txt`.
- Updates: `cryptography` `49.0.0` naar `50.0.0` en pytest `9.0.2` naar `9.0.3`.
- Installatie: geslaagd in de lokale Python 3.12.3-venv.
- `pip check`: geslaagd.
- MW-tests: `85 passed`, 15 deprecation warnings.
- Audit na update: 7 bekende kwetsbaarheden in alleen Starlette `0.49.3` volgens audit
  van `requirements.txt`; cryptography en pytest rapporteren geen advisories meer.
- Exacte volgende stap: Starlette 1.x-migratie afzonderlijk beoordelen. Dit is de laatste
  resterende dependencygroep in MW en heeft mogelijk FastAPI-compatibiliteits- en
  frameworkgedragsrisico's.

## Hervatten na onderbreking

Lees eerst dit document volledig en controleer daarna:

1. de laatste logsectie;
2. de actuele branch en working tree van de genoemde repository;
3. de laatst vastgelegde starting commit;
4. of de genoemde audit- en testresultaten nog reproduceerbaar zijn;
5. de exacte volgende stap uit het log.

Ga pas verder met wijzigen nadat de werkboom en branchstatus zijn vastgelegd.
