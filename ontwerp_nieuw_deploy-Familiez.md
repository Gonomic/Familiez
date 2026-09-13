# Ontwerp nieuw deployment- en rollback-systeem Familiez

Dit document beschrijft het ontwerp voor een gecontroleerde productie-uitrol van Familiez naar de Synology NAS, inclusief volledige MariaDB-backup, backupvalidatie, FE/MW-backups, database-sync, databasevalidatie, FE/MW-deployment, smoke tests en een gecontroleerde rollbackbeslissing.

Dit is een ontwerp- en uitvoeringsplan. Het document voert zelf geen deployment, databasewijziging, SSH-actie of credentialrotatie uit.

## Doel

Een release moet als een herkenbare stack worden behandeld:

```text
FE + MW + DB + stack-manifest + databasebackup
```

Iedere release krijgt een unieke `ReleaseId`, bijvoorbeeld:

```text
20260913_153000
```

## Centrale backupstructuur op Synology

Alle release-backups worden centraal op de Synology opgeslagen onder de bestaande Familiez-deploymentmap:

```text
/volume1/docker/familiez/Backup/<ReleaseId>/
├── BE/
│   ├── humans_<ReleaseId>.sql
│   ├── humans_<ReleaseId>.sha256
│   └── metadata.json
├── MW/
│   ├── <MW-build-bestanden>
│   └── metadata.json
└── FE/
   ├── <FE-build-bestanden>
   └── metadata.json
```

Hierbij staat `BE` voor de database-backup die uit de BE/database-laag voortkomt. De mapnaam blijft `BE` omdat de bestaande repository- en deploymentconventie de databasebron als BE aanduidt; in de manifestlaag heet dezelfde component `DB`.

Dezelfde `ReleaseId` is verplicht voor de drie mappen. Een backup is pas compleet als `BE`, `MW` en `FE` voor die release aanwezig en gevalideerd zijn. Optioneel kan in de release-root aanvullend een niet-geheim `release-metadata.json` worden opgeslagen met de ReleaseId, stack build, componentversies, checksums en status:

```text
/volume1/docker/familiez/Backup/<ReleaseId>/release-metadata.json
```

De centrale `Backup`-structuur is de enige backup- en rollbackbron. De mappen `FE-build/voorgaande_versie/` en `MW-build/voorgaande_versie/` maken geen onderdeel uit van het nieuwe ontwerp en worden niet gebruikt nadat dit ontwerp is geïmplementeerd.

Dezelfde `ReleaseId` wordt gebruikt voor:

- FE-backup in `Backup/<ReleaseId>/FE/`;
- MW-backup in `Backup/<ReleaseId>/MW/`;
- BE/databasebackup in `Backup/<ReleaseId>/BE/`;
- stack build en manifestregistratie;
- deploylog;
- rollbackselectie.

De deployment mag alleen doorgaan als de stack compatibel is, de BE/databasebackup valide is, de FE- en MW-backups succesvol zijn aangemaakt en beschikbaar zijn voor rollback, en de post-deployment smoke tests slagen.

## Uitgangspunten

- Productie is de Synology NAS; lokale ontwikkel- en testomgevingen worden niet als productie beschouwd.
- Er wordt geen productieactie uitgevoerd zonder afzonderlijke expliciete toestemming.
- Secrets blijven buiten Git en worden niet in logs of foutmeldingen afgedrukt.
- De bestaande deploy-gate blijft de eerste compatibiliteitsbarriere.
- Een mislukte backup blokkeert de deployment voordat `sync_db.py` wordt uitgevoerd.
- De databasefallback is een restore uit een gevalideerde backup, niet alleen een SQL `ROLLBACK`.
- FE, MW en DB worden als een samenhangende release behandeld.
- Rollback wordt handmatig bevestigd, tenzij later expliciet wordt besloten automatische rollback ook voor de database in te schakelen.

## Bestaande onderdelen die worden hergebruikt

### `Deploy/synology/deploy_to_synology.sh`

Blijft de hoofdorchestrator voor:

- configuratievalidatie;
- manifest- en compatibiliteitscontrole;
- FE-build;
- lokale staging;
- NAS SSH-preflight;
- FE/MW-upload;
- FE/MW-backup;
- containerrestart;
- healthchecks;
- bestaande FE/MW-rollback bij restart- of healthcheckfouten.

De volgorde wordt aangepast zodat databasebackup en FE/MW-backup op een veilige, gezamenlijke `ReleaseId` werken voordat productiegegevens worden gewijzigd.

### `Deploy/synology/sync_db.py`

Blijft verantwoordelijk voor:

- DEV/PROD-verbinding;
- structuurvergelijking;
- routinevergelijking;
- toevoegen van ontbrekende tabellen/kolommen;
- vervangen van routines;
- check-only-validatie.

`sync_db.py` wordt niet gebruikt als database-rollbackmechanisme. De backup/restorelaag komt eromheen.

`sync_db.py` draagt geen releasegegevens over. Het synchroniseert uitsluitend database-structuur en database-routines: tabellen, kolommen, procedures en functies. De volgende gegevens vallen nadrukkelijk buiten `sync_db.py`:

- `FunctionKey`- en functierelease-state;
- `DependencyKey`-relaties;
- componentmanifesten;
- het actieve stackmanifest;
- `ReleaseKey`- en stackreleasegegevens;
- auditgeschiedenis.

Deze releasegegevens worden vanuit de al gevalideerde DEV-release bundle afzonderlijk overgedragen door `import_release_data.py` in Fase 6a.

### `Deploy/synology/rollback_on_synology.sh`

Wordt uitgebreid of aangevuld zodat een rollback met dezelfde `ReleaseId` ook:

- FE herstelt;
- MW herstelt;
- databasebackup terugzet;
- containers opnieuw start;
- database- en applicatievalidatie uitvoert.

De bestaande handmatige timestamp-aanroep blijft bruikbaar zolang de nieuwe release-id daarmee verenigbaar blijft.

### Manifesten en deploy-gate

De bestaande controle met:

- FE-manifest;
- MW-manifest;
- DB-manifest;
- `registry.json`;
- `stack-manifest.json`;
- `compatibilityCheck: passed`;

blijft ongewijzigd de eerste inhoudelijke gate. De databasebackup wordt een extra release-artifact naast deze manifesten.

### Bestaande DEV-releaseketen

De bestaande lokale release-orchestrator blijft verantwoordelijk voor het opbouwen en registreren van de DEV-releasegegevens. Deze onderdelen worden niet opnieuw gebouwd:

- scanners;
- componentmanifesten;
- `registry.json`;
- `stack-manifest.json`;
- `UpdateFunctionRegistry`;
- `AddFunctionDependency`;
- `RegisterComponentManifest`;
- `PublishStackManifest`;
- lokale DEV-validatie.

De nieuwe deploymentuitbreiding begint pas nadat deze bestaande keten een gevalideerde DEV-release heeft opgeleverd.

## Gewenste releaseflow

### Fase 0: Release voorbereiden

De releaseflow mag pas starten nadat de DEV-only migratie uit Stap 15b is afgerond. Dat betekent dat `FunctionKey` en de overige expliciete keys leidend zijn en de oude interne ID-velden niet meer door de releaseflow worden gebruikt.

1. Controleer branches, commits en schone werkbomen.
2. Voer de bestaande DEV-releaseorchestrator uit; bouw de DEV-release niet opnieuw in de deploymentlaag.
3. Genereer FE-, MW- en DB-manifesten.
4. Genereer `registry.json` en `stack-manifest.json` met expliciete keys.
5. Controleer `compatibilityCheck: passed`.
6. Bepaal een unieke `ReleaseId` en `ReleaseKey`.
7. Leg componentversies, stack build, source commits en keys vast in een releasecontext.

Bij een fout stopt de flow zonder productiecontact.

### Fase 0a: DEV-releasegegevens exporteren

Na een geslaagde bestaande DEV-release-run worden de actuele releasegegevens gebundeld voor overdracht naar PROD. Dit is geen tweede registratiepipeline.

De bundle bevat alleen releasegegevens:

```text
release-bundle/<ReleaseId>/
├── release-bundle.json
├── release-bundle.sha256
└── metadata.json
```

De JSON bevat onder andere:

- `ReleaseId`;
- stack buildnummer;
- compatibiliteitsstatus;
- componentmanifesten;
- actuele functies en functieversies;
- dependencies;
- stackmanifest.

De bundle bevat geen `FunctionID`, `CallerFunctionID`, `CalleeFunctionID` of `DependencyID`, en bevat geen auditgeschiedenis tenzij daar later expliciet voor wordt gekozen.

De export wordt opgebouwd uit de al gevalideerde DEV-releasegegevens en niet door volledige DEV-tabellen naar PROD te kopiëren. De bundle wordt vóór productie-import gecontroleerd op JSON-geldigheid, checksum, componenten, dependencies en afwezigheid van secrets.

### Fase 1: Lokale preflight

Controleer lokaal:

- benodigde commando's: `ssh`, `rsync`, `npm`, Python, MariaDB-client of dump-tool;
- aanwezigheid van productieconfiguratie zonder waarden te loggen;
- aanwezigheid van alle manifesten;
- aanwezigheid van FE-buildconfiguratie;
- beschikbare lokale stagingruimte;
- geldige deploy-gate;
- geldige `ReleaseId`.

### Fase 2: NAS- en opslagpreflight

Controleer vóór databasewijzigingen:

- SSH-poort bereikbaar;
- productiecompose-bestand aanwezig;
- productieproject bereikbaar;
- `mysql-data`/MariaDB-container aanwezig;
- FE-build- en MW-buildmappen aanwezig;
- `/volume1/docker/familiez/Backup/` aanwezig of veilig aan te maken;
- voldoende vrije opslag voor:
  - databasebackup;
  - FE-backup;
  - MW-backup;
  - tijdelijke staging;
  - ten minste één oudere rollbackversie.

Bij onvoldoende opslag stopt de flow.

### Fase 3: BE/databasebackup maken

Maak vóór `sync_db.py` een volledige MariaDB-backup met onder andere:

- schema;
- data;
- routines;
- functies;
- triggers;
- events, indien aanwezig;
- relevante database-objecten.

Voorkeursvorm:

```bash
mariadb-dump \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  humans > humans_<ReleaseId>.sql
```

De uiteindelijke opties moeten worden afgestemd op de feitelijke MariaDB-versie en tabelengines. Omdat bestaande tabellen MyISAM kunnen bevatten, moet worden gecontroleerd of een consistente backup aanvullende locking of een korte databasepauze nodig heeft.

De backup wordt opgeslagen in de centrale releasebackupstructuur:

```text
/volume1/docker/familiez/Backup/<ReleaseId>/BE/humans_<ReleaseId>.sql
/volume1/docker/familiez/Backup/<ReleaseId>/BE/humans_<ReleaseId>.sha256
/volume1/docker/familiez/Backup/<ReleaseId>/BE/metadata.json
```

`metadata.json` bevat alleen niet-geheime metadata, zoals:

- `ReleaseId`;
- UTC-tijdstip;
- database-naam;
- stack build;
- componentversies;
- dump-tool en versie;
- bestandsgrootte;
- checksum;
- backupstatus.

### Fase 4: Databasebackup valideren (backup validation)

Een backup is pas geldig als minimaal het volgende slaagt:

1. bestand bestaat;
2. bestandsgrootte is groter dan nul;
3. checksum kan worden berekend;
4. checksum wordt direct opnieuw gecontroleerd;
5. dump bevat verwachte database-identificatie;
6. dump bevat verwachte versioning-objecten of de actuele objectinventaris;
7. dump is syntactisch leesbaar voor de beoogde restore-tool;
8. backupmetadata wordt opgeslagen;
9. de backup is niet alleen op het actieve databasevolume aanwezig.

Een volledige restoretest in een tijdelijke MariaDB-container wordt periodiek uitgevoerd. Niet elke productie-release hoeft een volledige restoretest te doen, maar een release mag niet worden vrijgegeven als de meest recente restoretest ongeldig is.

Bij backupvalidatiefout: deployment stoppen, geen `sync_db.py`, geen FE/MW-vervanging.

### Fase 5: FE/MW-backup maken en valideren

Gebruik dezelfde `ReleaseId` en de centrale `Backup`-structuur voor:

```text
/volume1/docker/familiez/Backup/<ReleaseId>/FE/
/volume1/docker/familiez/Backup/<ReleaseId>/MW/
```

De backup moet worden gemaakt voordat de bestaande buildmappen worden vervangen. Controleer:

- `Backup/<ReleaseId>/FE/` bestaat;
- `Backup/<ReleaseId>/MW/` bestaat;
- bestanden zijn leesbaar;
- backupmappen zijn niet leeg wanneer de bestaande deployment niet leeg was;
- ReleaseId is overal gelijk;
- FE/MW-metadata bevat minimaal component, ReleaseId, source/buildinformatie, timestamp, bestandstelling en status.

### Fase 6: DB-sync en databasewijzigingen

1. Voer `sync_db.py --check-only` uit.
2. Als DEV en PROD gelijk zijn, wijzig de database niet.
3. Als ze verschillen, voer de sync uit.
4. Log uitsluitend objectnamen en status, nooit wachtwoorden of volledige connectiestrings.
5. Stop bij iedere syncfout.

Omdat `sync_db.py` autocommit gebruikt, is een mislukte gedeeltelijke sync niet automatisch transactioneel herstelbaar. Daarom blijft de vooraf gemaakte backup noodzakelijk.

### Fase 6a: DEV-releasegegevens gecontroleerd naar PROD importeren

Na de structurele DB-sync en vóór FE/MW-publicatie wordt de gevalideerde release bundle naar PROD geïmporteerd.

De import past uitsluitend de al in DEV goedgekeurde gewenste toestand toe. PROD neemt geen nieuwe releasebeslissingen. De import gebruikt de bestaande registry- en manifest-sprocs, aangepast voor expliciete keys:

1. functies registreren/updaten via `UpdateFunctionRegistry` op basis van `FunctionKey`;
2. DEV-verwijderingen als de gewenste PROD-status `removed` toepassen;
3. dependencies toevoegen via `DependencyKey`, `CallerFunctionKey` en `CalleeFunctionKey`;
4. componentmanifesten registreren via `ComponentManifestKey` en `RegisterComponentManifest`;
5. het compatibele stackmanifest als laatste publiceren via `StackManifestKey` en `PublishStackManifest`.

Er worden geen DEV-ID's naar PROD gekopieerd, er is geen PROD-ID-mapping nodig en er worden geen rechtstreekse tabel-`INSERT`s vanuit de deployorchestrator gebruikt. De import moet idempotent zijn en vóór de eerste mutatie volledig kunnen worden gevalideerd.

Bij een importfout stopt de deployment. De PROD-databasebackup van dezelfde `ReleaseId` is dan de rollbackbron.

### Fase 7: Databasevalidatie na DB-sync en release-data-import

Voer na zowel de structurele DB-sync uit Fase 6 als de release-data-import uit Fase 6a uit:

- databaseverbinding;
- verwachte tabellen aanwezig;
- verwachte routines/functies aanwezig;
- `component_manifests` aanwezig;
- `stack_manifests` aanwezig;
- `GetActiveStackBuildNumber()` werkt;
- `GetActiveStackManifest()` werkt;
- `GetFunctionCapabilities()` werkt;
- actieve stack is compatibel;
- stack build en componentversies zijn de verwachte releasewaarden;
- geen onverwachte foutstatus.

Bij fout: deployment stoppen en handmatige rollbackbeslissing activeren. FE/MW mogen nog niet als actief worden gepubliceerd.

### Fase 8: FE/MW staging en upload

1. Bouw FE lokaal.
2. Controleer `dist/`.
3. Maak lokale stagingmappen.
4. Kopieer FE en MW naar tijdelijke NAS-stagingmappen.
5. Controleer staging op ontbrekende of onverwachte bestanden.
6. Vervang pas daarna de actieve FE/MW-buildmappen.

### Fase 9: Containers herstarten

1. Stop relevante services gecontroleerd.
2. Start de services opnieuw.
3. Herbouw MW alleen als dependencybestanden dit vereisen.
4. Bij gewijzigde `requirements.txt` moet de image vóór de productieherstart beschikbaar zijn.
5. Leg containerstatus en restartresultaat vast.

### Fase 10: Healthchecks en smoke test

Healthchecks:

- MW endpoint bereikbaar;
- FE endpoint bereikbaar;
- databaseverbinding werkt;
- `/versioning/stack-build` geeft de verwachte stack build;
- `/capabilities` geeft een geldige response;
- actieve compatibiliteitsstatus is `passed`.

Smoke test:

- loginpagina laden;
- loginactie controleren volgens productie-SSO-flow;
- na login dashboard laden;
- een bestaande leesactie uitvoeren;
- geen onverwachte fout in MW-logs;
- bestaande gebruikersdata blijft zichtbaar;
- Release Dashboard toont juiste stack build en componentversies.

### Fase 11: Release afronden

Een release wordt alleen als geslaagd gemarkeerd wanneer:

- backup geldig is;
- DB-sync en DB-validatie geslaagd zijn;
- FE/MW actief zijn;
- healthchecks geslaagd zijn;
- smoke test geslaagd is;
- releasemetadata en checksums zijn opgeslagen;
- rollbackmateriaal beschikbaar blijft.

## Rollback- en fallbackontwerp

### Automatische fallback vóór DB-sync

Bij fouten in manifestcontrole, preflight, backup of FE-build:

- stop zonder productie-mutatie;
- geen rollback nodig;
- foutstatus rapporteren.

### Database-syncfout

Bij een fout tijdens DB-sync:

1. stop verdere deploystappen;
2. behoud logs en releasemetadata;
3. markeer database als mogelijk gedeeltelijk gewijzigd;
4. gebruik de backup van dezelfde `ReleaseId`;
5. voer restore uit volgens de gecontroleerde restoreprocedure;
6. valideer database opnieuw;
7. zet FE/MW terug als deze al waren vervangen;
8. herstart containers;
9. voer smoke test uit;
10. markeer release als `rolled_back` of `rollback_failed`.

### FE/MW restart- of healthcheckfout

De bestaande automatische rollback kan FE/MW terugzetten uit:

```text
/volume1/docker/familiez/Backup/<ReleaseId>/FE/
/volume1/docker/familiez/Backup/<ReleaseId>/MW/
```

Daarna moet de databaseversie worden vergeleken met de teruggezette applicatieversie. Als deze niet bij elkaar passen, is ook database-restore nodig.

### Smoke-testfout

Bij een functionele fout na succesvolle restart:

- deployment markeren als mislukt;
- rollbackbeslissing nemen;
- database restore uitvoeren als de database al is gewijzigd en de oude applicatieversie wordt teruggezet;
- FE/MW herstellen;
- containers herstarten;
- volledige smoke test herhalen.

### Handmatige rollbackbeslissing

Automatische database-restore wordt niet ingeschakeld voordat deze aantoonbaar is getest. Tot die tijd vraagt het script expliciet om een operationele rollbackbeslissing of stopt het met een duidelijke status.

De beslissing moet worden gebaseerd op:

- foutfase;
- database-syncstatus;
- backupvaliditeit;
- applicatiestatus;
- verschil tussen actieve en vorige stackversie.

## Restoreontwerp

Een restoreprocedure moet minimaal:

1. productie-MW/FE gecontroleerd stoppen;
2. actieve databaseverbindingen beheersen;
3. juiste backup en checksum selecteren;
4. restore uitvoeren met een beperkte, gecontroleerde opdracht;
5. databasegebruikers/grants controleren;
6. databasevalidatie uitvoeren;
7. passende FE/MW-backup terugzetten;
8. containers opnieuw starten;
9. healthchecks uitvoeren;
10. smoke test uitvoeren;
11. restorelog vastleggen.

Er wordt geen `DROP DATABASE`-restore gebruikt zonder afzonderlijke expliciete goedkeuring en geteste procedure.

## Benodigde uitbreidingen

### Benodigde uitbreidingen aan de deploytool

`Deploy/synology/deploy_to_synology.sh`:

- bestaande DEV-releasegegevens als release bundle exporteren;
- release bundle naar PROD-staging brengen;
- release bundle vóór import valideren;
- releasegegevens na structurele DB-sync via de bestaande registry-/manifest-sprocs naar PROD importeren;
- PROD-releasegegevens en stackstatus na import valideren;
- ReleaseId genereren en doorgeven;
- centrale backupdirectory `/volume1/docker/familiez/Backup/<ReleaseId>/` instellen;
- submappen `BE/`, `MW/` en `FE/` aanmaken;

`Deploy/versioning/run_local_release.py`:

- bestaande DEV-registratie en lokale stackgeneratie blijven ongewijzigd;
- de nieuwe deploymentlaag consumeert de gevalideerde output, maar dupliceert de DEV-registratie niet.
- vrije opslag controleren;
- BE/databasebackup naar `Backup/<ReleaseId>/BE/` aanroepen;
- backupvalidatie aanroepen;
- FE-backup rechtstreeks naar `Backup/<ReleaseId>/FE/` maken;
- MW-backup rechtstreeks naar `Backup/<ReleaseId>/MW/` maken;
- `release-metadata.json` in de release-root schrijven;
- DB-validatie aanroepen;
- rollbackstatus uitbreiden met database-status;
- releasemetadata opslaan.

`Deploy/synology/rollback_on_synology.sh`:

- dezelfde ReleaseId accepteren;
- FE-backup uit `Backup/<ReleaseId>/FE/` herstellen;
- MW-backup uit `Backup/<ReleaseId>/MW/` herstellen;
- optioneel na expliciete bevestiging BE/databasebackup uit `Backup/<ReleaseId>/BE/` herstellen;
- databasevalidatie en smoke test na restore uitvoeren.

`Deploy/synology/sync_db.py`:

- bestaande compare/sync-logica behouden;
- exitcodes behouden;
- eventueel dry-run/planmodus uitbreiden;
- geen impliciete rollback toevoegen zonder backuplaag.

### Nieuwe scripts/modules

Voorgestelde nieuwe bestanden:

- `Deploy/synology/backup_db.py`
  - dump maken;
  - metadata en checksum maken;
  - backup valideren.
- `Deploy/synology/backup_release.py`
   - `Backup/<ReleaseId>/BE/`, `MW/` en `FE/` aanmaken;
   - FE/MW-builds veilig kopiëren;
   - centrale release-metadata schrijven;
   - controleren dat alle drie componentmappen compleet zijn.
- `Deploy/synology/export_release_data.py`
   - gevalideerde DEV-releasegegevens bundelen;
   - functies, dependencies, componentmanifesten en stackmanifest op expliciete keys exporteren;
   - geen `FunctionID`-achtige database-ID's of auditgeschiedenis exporteren;
   - canonical JSON en SHA-256 maken;
   - secrets uitsluiten.
- `Deploy/synology/import_release_data.py`
   - release bundle valideren;
   - PROD-state op expliciete `FunctionKey`-/`DependencyKey`-waarden toepassen;
   - bestaande registry-/manifest-sprocs aanroepen;
   - geen DEV/PROD-ID-mapping uitvoeren;
   - idempotent importresultaat rapporteren.
- `Deploy/synology/restore_db.py`
  - alleen gecontroleerd aanroepen;
  - backup/checksum controleren;
  - restore uitvoeren;
  - generieke status teruggeven.
- `Deploy/synology/validate_production_release.py`
  - tabellen, routines, actieve stack en API-contract controleren;
  - geen secrets loggen.
- tests voor backupmetadata, checksum, restoreplanning, foutstatussen en validatie.

### Configuratie-uitbreidingen

Toe te voegen aan `deploy.env.example`, zonder echte waarden:

```text
REMOTE_BACKUP_ROOT=/volume1/docker/familiez/Backup
RELEASE_ID_FORMAT=%Y%m%d_%H%M%S
RELEASE_BUNDLE_PATH=...
REQUIRE_RELEASE_BUNDLE_VALIDATION=1
DB_DUMP_COMMAND=mariadb-dump
DB_RESTORE_COMMAND=mariadb
DB_BACKUP_RETENTION_COUNT=3
DB_BACKUP_MIN_FREE_BYTES=...
AUTO_ROLLBACK_ON_DB_FAILURE=0
REQUIRE_DB_BACKUP_VALIDATION=1
```

Werkelijke productie-invulling blijft in het lokale, niet-getrackte `deploy.env`.

## Test- en validatieplan

### Lokale unit tests

- ReleaseId-generatie;
- veilige padopbouw;
- checksumcontrole;
- metadata-opbouw;
- ongeldige of lege dump;
- ontbrekende backup;
- foutieve checksum;
- gesimuleerde restorefout;
- DB-validatie bij ontbrekende routine;
- DB-validatie bij verkeerde stack build.

### Lokale integratietests

- backup maken van een tijdelijke MariaDB;
- backup herstellen in een andere tijdelijke MariaDB;
- routines en tabellen vergelijken;
- `GetActiveStackBuildNumber()` na restore controleren;
- malformed backup weigeren;
- dubbele ReleaseId veilig afhandelen.
- release bundle exporteren en checksum controleren;
- release bundle importeren in een tijdelijke PROD-achtige database;
- herhaalde bundle-import zonder duplicaten uitvoeren;
- PROD-ID-mapping voor dependencies controleren;
- stackmanifest pas na functies, dependencies en componentmanifesten publiceren.

### Deploy-gate tests

- geldige manifesten laten passeren;
- ongeldige registry blokkeren;
- ontbrekende backup blokkeren vóór sync;
- ongeldige checksum blokkeren vóór sync;
- DB-validatiefout markeren als rollback nodig;
- geen NAS-mutatie bij preflightfout.

### Productievoorbereiding

Voor productie moet worden aangetoond:

- een geteste restore werkt;
- backup en FE/MW-backup dezelfde ReleaseId gebruiken;
- de deploy-gate vóór databasewijzigingen draait;
- DB-validatie na sync werkt;
- rollbacklogica duidelijk stopt wanneer database-restore niet automatisch is toegestaan;
- handmatige rollbackprocedure documentair uitvoerbaar is.

## Uitvoeringsvolgorde als toekomstige implementatiestappen

Deze ontwerpstappen worden afzonderlijk aangeboden en uitgevoerd volgens het bestaande implementatieplan: eerst beschrijven, expliciete toestemming vragen, uitvoeren, testen en loggen.

1. **Ontwerp en contracten**
   - exacte backupmetadata;
   - ReleaseId-contract;
   - exitcodes;
   - backuplocatie en retentie;
   - automatische versus handmatige rollbackbeslissing.
2. **Backupmodule**
   - `backup_db.py`;
   - checksum en validatie;
   - unit tests.
3. **Restoremodule**
   - `restore_db.py`;
   - veilige bevestigingsgrens;
   - tijdelijke MariaDB-restoretests.
4. **Productievalidatiemodule**
   - `validate_production_release.py`;
   - API-, DB- en stackcontrole.
5. **Release-data export/import**
   - bestaande DEV-orchestratoroutput bundelen;
   - `export_release_data.py` en `import_release_data.py` bouwen;
   - import via bestaande registry-/manifest-sprocs testen;
   - idempotentie en PROD-ID-mapping testen.
6. **Deployorchestrator aanpassen**
   - ReleaseId door de flow;
   - backup vóór DB-sync;
   - FE/MW-backups koppelen;
   - release bundle na DB-sync importeren;
   - DB-validatie na sync.
7. **Rollback uitbreiden**
   - gezamenlijke FE/MW/DB-release rollback;
   - automatische restore voorlopig standaard uit.
8. **Lokale end-to-end validatie**
   - tijdelijke MariaDB;
   - backup/restore;
   - foutscenario's;
   - positieve en negatieve gates.
9. **Review, commit en push**
   - afzonderlijke Deploy-commits;
   - documentatiecommit;
   - geen productieactie.
10. **Stap 18 en daarna Stap 19**
   - pas na expliciete goedkeuring PR's/merges;
   - productie-uitrol pas als backup, restore en rollback aantoonbaar werken.

## Open beslissingen vóór implementatie

Voor uitvoering moet expliciet worden besloten:

- Wordt database-restore automatisch uitgevoerd bij een fout, of blijft bevestiging verplicht?
- Waar wordt de backup buiten het actieve databasevolume bewaard?
- Hoeveel backups worden behouden?
- Wordt de productie-database tijdens de dump tijdelijk read-only of gestopt vanwege MyISAM-tabellen?
- Welke smoke tests zijn verplicht voor deze Familiez-release?
- Mag een deployment doorgaan als de backup wel geldig is maar de periodieke restoretest verouderd is?
- Welke operator mag een restore bevestigen?
- Wordt database-sync vervangen door expliciete migraties voor toekomstige releases?

## Veiligheidsgrens

Dit ontwerp documenteert de aanpak. Het uitvoeren van een backup op productie, restore, SSH-actie, database-sync of deployment vereist een aparte expliciete toestemming per uitvoeringsstap.
