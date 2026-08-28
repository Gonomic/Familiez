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

### 2026-08-28 - WG-09 BE MariaDB read-only audit

- Status: read-only BE-audit afgerond; geen Dockerfile-, SQL- of composewijzigingen.
- Repository: BE.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Working tree: schoon.
- Productie- en root Compose-configuratie gebruiken al `mariadb:10.6`.
- `BE/dockerfile` gebruikt nog `FROM mariadb:latest`; deze tag is niet reproduceerbaar
  en maakt securitypatches en regressies moeilijk aan een specifieke imageversie te koppelen.
- `BE/dockerfile` bevat daarnaast een vermoedelijke buildblokkade: de `COPY`-regel verwijst
  naar `StructureDataSprocsSprocsAndFuncs27012020.sql`, terwijl de repositorybestanden
  `StructureDataSprocsAndFuncs27012020.sql` en `StructureDataSprocsAndFuncs01022020.sql`
  bevatten.
- Lokale Docker-image: `mariadb:10.6` aanwezig; `mariadb:latest` niet lokaal aanwezig.
- Remote manifestmetadata voor beide tags is beschikbaar; inhoudelijke CVE-scan kon niet
  worden uitgevoerd omdat Trivy en Docker Scout niet beschikbaar zijn.
- Advies: behandel het vervangen van `mariadb:latest` als een aparte BE-wijziging, kies
  een expliciete digest of beheerst gepinde MariaDB 10.6-tag, corrigeer de bestandsnaam
  alleen na bevestiging van de bedoelde init-SQL, en test daarna image-build,
  initialisatie, databaseverbinding en stored procedures.
- Exacte volgende stap: eerst de actuele MariaDB 10.6 patchtag/digest en gewenste init-
  SQL vastleggen; daarna pas Dockerfile wijzigen en een image-scan uitvoeren.

### 2026-08-28 - WG-09 BE Dockerfile-update en buildvalidatie

- Status: Dockerfile-update en lokale image-build afgerond; nog niet gecommit, gepusht
  of gedeployed.
- Repository: BE.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Gewijzigd bestand: `BE/dockerfile`.
- Updates: `mariadb:latest` naar `mariadb:10.6`, fout gespelde init-SQL-bestandsnaam
  gecorrigeerd naar `StructureDataSprocsAndFuncs27012020.sql`, initdirectory-aanmaak
  idempotent gemaakt met `mkdir -p`, en legacy `ENV LANG C.UTF-8` gewijzigd naar
  `ENV LANG=C.UTF-8`.
- Build: `docker build -f BE/dockerfile -t familiez-be:security-audit BE` geslaagd.
- Imagecontrole: image bevat de correcte init-SQL-copylaag en labelversie `10.6`.
- Eerste buildfout: MariaDB bevat `/docker-entrypoint-initdb.d` al; opgelost met `mkdir -p`.
- Scan: inhoudelijke CVE-scan niet uitgevoerd; Trivy en Docker Scout zijn niet beschikbaar.
- Exacte volgende stap: een image-scanner beschikbaar maken of elders uitvoeren, daarna
  database-initialisatie en stored-procedure-smoketests tegen deze image valideren.

### 2026-08-28 - WG-09 BE image-scan en initvalidatie

- Status: scan en geïsoleerde initvalidatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: BE.
- Branch: `feature/nieuwe-wijzigingen-2026-06-28`.
- Image: lokaal gebouwd als `familiez-be:security-audit` vanaf `mariadb:10.6`;
  runtime rapporteerde MariaDB `10.6.25-MariaDB-ubu2204`.
- Trivy: uitgevoerd via tijdelijke `aquasec/trivy:latest`-container met scanner `vuln`,
  severities CRITICAL/HIGH/MEDIUM en `--ignore-unfixed`.
- Trivy-resultaat: 1 CRITICAL, 25 HIGH en 135 MEDIUM findings; 118 in Ubuntu 22.04
  en 43 in de meegeleverde `gosu`-binary. Dit zijn OS-/imagecomponenten, niet de
  stored-procedures zelf.
- Runtime-initcheck: geslaagd tot en met databaseinitialisatie; officiële MariaDB-
  entrypoint start als dedicated `mysql`-gebruiker, voert
  `StructureDataSprocsAndFuncs27012020.sql` uit en meldt `MariaDB init process done`.
  De tijdelijke container is door `--rm`/timeout opgeruimd.
- Opgeloste Dockerfileproblemen tijdens validatie: bestaande initdirectory, foutieve
  SQL-doelmap, ontbrekende executable-bit, custom root-entrypoint en hardcoded custom
  entrypointgedrag zijn vervangen of verwijderd door gebruik van het officiële entrypoint.
- Open risico's: Trivy toont nog vaste OS-/gosu-kwetsbaarheden; `mariadb:10.6` is een
  tag en nog geen digest-pin. Stored-procedure-smoketest tegen een draaiende database
  met een echte applicatieverbinding is nog niet uitgevoerd.
- Exacte volgende stap: review van de volledige BE-Dockerfilediff en keuze tussen
  digest-pinning of de bestaande 10.6-tag; daarna pas eventuele stored-procedure-
  smoketest, commit en push na expliciete toestemming.

### 2026-08-28 - WG-10 BE hardcoded-secret onderzoek

- Status: read-only onderzoek afgerond; behalve het securitylog zijn geen nieuwe BE-
  bestanden gewijzigd.
- `BE/dockerfile` gebruikt het custom `BE/docker-entrypoint.sh` niet meer; de image
  gebruikt het officiële MariaDB-entrypoint.
- Het ongebruikte tracked bestand `BE/docker-entrypoint.sh` bevat nog hardcoded
  wachtwoordliteralen voor een oude rootcredential en healthcheckcredential, waaronder database-accounts
  en een root-account voor netwerktoegang. Dit is een repository-secret-risico, ook al
  wordt het bestand niet meer in de huidige image gekopieerd.
- `BE/init/00-remote-access.sql` gebruikt `${MYSQL_ROOT_PASSWORD}` als placeholder,
  maar moet alleen via een omgeving worden uitgevoerd die variabelen daadwerkelijk
  substitueert; dit is geen vervanging voor secretbeheer.
- Geen verwijzing naar het custom entrypoint gevonden in de actuele projectconfiguratie.
- Advies: verwijder `BE/docker-entrypoint.sh` uit Git na bevestiging dat er geen
  handmatige productieprocedure meer van afhankelijk is. Als de oude credential ooit echt
  is gebruikt, roteer die credentials buiten Git en beoordeel Git-history cleanup als
  afzonderlijke actie. Controleer daarna de overige init-SQL op echte secrets.
- Exacte volgende stap: toestemming vragen voor verwijderen van het ongebruikte custom
  entrypoint; daarna secret-scan van BE-initbestanden en Dockerfilediff afronden.

### 2026-08-28 - WG-10 aanvullende BE-secretbevinding

- Het ongebruikte `BE/docker-entrypoint.sh` is verwijderd uit de working tree; de
  actuele Dockerfile gebruikt het officiële MariaDB-entrypoint.
- Aanvullende controle vond in `BE/startgenbe.bat` nog een historische hardcoded
  rootcredential, gecombineerd met `mariadb:latest`.
- Dit script lijkt een oude handmatige Windows-ontwikkelstartprocedure. Het is niet
  onderdeel van de huidige Linux/Compose-runtime, maar de waarde moet als gelekt
  worden beschouwd als deze ooit echt is gebruikt; roteer die credential buiten Git.
- Advies: verwijder of herschrijf `startgenbe.bat` naar een placeholder-/`.env`-route
  en vervang `mariadb:latest` door `mariadb:10.6`, maar alleen na bevestiging dat de
  oude procedure niet meer nodig is.
- Open risico: oude Git-commits kunnen de waarde nog bevatten; history-cleanup is een
  afzonderlijke, potentieel verstorende actie.
- Exacte volgende stap: expliciete keuze vragen voor `startgenbe.bat` verwijderen of
  veilig herschrijven; daarna de BE-diff opnieuw bouwen, scannen en committen.

### 2026-08-28 - WG-10 BE legacy-secret cleanup

- Status: cleanup en validatie afgerond; nog niet gecommit, gepusht of gedeployed.
- Repository: BE.
- Verwijderd: `BE/docker-entrypoint.sh` en `BE/startgenbe.bat`.
- Reden: beide waren oude, niet door de huidige Dockerflow gebruikte scripts; ze
  bevatten hardcoded credentials of verwezen naar `mariadb:latest`.
- Secret/tag-scan van actuele BE-bestanden: geen oude hardcoded credentials,
  `mariadb:latest` of hardcoded `MARIADB_ROOT_PASSWORD=` gevonden.
- Docker-build na cleanup: geslaagd met `mariadb:10.6` en correcte init-SQL.
- Open risico: oude Git-commits kunnen de verwijderde credentials nog bevatten;
  history-cleanup en eventuele credentialrotatie blijven afzonderlijke acties.
- Exacte volgende stap: volledige BE-diff reviewen, eventueel bestaande echte
  credentials buiten Git roteren, en daarna BE plus dit securitylog committen/pushen
  na expliciete toestemming.

### 2026-08-28 - WG-09 upstream MariaDB-imagevergelijking

- Status: read-only vergelijking afgerond; geen Dockerfile- of imagewijzigingen.
- De officiële `mariadb:10.6`-image en de lokaal gebouwde `familiez-be:security-audit`
  hebben hetzelfde Trivy-profiel: 1 CRITICAL, 25 HIGH en 135 MEDIUM findings bij
  scan met `--ignore-unfixed`.
- De findings zitten in upstream-componenten: 118 in Ubuntu 22.04 en 43 in de
  meegeleverde `gosu`-binary. De eigen BE-laag voegt geen extra softwarepakket toe.
- Lokale image-digest: `mariadb@sha256:10fb7d1457175b9b8757389f32e429d5b8a7d624bae18975f48751927007e43d`.
  Een digest-pinning maakt builds reproduceerbaar, maar voorkomt niet dat de huidige
  digest zelf kwetsbare upstream-pakketten bevat.
- Advies: pin na keuze van de gewenste MariaDB-patchrelease op een digest en plan
  periodieke image-refreshes. Een overstap naar een andere MariaDB-major of wachten
  op upstream Ubuntu/gosu-refresh moet apart worden beoordeeld en getest.
- Open risico: de huidige officiële image bevat nog vaste OS-/gosu-findings; de
  Trivy-database kan bovendien toekomstige advisories toevoegen.
- Exacte volgende stap: kies expliciet tussen digest-pinning van de huidige 10.6-image
  of eerst een andere ondersteunde MariaDB-patch/major onderzoeken. Daarna kan de
  huidige BE-Dockerfilewijziging worden afgerond.

### 2026-08-28 - WG-11 credentialstatus bevestigd

- Status: security-incidentactie vereist; nog geen credentialrotatie of productieactie
  uitgevoerd.
- De gebruiker heeft bevestigd dat de oude credentials uit de verwijderde BE-scripts
  ooit actief zijn geweest.
- Betrokken oude root-, healthcheck- en ontwikkelcredentials worden vanaf nu als
  gecompromitteerd beschouwd en mogen niet opnieuw worden gebruikt.
- Prioriteit: roteer eerst de actieve MariaDB-root-, applicatie- en eventuele
  healthcheckcredentials buiten Git. Controleer daarna bestaande deployments,
  configuraties, volumes en logs op gebruik van de oude waarden.
- Daarna: revoke/verwijder oude databaseaccounts waar mogelijk, voer een gecontroleerde
  databaseverbindingstest uit en controleer MW/Compose/Synology-configuratie.
- Git-history cleanup: pas na rotatie beoordelen en plannen; history cleanup alleen
  uitvoeren met een expliciet plan voor bestaande clones, branches en remote refs.
- Secrets: nieuwe waarden uitsluitend via secretbeheer of niet-getrackte
  omgevingsconfiguratie doorgeven; nooit in dit log of in commando-output opnemen.
- Exacte volgende stap: actieve productie- en ontwikkelomgevingen inventariseren en
  vastleggen welke accounts met de oude credentials bestaan; daarna afzonderlijke
  toestemming vragen voor rotatie per omgeving.

### 2026-08-28 - WG-11 lokale en Synology-configuratiecontrole

- Status: configuratiecontrole afgerond; geen credentials getoond, gelogd of gewijzigd.
- Lokale secretbestanden `.env`, `.env.prod` en `Deploy/synology/deploy.env` zijn op
  mode `600` gezet.
- Lokale databasewachtwoorden verschillen van de drie oude waarden en zijn onderling
  gelijk voor de gecontroleerde applicatie-/productiewaarden.
- De Synology remote Compose-directory bevat een `.env` met aanwezige
  `DB_PASSWORD` en `DB_ROOT_PASSWORD`.
- Remote Compose gebruikt `MYSQL_PASSWORD: ${DB_PASSWORD}` en
  `MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}`; geen oude waarden of `mariadb:latest`
  aangetroffen in de gecontroleerde remote Compose.
- Belangrijk verschil: remote `DB_PASSWORD` matcht niet met de lokale
  `Deploy/synology/deploy.env` `PROD_DB_PASSWORD` en dus ook niet met de lokale
  `.env.prod`-applicatiewaarde. De remote configuratie gebruikt dus een andere waarde
  dan de lokale deploytool verwacht.
- Gevolg: dit is geen bewijs dat de remote credential onveilig is, maar lokale
  `sync_db.py`- en deployacties kunnen met de huidige lokale `PROD_DB_PASSWORD`
  niet betrouwbaar tegen de Synology-database werken.
- Advies: niet blind een lokaal wachtwoord naar productie overschrijven. Eerst bepalen
  welke remote credential de actuele is, de lokale deployconfiguratie veilig daarmee
  synchroniseren of bewust roteren, en daarna een gecontroleerde verbindingstest doen.
- Open risico: lokale secretbestanden hebben geen Git-status, maar staan wel buiten Git;
  remote secretbestand en databasegebruikers zijn alleen op aanwezigheid/fingerprint
  gecontroleerd. Geen credentialwaarden in dit log opnemen.
- Exacte volgende stap: via een gecontroleerde remote DB-verbinding vaststellen of de
  remote `DB_PASSWORD` werkelijk werkt voor `HumansService`; daarna pas besluiten over
  synchronisatie of rotatie.

### 2026-08-28 - WG-11 PROD-credential synchronisatie en DB-check

- Status: lokale deployconfiguratie gesynchroniseerd en read-only DB-check geslaagd;
  geen productiegegevens of credentials gelogd.
- Actie 2: actuele remote `DB_PASSWORD` veilig via SSH opgehaald en uitsluitend lokaal
  als `PROD_DB_PASSWORD` opgeslagen in `Deploy/synology/deploy.env`.
- Lokale secretbescherming: `Deploy/synology/deploy.env` staat op mode `600`.
- Actie 3: `sync_db.py --check-only` uitgevoerd met de expliciete MW Python 3.12.3-venv;
  de ontbrekende/onbruikbare lokale `PYTHON_BIN`-variabele in `deploy.env` is omzeild
  zonder het bestand inhoudelijk te wijzigen.
- Databaseverbinding: DEV `127.0.0.1:3306/humans` en PROD `192.168.1.10:3306/humans`
  bereikbaar met de geconfigureerde databasegebruikers.
- Resultaat: `[DB] Structure already equal (DEV == PROD)`, exitcode `0`.
- Productieactie: geen containers gestopt of gestart; geen databasewijziging uitgevoerd.
- Open punt: `PYTHON_BIN` ontbreekt of is niet bruikbaar in het lokale echte `deploy.env`;
  de deploydocumentatie/template noemt deze variabele wel. Dit moet later consistent
  worden gemaakt, maar is geen credentialprobleem.
- Exacte volgende stap: controleer of de gewijzigde lokale deployconfiguratie en dit
  log gecommit moeten worden; daarna eventueel alleen de lokale `PYTHON_BIN`-configuratie
  corrigeren en een volledige deploy-preflight uitvoeren zonder productieactie.

### 2026-08-28 - WG-09 MariaDB 10.6 versus latest

- Status: read-only vergelijking afgerond; geen repositorywijzigingen.
- `mariadb:10.6`: MariaDB `10.6.25` op Ubuntu `22.04`; lokale imagegrootte ongeveer
  308.7 MB.
- `mariadb:latest`: MariaDB `12.3.3` op Ubuntu `24.04`; lokale imagegrootte ongeveer
  333.8 MB, dus ongeveer 25.1 MB (8.1%) groter dan 10.6.
- Trivy met dezelfde instellingen (`CRITICAL,HIGH,MEDIUM`, `--ignore-unfixed`):
  - 10.6: 1 CRITICAL, 25 HIGH, 135 MEDIUM.
  - latest: 1 CRITICAL, 21 HIGH, 63 MEDIUM.
- De resterende CRITICAL zit in de gedeelde `gosu`-component; `latest` is dus niet
  volledig vrij van securitybevindingen.
- Compatibiliteitsrisico: `latest` is een sprong van MariaDB 10.6 naar 12.3 en de
  onderliggende Ubuntu 22.04 naar 24.04. Daarnaast verandert de tag in de tijd.
- Advies: gebruik niet rechtstreeks `mariadb:latest`. Onderzoek eventueel MariaDB
  10.6 met de nieuwste patch/digest of plan een aparte MariaDB-majorupgrade met
  databasebackup, schema-/sproc-tests en rollbackplan. Pin de gekozen image daarna
  op digest.

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

### Uitgesteld plan - Git-history cleanup van oude credentials

- Status: alleen gepland; uitvoering expliciet uitgesteld.
- Doel: oude credentialwaarden uit bereikbare en relevante Git-history verwijderen,
  zonder nieuwe secrets in de repository of dit log op te nemen.
- Repositories: root `Familiez` en `BE`; controleer ook remote refs en eventuele
  gekoppelde branches voordat history wordt herschreven.
- Voorbereiding:
  1. Maak een volledige lokale backup/mirror van root en BE, inclusief alle refs.
  2. Inventariseer alle branches, tags, remote refs en pull requests die geraakt worden.
  3. Bevestig dat de actuele configuraties nieuwe credentials gebruiken.
  4. Roteer of revoke oude actieve credentials eerst; history cleanup vervangt geen rotatie.
  5. Zoek opnieuw in alle bereikbare en onbereikbare lokale objects en leg alleen
     aantallen, commit-ID's en paden vast.
- Uitvoering, later en afzonderlijk goed te keuren:
  1. Herschrijf de history met een geschikt hulpmiddel zoals `git filter-repo`.
  2. Controleer de nieuwe refs en scan de resultaatrepositories opnieuw.
  3. Verwijder of expire oude remote refs volgens GitHub-procedure.
  4. Force-push alleen na expliciete toestemming en afgestemde onderhoudsperiode.
- Nazorg:
  - Laat bestaande clones opnieuw clonen of gecontroleerd synchroniseren.
  - Controleer alle actieve branches, tags, forks, releases en caches waar relevant.
  - Voer GitHub secret scanning opnieuw uit.
  - Controleer database-, deploy- en Synology-logs op gebruik van de oude credentials.
- Stopcriteria: stop onmiddellijk bij onverwachte refs, actieve afhankelijkheden,
  ontbrekende backups, onduidelijke credentialstatus of een history-tool die meer
  bestanden/branches zou wijzigen dan geïnventariseerd.
- Exacte hervatstap: begin met een read-only inventaris van refs en betrokken commits;
  voer geen history rewrite, force-push of productieactie uit zonder nieuwe toestemming.

## Hervatten na onderbreking

Lees eerst dit document volledig en controleer daarna:

1. de laatste logsectie;
2. de actuele branch en working tree van de genoemde repository;
3. de laatst vastgelegde starting commit;
4. of de genoemde audit- en testresultaten nog reproduceerbaar zijn;
5. de exacte volgende stap uit het log.

Ga pas verder met wijzigen nadat de werkboom en branchstatus zijn vastgelegd.
