# Instructie voor deploy Familiez

Deze instructie beschrijft hoe je een groep wijzigingen vanuit DEV gecontroleerd naar PROD/Synology brengt.

De instructie volgt:

- `Ontwerp_nieuw_versie_systeem-Familiez.md`;
- `ontwerp_nieuw_deploy-Familiez.md`;
- `Implementatieplan_nieuw_versie_systeem_Familiez.md`;
- de werkwijze die tijdens de release van 2026-09-18 daadwerkelijk is gevalideerd.

De productieomgeving is de Synology. DEV is de lokale Docker/MariaDB-omgeving op de Mint-devmachine.

## Belangrijkste regels

- Productieacties altijd per substap uitvoeren en vooraf expliciet goedkeuren.
- Secrets nooit in Git, chat, command-output of commitberichten zetten.
- De officiele rollbackbron is `Backup/<ReleaseId>/`, niet de oude map `voorgaande_versie`.
- `voorgaande_versie` is historische legacy en valt buiten de nieuwe methodiek. Deze map wordt niet door de nieuwe deployflow verwijderd.
- Gebruik geen `git push --force` en verwijder featurebranches niet automatisch.
- Gebruik voor databases niet blind de algemene `sync_db.py` wanneer DEV en PROD verschillende versioningfasen hebben.
- `sync_db.py` is bedoeld voor structuur en routines. Releasegegevens gaan via de release bundle en de key-gebaseerde stored procedures.
- FE/MW mogen pas worden vervangen nadat backup, bundle, metadata en staging zijn gevalideerd.
- De PROD-versioningstructuur is eenmalig gemigreerd. Toekomstige releases migreren die structuur niet opnieuw.

## Overzicht van de releaseflow

```text
DEV-bronnen
  -> scanners en manifesten
  -> lokale release-orchestrator
  -> release-bundle.json
  -> compatibiliteitscontrole
  -> productiebackup BE/FE/MW
  -> release-metadata.json
  -> Synology Staging/<ReleaseId>/
  -> database versioning/import
  -> FE/MW publiceren
  -> gecontroleerde restart
  -> healthchecks en smoke test
```

## 1. Werkboom en branches controleren

Controleer eerst de vier repositories:

- `BE/`
- `MW/`
- `FE/`
- `Deploy/`

Controleer per repository:

```bash
git status --short --branch
git fetch origin --prune
```

De featurebranch voor dit systeem is:

```text
feature/familiez-versioning-system
```

De hoofdbranches zijn repositoryafhankelijk:

- BE gebruikt `master`;
- MW gebruikt `main`;
- FE gebruikt `main`;
- Deploy gebruikt `main`.

Werk alleen verder met een schone werkboom. Controleer expliciet dat geen `.env`, wachtwoordbestand, SSH-key of ander secret wordt toegevoegd.

## 2. DEV-bronnen wijzigen en testen

Werk in DEV aan de normale bronbestanden:

- BE: SQL-bronnen en stored procedures;
- MW: Python/FastAPI-bronnen;
- FE: React/Vite-bronnen.

Draai de normale tests van de gewijzigde componenten:

```bash
# MW
cd MW
source .venv/bin/activate
pytest

# FE
cd FE
npm test -- --run
npm run build

# Deploy/versioning
cd Deploy
../MW/.venv/bin/python -m unittest discover -s versioning -p 'test_*.py' -v
```

Draai daarnaast de versioning-scanners:

```bash
# MW
cd MW
python -m versioning.scan_mw_functions .

# BE
cd BE
python -m versioning.scan_be_functions .

# FE
cd FE
npm run scan:versioning
```

## 3. DEV-manifesten en release bundle maken

Gebruik de bestaande lokale orchestrator. Die bouwt de componentmanifesten, registry, stackmanifest en release bundle.

Voor een lokale dry-run:

```bash
cd Deploy
../MW/.venv/bin/python -m versioning.run_local_release \
  --root .. \
  --dry-run
```

Voor een DEV-run met lokale database-sync/publicatie, alleen na expliciete toestemming:

```bash
cd Deploy
../MW/.venv/bin/python -m versioning.run_local_release \
  --root .. \
  --database \
  --bundle-output versioning/release-bundle.json \
  --release-key release:<ReleaseId>
```

Controleer daarna minimaal:

- `FE/versioning/manifest.json` bestaat;
- `MW/versioning/manifest.json` bestaat;
- `BE/versioning/manifest.json` bestaat;
- `Deploy/versioning/registry.json` bestaat;
- `Deploy/versioning/stack-manifest.json` bestaat;
- `Deploy/versioning/release-bundle.json` bestaat;
- alle componenten zijn `FE`, `MW`, `DB`;
- `compatibilityCheck` is `passed`;
- de bundle-checksum is geldig;
- `releaseKey` bij de gekozen `ReleaseId` hoort;
- oude ID-velden zoals `FunctionID`, `DependencyID`, `CallerFunctionID` en `CalleeFunctionID` ontbreken.

De `ReleaseId` is de identiteit van de volledige promotie. Gebruik dezelfde waarde voor databasebackup, FE-backup, MW-backup, staging, metadata en rollback.

## 4. PROD-versioningstructuur controleren

De nieuwe PROD-versioningstructuur bestaat uit:

- `function_registry`;
- `function_dependencies`;
- `function_registry_audit`;
- `component_manifests`;
- `stack_manifests`;
- de key-gebaseerde registry-, capabilities-, manifest- en stackprocedures.

Bij een oudere PROD-database kan deze structuur ontbreken. Voer dan niet blind de algemene `sync_db.py` uit. Tijdens de eerste promotie moet je de gerichte versioningmigratie gebruiken:

1. nieuwe versioningtabellen en constraints;
2. `UpdateFunctionRegistry`, `AddFunctionDependency` en `GetFunctionCapabilities`;
3. `RegisterComponentManifest` en `PublishStackManifest`;
4. `GetActiveStackManifest` en `GetActiveStackBuildNumber`;
5. read-only validatie.

Laat de legacy release-tabellen en `GetReleasesByComponent` staan zolang daar geen aparte goedgekeurde cleanup voor is.

De 49 algemene routineverschillen uit de eerste DEV/PROD-vergelijking mogen niet automatisch worden overschreven. Beoordeel die afzonderlijk.

## 5. Productiebackup maken

Maak eerst een unieke `ReleaseId`, bijvoorbeeld:

```text
20260918_164519
```

De centrale Synologystructuur is:

```text
/volume1/docker/familiez/
├── Backup/
│   └── <ReleaseId>/
│       ├── BE/
│       ├── FE/
│       ├── MW/
│       └── release-metadata.json
└── Staging/
    └── <ReleaseId>/
        ├── FE/
        └── MW/
```

### BE/databasebackup

Gebruik een backupaccount met alleen de benodigde dumprechten, bijvoorbeeld `FamiliezBackup`. Gebruik een willekeurig wachtwoord dat lokaal in een bestand met mode `600` staat. Zet het wachtwoord nooit in argv of output.

De dump bevat minimaal:

- schema;
- data;
- procedures en functies;
- triggers;
- events.

De dump moet lokaal worden gevalideerd op:

- bestand bestaat en is niet leeg;
- database-identificatie aanwezig;
- checksum gemaakt en opnieuw gecontroleerd;
- metadata aanwezig;
- routine-export geslaagd.

Upload daarna:

```text
Backup/<ReleaseId>/BE/<database>_<ReleaseId>.sql
Backup/<ReleaseId>/BE/<database>_<ReleaseId>.sql.sha256
Backup/<ReleaseId>/BE/metadata.json
```

Controleer remote dat alle bestanden bestaan, niet leeg zijn en dat de remote SHA-256 gelijk is aan de lokale checksum.

### FE- en MW-backup

Backup de huidige productie-builds, dus niet de nieuwe DEV-bronnen:

```text
Backup/<ReleaseId>/FE/
Backup/<ReleaseId>/MW/
```

Vergelijk de actuele rootinhoud zonder:

- `voorgaande_versie`;
- `metadata.json`;
- andere historische deploymentmappen.

De backup is pas betrouwbaar als de actuele productie-root en backup-root dezelfde relatieve bestanden en hashes hebben.

## 6. Centrale release-metadata

Bouw daarna `release-metadata.json` met:

- `ReleaseId`;
- stack build;
- componentversies en source commits;
- backupstatus voor BE, FE en MW;
- checksums;
- `compatibilityCheck`;
- rollbackstatus.

De metadata moet aangeven:

```json
{
  "status": "validated",
  "compatibilityCheck": "passed",
  "rollback": {
    "available": true,
    "databaseRestoreRequiresConfirmation": true,
    "dropDatabaseAllowed": false
  }
}
```

Upload de metadata naar de root van dezelfde releasebackup:

```text
Backup/<ReleaseId>/release-metadata.json
```

## 7. PROD release-data importeren

Nadat de PROD-versioningtabellen en procedures aanwezig zijn, importeer je de DEV-release bundle:

```bash
cd Deploy
DEV_DB_HOST=<prod-host> \
DEV_DB_PORT=<prod-port> \
DEV_DB_USER=<prod-user> \
DEV_DB_PASSWORD=<prod-password> \
DEV_DB_NAME=<prod-database> \
  ../MW/.venv/bin/python -m versioning.import_release_data \
  versioning/release-bundle.json \
  --database
```

Het wachtwoord mag niet in het commando of in logs staan. Gebruik waar nodig een lokale env-injectie zonder `.env` als shellscript te sourcen.

De importer doet in vaste volgorde:

1. functies op `FunctionKey`;
2. dependencies op `DependencyKey`;
3. FE/MW/DB-componentmanifesten;
4. het compatibele stackmanifest als laatste.

Controleer read-only:

- precies één actieve stack;
- `CompatibilityStatus = passed`;
- verwacht stack buildnummer;
- verwacht aantal functies en dependencies;
- componentmanifesten aanwezig;
- capabilities levert geldige JSON.

## 8. FE/MW-staging vullen

Maak staging zichtbaar op rootniveau van de Synology:

```text
/volume1/docker/familiez/Staging/<ReleaseId>/FE/
/volume1/docker/familiez/Staging/<ReleaseId>/MW/
```

FE-staging bevat:

- de actuele FE `dist`-inhoud;
- `nginx.conf` als de productiecompose die nodig heeft.

MW-staging bevat de runtimebron, maar sluit uit:

```text
.git
.venv
__pycache__
BESTANDEN
.pytest_cache
.mypy_cache
.ruff_cache
.github
.vscode
voorgaande_versie
```

Controleer na kopiëren:

- bestandstelling;
- totale grootte;
- relatieve bestanden;
- SHA-256-hashes tegen de lokale stagingbron.

## 9. FE/MW-publicatie

Publiceer pas nadat backup en staging volledig gecontroleerd zijn.

Gebruik de nieuwe expliciete stagingmethode:

1. controleer `Backup/<ReleaseId>/` opnieuw;
2. controleer `Staging/<ReleaseId>/` opnieuw;
3. negeer `voorgaande_versie` volledig;
4. kopieer FE en MW per component vanuit staging naar de actieve rootmappen;
5. vergelijk de actieve rootinhoud met staging op relatieve bestanden en hashes;
6. bij fout: herstel de betreffende component vanuit `Backup/<ReleaseId>/FE|MW/`;
7. markeer de publicatie pas als geslaagd wanneer beide componenten matchen.

De actieve buildmappen zijn in deze omgeving:

```text
/volume1/docker/familiez/FE-build
/volume1/docker/familiez/MW-build
```

Let op: `nginx.conf` hoort bij de FE-publicatie. Oude `voorgaande_versie`-mappen worden niet door deze nieuwe flow verwijderd.

## 10. Container-restart

Restart pas nadat FE/MW-publicatie en hashcontrole geslaagd zijn.

Herstart in principe alleen de gewijzigde applicatieservices, tenzij de release expliciet anders vereist:

```bash
docker compose -f docker-compose.yml -p familiez-prod restart mw fe
```

MariaDB blijft bij een gewone FE/MW-release draaien.

Bij een restartfout:

1. stop verdere releaseacties;
2. herstel FE/MW vanuit `Backup/<ReleaseId>/`;
3. start de vorige applicatiestate opnieuw;
4. voer healthchecks opnieuw uit;
5. database-restore alleen na expliciete operationele bevestiging.

## 11. Healthchecks en smoke test

Controleer minimaal:

- MariaDB-container actief en healthy;
- MW-container actief;
- FE-container actief;
- MW root endpoint HTTP 200;
- `/versioning/stack-build` HTTP 200 met het verwachte buildnummer;
- `/capabilities` HTTP 200 na login/authenticatie;
- FE health URL HTTP 200;
- MW health URL HTTP 200.

Handmatige smoke test:

1. log in op Familiez;
2. open `Familiez info` / Release Dashboard;
3. controleer stack build;
4. controleer compatibiliteit `passed`;
5. controleer FE/MW/DB-componenten;
6. controleer functies en dependencies;
7. voer één bestaande leesactie uit.

Een HTTP 401 op `/capabilities` zonder login is verwacht. Een HTTP 422 op `/pingAPI` zonder verplichte parameter is eveneens verwachte validatie.

## 12. Rollback

De officiële rollbackbron is:

```text
Backup/<ReleaseId>/BE/
Backup/<ReleaseId>/FE/
Backup/<ReleaseId>/MW/
```

FE/MW rollback:

- herstel alleen de actuele rootbestanden;
- laat `voorgaande_versie` buiten scope;
- controleer hashes na herstel;
- herstart daarna de applicatieservices.

Database rollback:

- vereist expliciete bevestiging;
- valideer backup en checksum opnieuw;
- stop relevante services gecontroleerd;
- gebruik geen ongecontroleerde `DROP DATABASE`;
- valideer database en applicatie na restore.

## 13. Git, PR en merge

Commit pas nadat de release functioneel is getest.

Gebruik Conventional Commits. Voorbeelden:

```text
feat: add controlled production release flow
docs: close release implementation log
```

Push de featurebranch eerst. Maak daarna per repository een PR naar de juiste hoofdbranch:

- BE: `feature/familiez-versioning-system` -> `master`;
- MW: `feature/familiez-versioning-system` -> `main`;
- FE: `feature/familiez-versioning-system` -> `main`;
- Deploy: `feature/familiez-versioning-system` -> `main`.

Merge pas na review en statuschecks. Featurebranches mogen blijven bestaan als historische release- en rollbackreferentie. Verwijderen is niet verplicht.

## 14. Wat niet doen

- Niet rechtstreeks naar productie deployen zonder backup en preflight.
- Niet `sync_db.py` blind gebruiken wanneer DEV en PROD verschillende versioningfasen hebben.
- Niet de oude release-tabellen verwijderen zonder aparte goedkeuring.
- Niet alle 49 algemene routineverschillen automatisch overschrijven.
- Niet `.env`, wachtwoorden, tokens of SSH-keys committen.
- Niet `.github`, `.vscode`, `.git`, `.venv`, caches of `BESTANDEN` naar MW-runtime kopiëren.
- Niet `voorgaande_versie` behandelen als officiële nieuwe rollbackbron.
- Niet `DROP DATABASE` gebruiken als standaardrollback.
- Niet restarten voordat staging, backup en hashes kloppen.

## 15. Opruimen en release afronden

Leg in het implementatieplan vast:

- ReleaseId;
- gewijzigde componenten;
- backupstatus en checksums;
- databaseversioning/importstatus;
- FE/MW-publicatiestatus;
- restart- en healthcheckresultaat;
- smoke-testresultaat;
- rollbackstatus;
- commit- en PR-nummers.

Bewaar `Backup/<ReleaseId>/` totdat de release stabiel is en de afgesproken bewaartermijn verstreken is. Verwijder oude `voorgaande_versie`-mappen later als aparte handmatige opruimactie.

## 16. Releasecommando’s vanuit VS Code

De samengestelde dispatcher staat in:

```text
Deploy/synology/familiez_release.sh
```

Start hem vanuit de workspace-root:

```bash
cd /home/frans/Documenten/Dev/Familiez
```

Veilige lokale commando’s:

```bash
./Deploy/synology/familiez_release.sh preflight
./Deploy/synology/familiez_release.sh prepare
./Deploy/synology/familiez_release.sh test
```

Deze commando’s gebruiken bestaande onderdelen:

- `preflight` valideert de bestaande bundle en het bundlecontract;
- `prepare` roept `versioning.run_local_release --dry-run` aan;
- `test` draait de bestaande Deploy-versioning-, backup-, restore- en metadata-tests.

Productiecommando’s hebben bewust een expliciete bevestigingsvlag:

```bash
./Deploy/synology/familiez_release.sh import --confirm-prod
./Deploy/synology/familiez_release.sh deploy --confirm-prod
./Deploy/synology/familiez_release.sh rollback --confirm-prod <ReleaseId>
```

De dispatcher implementeert de versioningmigratie niet opnieuw. De eenmalige PROD-migratie is al uitgevoerd. `import` gebruikt de bestaande `import_release_data.py`; `deploy` gebruikt de bestaande `deploy_to_synology.sh`; `rollback` gebruikt `rollback_on_synology.sh`.

De dispatcher is bewust geen vervanging voor review en expliciete substapgoedkeuring. Controleer vóór een productiecommando altijd backup, ReleaseId, bundle, staging en metadata.

### Praktisch gebruik per release

Gebruik de dispatcher vanuit de root van de Familiez-workspace. Maak het script niet aan vanuit `FE/`, `MW/` of `Deploy/`; de paden zijn vanuit de workspace-root bedoeld.

#### 1. Lokale controle

Start hiermee na wijzigingen:

```bash
cd /home/frans/Documenten/Dev/Familiez
./Deploy/synology/familiez_release.sh preflight
```

De preflight wijzigt niets. Bij `validated` zijn de bestaande release-artifacts en bundle contractueel geldig.

#### 2. Nieuwe DEV-release voorbereiden

Maak eerst een lokale dry-run:

```bash
./Deploy/synology/familiez_release.sh prepare
```

Daarna draai je de tests:

```bash
./Deploy/synology/familiez_release.sh test
```

Pas wanneer tests en bundlecontrole goed zijn, bepaal je de ReleaseId en voer je de backup-/promotiestappen uit volgens de hoofdstukken hierboven.

#### 3. Productie-import en deployment

Deze commando’s zijn productiemutaties. Voer ze alleen uit na afzonderlijke goedkeuring en nadat `Backup/<ReleaseId>/` en `Staging/<ReleaseId>/` zijn gecontroleerd:

```bash
./Deploy/synology/familiez_release.sh import --confirm-prod
./Deploy/synology/familiez_release.sh deploy --confirm-prod
```

`import` vult PROD met de al bestaande versioningstructuur en releasegegevens. Het migreert de versioningtabellen niet opnieuw.

`deploy` gebruikt de bestaande Synology-deployorchestrator. Controleer na afloop de restart, healthchecks en het Release Dashboard.

#### 4. Rollback

Gebruik bij een bevestigde FE/MW-fout het exacte ReleaseId van de release:

```bash
./Deploy/synology/familiez_release.sh rollback --confirm-prod 20260918_164519
```

Een database-restore gebeurt niet automatisch. Daarvoor is een aparte operationele bevestiging en restoreprocedure nodig.

#### 5. Hulp en foutafhandeling

Bekijk de beschikbare commando’s met:

```bash
./Deploy/synology/familiez_release.sh --help
```

De dispatcher stopt bij een fout. Ga niet meteen opnieuw draaien; noteer eerst de fase, ReleaseId en foutcategorie in het implementatieplan. Controleer daarna of de officiële backup intact is.
