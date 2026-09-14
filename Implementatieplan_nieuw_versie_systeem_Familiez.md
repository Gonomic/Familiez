# Implementatieplan nieuw versie- en release-systeem Familiez

Dit bestand is het voortgangslogboek voor de uitvoering van het ontwerp in [Ontwerp_nieuw_versie_systeem-Familiez.md](Ontwerp_nieuw_versie_systeem-Familiez.md).

Werkwijze per stap (verplicht, zoals afgesproken in het ontwerp):
1. Copilot beschrijft de stap (wat, waarom, opbrengst, welke bestanden/scripts/configs).
2. Copilot vraagt expliciete toestemming.
3. Pas na toestemming: uitvoeren.
4. Terugkoppeling geven.
5. Resultaat in dit bestand loggen (status, datum, opmerkingen).
6. Pas daarna wordt de volgende stap aangeboden.

Er wordt **geen enkele stap** uitgevoerd zonder expliciete toestemming vooraf. Afgeronde implementatiehistorie en toekomstige migratie-/deploymentstappen worden strikt gescheiden. Nieuwe wijzigingen worden alleen in de actuele roadmap uitgevoerd en daarna afzonderlijk gelogd.

**Uitvoeringsprincipe (conform ontwerpbesluit 14)**: de kernlogica (stappen 2 t/m 7) wordt gebouwd als losstaande, lokaal aanroepbare scripts (npm-scripts voor FE, Python-CLI voor MW/BE/Familiez-Deploy), onafhankelijk van GitHub Actions. Dit betekent dat het systeem al **lokaal, handmatig bruikbaar** is zodra stap 0 t/m 9 zijn afgerond — GitHub Actions (stap 10/11) is een latere, niet-blokkerende automatiseringslaag die dezelfde scripts aanroept, geen aparte implementatie.

## Statusoverzicht

| Stap | Omschrijving | Status |
|---|---|---|
| Voorstap | Aparte featurebranches voorbereiden in BE, MW, FE en Deploy | Afgerond |
| 0 | Voorbereiding: Function Registry-schema in BE | Afgerond |
| 1 | Registry-sproc(s) (insert/update + audit) | Afgerond |
| 2 | MW: functie-scanner (Python-CLI, lokaal aanroepbaar) | Afgerond |
| 3 | BE: functie-scanner (Python-CLI, lokaal aanroepbaar) | Afgerond |
| 4 | FE: functie-scanner (`src/services/`, npm-script, lokaal aanroepbaar) | Afgerond |
| 5 | Bump-engine (hash + commit-tag + AI-tie-breaker, lokaal aanroepbaar) | Afgerond |
| 6 | Component-manifesten (FE/MW/DB, lokaal aanroepbaar) | Afgerond |
| 6a | Bump-engine ↔ manifestgenerator koppelen | Afgerond |
| 7 | Stack-manifest + compatibiliteitscheck (Familiez-Deploy, lokaal aanroepbaar) | Afgerond |
| 8 | MW capabilities-endpoint | Afgerond |
| 9 | FE Release Dashboard | Afgerond |
| 10 | Lokale orchestrator (vervangt GitHub Actions-aanpak) | Afgerond |
| 11 | Vervallen — GitHub Actions self-hosted runner (oorspronkelijke stap 11), zie Legacy | Vervallen |
| 12 | Deploy-gate (verplichte compatibiliteitscheck vóór deployment, lokaal) | Afgerond |
| 13 | End-to-end validatie van het volledige nieuwe systeem | Afgerond |
| 14 | Verwijderen oude versie-/release-logica (allerlaatste stap) | Afgerond op 2026-09-12 |
| 15 | Database-backed component- en stackmanifesten | Afgerond op 2026-09-13 |
| 15a | Expliciete releasekeys en DEV→PROD-promotiecontract | Ontwerpbesluit toegevoegd op 2026-09-13 |
| 15b | Migratie van interne FunctionID's naar expliciete keys | Ontwerpbesluit toegevoegd op 2026-09-13; implementatie nog niet gestart |
| 16 | Afrondende documentatie en reviewvoorbereiding | Afgerond op 2026-09-13 |
| 17 | Gezamenlijke code-review van de featurebranches | Afgerond met openstaande 17.6-reminder op 2026-09-13 |
| 18 | DEV-only migratie naar expliciete keys (`FunctionID` verwijderen) | Nog niet gestart |
| 19 | DEV-release bundle en DEV-validatie | Nog niet gestart |
| 20 | DEV→PROD-promotieontwerp en lokale test | Nog niet gestart |
| 21 | Productiebackup, deployvoorbereiding en gecontroleerde merge | Nog niet gestart |
| 22 | Gecontroleerde productie-uitrol | Nog niet gestart |

---

## Voorstap: Aparte featurebranches voorbereiden

**Wat**: vóór de implementatie in elk van de vier betrokken repositories een aparte featurebranch aanmaken met dezelfde branchnaam, bijvoorbeeld `feature/familiez-versioning-system`:

- BE
- MW
- FE: `main` → `feature/familiez-versioning-system`
- Deploy: `main` → `feature/familiez-versioning-system`
- Alle vier repositories hadden vóór de branchaanmaak een schone werkboom.
- Alle vier repositories hebben na de branchaanmaak een schone werkboom.
- Er zijn geen commits gemaakt en er is niets naar een remote gepusht.

---

## Stap 0: Function Registry-schema in BE

**Wat**: aanmaken van de drie tabellen uit het ontwerp (punt 7): `function_registry`, `function_dependencies`, `function_registry_audit`, in de `humans`-database.

**Waarom**: dit is de fundering waar alle latere stappen (scanners, bump-engine, manifests, compatibiliteitschecks) op leunen. Zonder deze tabellen kan niets anders gebouwd worden.

**Opbrengst**: een lege, correct gestructureerde registry, klaar om gevuld te worden door de sprocs uit stap 1.

**Bestanden**: nieuw SQL-bestand in de BE-repo (bijv. `CreateFunctionRegistry.sql`), volgens de bestaande BE-conventies (idempotent, niet-destructief bij herhaling, juiste engine en expliciete constraints).

**Randvoorwaarde**: geen wijziging van bestaande tabellen/sprocs — alleen nieuwe, geïsoleerde objecten.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuw bestand toegevoegd: `BE/CreateFunctionRegistry.sql`.
- De tabellen `function_registry`, `function_dependencies` en `function_registry_audit` zijn gedefinieerd.
- De registry identificeert functies uniek per `Layer` en `FunctionName`.
- Directe caller-callee-afhankelijkheden hebben foreign keys naar `function_registry`.
- Auditregels hebben een foreign key naar `function_registry` en behouden auditdata bij normale statuswijzigingen.
- De tabellen zijn idempotent aangemaakt met `CREATE TABLE IF NOT EXISTS` en gebruiken InnoDB.
- Er zijn geen bestaande BE-tabellen of stored procedures gewijzigd.

**Validatie**:

- Structurele controle van de drie tabellen, primary keys, unieke sleutel en foreign keys: geslaagd.
- Controle op InnoDB voor alle tabellen: geslaagd.
- Haakjes- en backtick-balans: geslaagd.
- Volledige whitespacecontrole van het nieuwe bestand: geslaagd.
- Dev BE-installatie en tabelcontrole zijn later uitgevoerd; zie de Dev BE-validatie onder Stap 1.

---

## Stap 1: Registry-sproc(s)

**Wat**: bouwen van de sproc(s) die de registry bijwerken (bijv. `UpdateFunctionRegistry`, `AddFunctionDependency`), volgens het standaard BE-sproc-patroon (`SQL SECURITY INVOKER`, exit handler, `testlog`-logging, één `SELECT` als resultaat).

**Waarom**: conform besluit 13B — geen rechtstreekse SQL-writes vanuit de pipeline, alles via een conventie-conforme sproc.

**Opbrengst**: veilige, consistente, auditeerbare manier om de registry te muteren.

**Bestanden**: nieuw(e) SQL-bestand(en) in de BE-repo.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuw bestand toegevoegd: `BE/UpdateFunctionRegistry.sql`.
- Nieuw bestand toegevoegd: `BE/AddFunctionDependency.sql`.
- `UpdateFunctionRegistry` voert idempotent een insert of update uit op `function_registry`.
- `UpdateFunctionRegistry` schrijft bij een nieuwe functie of gewijzigde versie/signature een regel naar `function_registry_audit`.
- `AddFunctionDependency` legt directe caller-callee-relaties vast en werkt een bestaande relatie bij zonder duplicaten.
- Beide sprocs gebruiken `SQL SECURITY INVOKER`, `GetTranNo`, transacties, `GET CURRENT DIAGNOSTICS`, rollback bij fouten, `testlog`-logging en een statusresultaat.
- Validatiefouten geven `CompletedOk = 1` en `Result = 400`; databasefouten geven `CompletedOk = 2` en `Result = 500`.
- Er zijn geen bestaande BE-tabellen, sprocs of andere functionaliteiten gewijzigd.

**Validatie**:

- Procedure- en delimiterstructuur gecontroleerd: geslaagd.
- Aanwezigheid van `SQL SECURITY INVOKER`, diagnostics-handler, rollback, logging en statusresultaten: geslaagd.
- Editorfoutcontrole voor beide SQL-bestanden: geen fouten.
- Beide sprocs zijn in de lokale Dev BE MariaDB 10.6 succesvol aangemaakt.

**Dev BE-validatie**:

- Uitgevoerd op 2026-09-10 tegen de lokale container `familiez-mysql`, database `humans`, met databasegebruiker `HumansService`; productie is niet gebruikt.
- De drie registry-tabellen zijn zichtbaar als `BASE TABLE` en de verwachte primary keys, unieke sleutel en foreign keys zijn gecontroleerd.
- Drie testfuncties (FE, MW en BE) zijn geregistreerd.
- Herhaalde registratie van dezelfde waarden maakte geen extra auditregels aan.
- De FE-testfunctie is van versie 1 naar versie 2 bijgewerkt; precies één auditregel met oud-versie 1 en nieuw-versie 2 is aangemaakt.
- Herhaalde registratie van de ongewijzigde FE-versie maakte geen extra auditregel aan.
- Twee dependencies zijn toegevoegd; een herhaalde FE→MW-relatie werkte de minimumversie bij zonder duplicaat.
- Ongeldige layer en self-dependency gaven `CompletedOk = 1`, `Result = 400`.
- Een dependency naar een niet-bestaande functie gaf `CompletedOk = 2`, `Result = 500`; de foreign-keyfout werd via rollback afgehandeld.
- Eindcontrole bevestigde 3 testfuncties, 2 dependencies, 4 auditregels, FE-versie 2 en de juiste minimumversies.
- Alle testfuncties, dependencies en auditregels zijn daarna verwijderd; resterend aantal testrecords: 0, 0, 0.
- De door de sprocs aangemaakte `testlog`-regels zijn intact gelaten.
- De drie BE-bestanden zijn lokaal gecommit met Conventional Commit-message `feat: add function registry schema and procedures` in commit `0e4087a5635f31c4514a71dd07a58699dce7612b`; er is niets gepusht.

---

## Stap 2: MW functie-scanner

**Wat**: een Python-script (los van `main.py`, geen wijziging van bestaande endpoints) dat de MW-routes/functies scant, hun signature hasht, en de resultaten kan doorgeven aan de bump-engine. Conform besluit 14: uitgevoerd als lokaal aanroepbare CLI (bijv. `python -m versioning.scan_mw_functions`), niet afhankelijk van GitHub Actions.

**Waarom**: nodig om automatisch te detecteren of een MW-functie gewijzigd is en wat voor bump dat betekent.

**Opbrengst**: een herbruikbaar scanner-script/module, direct lokaal bruikbaar, en later zonder aanpassing aan te roepen vanuit een GitHub Actions-workflow.

**Bestanden**: nieuw bestand in de MW-repo (bijv. `versioning/scan_mw_functions.py`), nieuwe tests.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuw pakket toegevoegd: `MW/versioning/`.
- Nieuwe scanner toegevoegd: `MW/versioning/scan_mw_functions.py`.
- Nieuwe gerichte tests toegevoegd: `MW/test_versioning.py`.
- De scanner gebruikt Python AST en importeert `main.py` of de FastAPI-applicatie niet.
- FastAPI HTTP-decorators, `api_route`, sync/async handlers, parameters, annotaties, routepaden en decoratoropties worden deterministisch uitgelezen.
- Per gevonden route wordt een canonieke SHA-256 signature hash (`sha256:...`) geproduceerd.
- Syntaxfouten worden als diagnostics gerapporteerd zonder de volledige scan af te breken.
- CLI-aanroep: `python3 -m versioning.scan_mw_functions [pad]`.

**Validatie**:

- Gerichte tests: 3 geslaagd.
- Scan van de volledige MW-bronboom: 37 functies gevonden, 0 diagnostics.
- Volledige MW-testset: 88 tests geslaagd.
- Bestaande deprecation warnings in dependencies/test tooling blijven aanwezig; er zijn geen nieuwe test failures.
- De MW-scanner en tests zijn lokaal gecommit met Conventional Commit-message `feat: add middleware route function scanner` in commit `1abca10f227d3e79ce6a187ef939246e698e0328`; er is niets gepusht.

---

## Stap 3: BE functie-scanner

**Wat**: een script dat de BE-sprocs scant (parametergroepen/signature) en hasht. Conform besluit 14: lokaal aanroepbare Python-CLI.

**Waarom**: analoog aan stap 2, voor de BE-laag.

**Opbrengst**: herbruikbaar scanner-script voor sproc-signatures, direct lokaal bruikbaar.

**Bestanden**: nieuw script, plaats nog te bepalen (BE-repo of Familiez-Deploy, afhankelijk van waar scanning-tooling het beste past — wordt bij deze stap concreet besloten).

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- De scanner is in de BE-repo geplaatst in `BE/versioning/scan_be_functions.py`.
- De scanner leest `.sql`- en `.ddl`-bestanden offline en maakt geen databaseverbinding.
- Comments, string literals, backtick-identifiers en `DELIMITER`-contexten worden veilig verwerkt.
- Procedureparameters worden gelezen als `IN`, `OUT`, `INOUT` of impliciet `IN`, inclusief type-informatie.
- Per procedure wordt een deterministische SHA-256 signature hash (`sha256:...`) geproduceerd.
- Syntax-/parseproblemen worden als diagnostics gerapporteerd zonder de volledige scan af te breken.
- CLI-aanroep: `python3 -m versioning.scan_be_functions [pad]`.
- Nieuwe tests toegevoegd in `BE/versioning/test_scan_be_functions.py`.

**Validatie**:

- Gerichte unittest-suite: 3 tests geslaagd.
- Scan van de volledige BE-repository: 309 procedures gevonden, 0 diagnostics.
- `UpdateFunctionRegistry` en `AddFunctionDependency` zijn door de scanner gevonden.
- Een ruwe tekstinventarisatie vond 316 `CREATE PROCEDURE`-teksten; de zeven extra matches kwamen uit historische/documentatie-/scriptbestanden en waren geen scanbare SQL-proceduredefinities.
- De scanner maakt geen databasewijzigingen.
- De BE-scanner en tests zijn lokaal gecommit met Conventional Commit-message `feat: add database procedure signature scanner` in commit `7f59c534e605fb99d766e119367a342468bad204`; er is niets gepusht.

---

## Stap 4: FE functie-scanner

**Wat**: een script dat alleen de functies in `src/services/` scant (conform besluit 13A), en hun argumenten als quasi-signature hasht. Conform besluit 14: als npm-script (`npm run scan:versioning`), lokaal aanroepbaar.

**Waarom**: conform besluit 13A — dit is de enige laag in FE die relevant is voor de aanroepketen, en de enige die betrouwbaar te scannen is zonder TypeScript.

**Opbrengst**: herbruikbaar scanner-script voor de FE-servicelaag, direct lokaal bruikbaar.

**Bestanden**: nieuw script in de FE-repo (bijv. `scripts/versioning/scan-fe-functions.mjs`), nieuw npm-script in `package.json`.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuwe scanner toegevoegd: `FE/scripts/versioning/scan-fe-functions.mjs`.
- Nieuwe Vitest-tests toegevoegd: `FE/src/test/scan-fe-functions.test.js`.
- `espree` expliciet als FE-devdependency toegevoegd; `package.json` en `package-lock.json` zijn bijgewerkt.
- Nieuw npm-script toegevoegd: `npm run scan:versioning`.
- De scanner beperkt zich hard tot `.js`-bestanden onder `src/services/`.
- Named function exports, async functions, arrow functions, indirecte named exports en default/destructuring/rest-parameters worden gescand.
- Per servicefunctie wordt een deterministische SHA-256 quasi-signature hash (`sha256:...`) geproduceerd.
- Parsefouten worden per bestand met locatie gerapporteerd zonder de scan af te breken.

**Validatie**:

- Gerichte scanner-tests: 4 geslaagd.
- `npm run scan:versioning`: 44 functies gevonden, 0 diagnostics.
- Volledige FE-testset: 21 tests geslaagd, 0 failures.
- De nieuwe scannerbestanden hebben geen ESLint-meldingen.
- `npm run lint` rapporteert 76 bestaande errors en 1 bestaande warning in andere FE-bestanden; deze zijn niet door Stap 4 veroorzaakt en zijn niet aangepast.
- De FE-scanner en tests zijn lokaal gecommit met Conventional Commit-message `feat: add frontend service function scanner` in commit `6b215ffd4193beef1c3c639811963929724a49e0`; er is niets gepusht.

---

## Stap 5: Bump-engine

**Wat**: implementatie van de bump-beslissingslogica uit besluit 1: hash-classificatie + commit-tag-analyse als primaire bronnen, diff-analyse als verfijning, AI-analyse als gelogde tie-breaker bij conflict.

**Waarom**: dit is het besluitvormingshart van het hele systeem.

**Opbrengst**: een herbruikbare bump-engine (functie- en componentniveau), met heldere, testbare regels.

**Bestanden**: nieuw script/module, vermoedelijk in Familiez-Deploy (gedeeld tussen componenten) of als los packagebaar script per repo — wordt bij deze stap concreet besloten.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- De gedeelde engine is geplaatst in `Deploy/versioning/bump_engine.py`.
- Nieuwe tests toegevoegd in `Deploy/versioning/test_bump_engine.py`.
- De engine werkt als pure Python-module en wijzigt geen repositories, versiebestanden of databases.
- JSON wordt via stdin of een bestand gelezen en als JSON naar stdout geschreven.
- Signature-hashverschillen worden als major-kandidaat verwerkt.
- Conventional Commits worden deterministisch geclassificeerd als major/minor/patch/none.
- Diff-informatie kan een implementation-only wijziging als patch aandragen.
- De zwaarste geldige bump wint per component.
- Geen wijziging en `chore:` geven deterministisch `none`; onbekende signalen geven `manual_review`.
- Een expliciet AI-advies wordt uitsluitend als gelogde tie-breaker gebruikt bij ambigue input; er is geen netwerk- of live-AI-aanroep.
- Exitcodes: `0` voor `ok`, `2` voor `invalid_input`, `3` voor `manual_review`.

**Validatie**:

- Gerichte unittest-suite: 6 tests geslaagd.
- CLI `feat`-scenario: `1.2.3` naar `1.3.0`, status `ok`, exitcode 0.
- Onbekend commitbericht: status `manual_review`, exitcode 3.
- Python syntaxcontrole: geslaagd.
- De bump-engine en tests zijn lokaal gecommit met Conventional Commit-message `feat: add deterministic version bump engine` in commit `0cd327bfc88725a00f199424df90ea8e92675747`; er is niets gepusht.
- Checkpoint na Stap 0 t/m 5: op 2026-09-10 zijn de featurebranches `feature/familiez-versioning-system` van BE, MW, FE en Deploy naar hun respectievelijke `origin`-remotes gepusht; er is niets naar `main` of `master` gemerged.

---

## Stap 6: Component-manifesten

**Wat**: genereren van het FE/MW/DB-manifest (JSON-structuur uit besluit 8), inclusief Docker image-tag, opgeslagen in de eigen repo.

**Waarom**: reproduceerbaarheid en traceerbaarheid per component-release.

**Opbrengst**: werkend manifest-generatiescript per component.

**Bestanden**: nieuw script per repo (FE/MW/BE), commit-logica met voorkoming van CI-loops (`[skip ci]`).

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- MW-generator toegevoegd: `MW/versioning/generate_manifest.py` met tests in `MW/versioning/test_generate_manifest.py`.
- BE-generator toegevoegd: `BE/versioning/generate_manifest.py` met tests in `BE/versioning/test_generate_manifest.py`.
- FE-generator toegevoegd: `FE/scripts/versioning/generate-manifest.mjs` met tests in `FE/src/test/generate-manifest.test.js`.
- Componentmanifesten gegenereerd in de eigen repositories als `versioning/manifest.json`.
- Het manifestcontract bevat `component`, `version`, `dockerImageTag`, `generatedAt`, `sourceCommit` en `functions`.
- De afgesproken startversie `1.0.0` is gebruikt voor FE, MW en DB.
- De image-tags zijn respectievelijk `familiez-fe:1.0.0`, `familiez-mw:1.0.0` en `familiez-db:1.0.0`.
- De manifestgeneratoren accepteren vaste metadata voor deterministische tests en gebruiken anders actuele commit/timestampinformatie.
- Generatorcodecommits:
	- FE: `4e09a56a16f0513466cec18bfc216c6f26caafdf` — `feat: add frontend component manifest generator`.
	- MW: `31a4f43be5fec82dff98fbf16beb9b2a748ddb8` — `feat: add middleware component manifest generator`.
	- BE: `ebcbcb0c0e5d0d5f66f41b05af3f6828431f196b` — `feat: add database component manifest generator`.
- Manifestcommits:
	- FE: `99e954b977b5089d4ac17f7e8834d3debb67b1cd` — `chore: add frontend component manifest`.
	- MW: `55d4414bccd49d90f66e548fbda8c58b91bd9522` — `chore: add middleware component manifest`.
	- BE: `ae75cb6cfdc639e3fd39c2fd1e558ada9d2a1ec3` — `chore: add database component manifest`.

**Validatie**:

- Gerichte FE-manifesttests: 2 geslaagd.
- Gerichte MW-manifesttests: 2 geslaagd.
- Gerichte BE-manifesttests: 2 geslaagd.
- FE- en BE-scanner/manifesttests gecombineerd: 6 FE-tests en 5 BE-tests geslaagd.
- Echte manifesten gecontroleerd: FE 44 functies, MW 37 functies, DB 309 functies.
- Alle signature hashes zijn geldig in het formaat `sha256:<64 hextekens>`.
- Alle verplichte top-level manifestvelden, componentnamen, versies en image-tags zijn gecontroleerd.
- De aanvankelijke MW-testaanroep gebruikte een onjuiste modulenaam; de juiste testaanroep `python -m unittest test_versioning versioning.test_generate_manifest -v` is daarna succesvol uitgevoerd.
- FE, MW en BE hadden na afronding een schone werkboom.

---
## Stap 6a: Bump-engine ↔ manifestgenerator koppelen

**Wat**: de ontbrekende koppeling tussen de bump-engine (Stap 5) en de manifestgeneratoren (Stap 6) bouwen, zodat een generatorrun zonder expliciete `--version` niet langer bij de bootstrapwaarde `1.0.0` blijft hangen, maar het vorige manifest als uitgangspunt neemt en incrementeel doortelt via de bump-engine.

**Aanleiding**: op 2026-09-10 is per abuis eerst een andere aanpak geïmplementeerd (manifestversie laten volgen uit de legacy `fe_releases`/`mw_releases`/`be_releases`-tabellen). Dat conflicteerde met de afspraak dat `1.0.0` uitsluitend de eenmalige bootstrapwaarde was en dat er daarna incrementeel via de bump-engine doorgeteld moest worden, los van de oude release-notes-tabellen (die in Stap 14 juist verwijderd worden). Die aanpak is teruggedraaid (working tree + de per ongeluk ingevoegde DB-rijen in `fe_releases`/`mw_releases`/`be_releases`) vóór deze stap is uitgevoerd.

**Waarom**: zonder deze koppeling is Stap 5 (bump-engine) een geïsoleerd, nooit aangeroepen onderdeel en blijven de manifesten voor altijd op de bootstrapwaarde staan.

**Opbrengst**: een `next_version`-script per component dat het vorige manifest (versie + `functions`) inleest, de scanner opnieuw draait, commits sinds het vorige `sourceCommit` verzamelt, dit als payload aan `Deploy/versioning/bump_engine.py` voorlegt, en het voorstel teruggeeft. De manifestgenerator gebruikt dit voorstel automatisch wanneer `--version` niet is opgegeven; bij een niet-`ok`-status (`manual_review`/`invalid_input`) wordt de generatie geweigerd i.p.v. stilzwijgend te gokken.

**Bestanden**:
- `MW/versioning/next_version.py` + `MW/versioning/test_next_version.py`
- `BE/versioning/next_version.py` + `BE/versioning/test_next_version.py`
- `FE/scripts/versioning/next-version.mjs` + `FE/src/test/next-version.test.js`
- Aanpassing van `generate_manifest.py`/`.mjs` in alle drie repositories: `--version` is nu optioneel; zonder expliciete waarde wordt bij een bestaand manifest de bump-engine geraadpleegd, en alleen bij een nog ontbrekend manifest wordt `1.0.0` gebruikt (eerste bootstrap).

**Randvoorwaarde**: `Deploy/versioning/bump_engine.py` wordt via een relatief pad (sibling-checkout, zoals in deze workspace) gevonden; dit is expliciet overschrijfbaar via `--bump-engine`. Er is geen DB-afhankelijkheid.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- `compute_next_version()`/`computeNextVersion()` leest het vorige manifest, draait de lokale scanner voor de actuele functiesignaturen, verzamelt volledige commitberichten sinds het vorige `sourceCommit` via `git log <commit>..HEAD --format=%B%x00`, en geeft dit als JSON via stdin aan `bump_engine.py`.
- Handmatige dry-run tegen scratch-kopieën van de drie echte manifesten leverde voor alle drie componenten hetzelfde, consistente voorstel op: `1.0.0 -> 2.0.0` (major, reden: "public signature hash changed") — logisch, aangezien de functiesignaturen sinds de bootstrap-commit substantieel zijn gewijzigd zonder dat het manifest ooit is bijgewerkt.
- De echte, gecommitte `versioning/manifest.json`-bestanden zijn bewust **niet** overschreven met dit voorstel; het toepassen van een concrete bump is een aparte, expliciete releasebeslissing die niet impliciet in deze koppelstap hoort.
- De eerder per abuis ingevoegde releaserijen (FE 1.0.4, MW 0.9.10, BE 0.9.13) zijn verwijderd uit `fe_releases`/`mw_releases`/`be_releases`; het bijbehorende SQL-bestand is verwijderd. De legacy release-tabellen staan weer op hun oorspronkelijke laatste release (FE 1.0.3, MW 0.9.9, BE 0.9.11).

**Validatie**:

- Nieuwe gerichte tests: MW 3 tests, BE 3 tests, FE 2 tests — allemaal geslaagd (gemockte bump-engine-aanroep resp. een echte stub-`bump_engine.py`).
- Volledige testsuites na de wijziging: MW 96/96, BE 8/8, FE 123/123 geslaagd — geen regressies.
- Working tree van MW, BE en FE bevat na afronding alleen de nieuwe/gewijzigde bestanden van deze stap; de gecommitte `manifest.json`-bestanden zijn ongewijzigd.
- MW, BE en FE zijn lokaal gecommit met Conventional Commit-message `feat: link bump engine to manifest generator` in respectievelijk commit `9fa0eba16ad30fc238107a1b6595ac78f16ab057` (MW), `57316ca88c468d59bd064eda7f002bc9a991d8ce` (BE) en `eec078466e6e702787c7c56e470190c7625f8524` (FE), en gepusht naar `origin/feature/familiez-versioning-system`.

---
## Stap 7: Stack-manifest + compatibiliteitscheck

**Wat**: bouwen van de logica in Familiez-Deploy die de drie component-manifesten combineert, de FE→MW→BE-keten wandelt (via `function_dependencies`), en het stack-manifest genereert met een nieuw `StackBuildNumber`.

**Waarom**: dit is de kern van "Function Registry wordt centrale bron van waarheid" en de eerste concrete compatibiliteitscheck.

**Opbrengst**: werkend stack-manifest-mechanisme, nog handmatig aan te roepen (nog los van GitHub Actions-triggering).

**Bestanden**: nieuw script in Familiez-Deploy.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Stackgenerator toegevoegd: `Deploy/versioning/stack_manifest.py`.
- Compatibiliteitstests toegevoegd: `Deploy/versioning/test_stack_manifest.py`.
- De generator leest FE-, MW- en DB-manifesten plus een apart registry-JSON met directe dependencies.
- De stackoutput bevat `schemaVersion`, `stackBuildNumber`, `generatedAt`, componentreferenties, manifest-hashes, `compatibilityCheck`, fouten en een registry-hash.
- Directe ketens FE→MW en MW→DB worden gecontroleerd op aanwezige caller/callee-functies en minimale functieversies (`v1`, `v2`, enzovoort).
- Componentversies blijven semver (`1.0.0`); functieversies blijven oplopende integers met `v`-prefix, conform het ontwerp.
- De controle is lokaal aanroepbaar via `python -m versioning.stack_manifest` en maakt geen databaseverbinding.

**Validatie**:

- Gerichte stack-suite: 4 tests geslaagd.
- Determinisme met vaste timestamp en buildnummer: geslaagd.
- Ontbrekende manifesten/callees en incompatibele functieversies: correct als `failed` gerapporteerd.
- CLI tegen de echte FE/MW/DB-manifesten met lege registry: exitcode 0, `compatibilityCheck: passed`.
- Ongeldige registry-input: geweigerd met exitcode 3 en compatibiliteitsfout.
- Python syntaxcontrole: geslaagd.
- De stack-generator en tests zijn lokaal gecommit met Conventional Commit-message `feat: add stack compatibility manifest generator` in commit `fdb727e0506df8b1997312136bfcece158b2f037`; er is niets gepusht.
- Checkpoint na Stap 6 en 7: op 2026-09-10 zijn de featurebranches van BE, MW, FE en Deploy naar `origin/feature/familiez-versioning-system` gepusht; er is niets naar `main` of `master` gemerged.

---

## Stap 8: MW capabilities-endpoint

**Wat**: nieuw, geïsoleerd endpoint (bijv. `GET /capabilities`) dat de actuele registry-status en het laatste stack-manifest uitleest en teruggeeft.

**Waarom**: dit is de runtime-voorziening uit de checklist, nodig voor het Release Dashboard.

**Opbrengst**: bevraagbaar endpoint, met eigen tests.

**Bestanden**: nieuwe functie in `main.py` (toevoeging, geen wijziging van bestaande endpoints) of een nieuwe module die vanuit `main.py` wordt aangeroepen; nieuwe tests.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuwe read-only BE-sproc toegevoegd: `BE/GetFunctionCapabilities.sql`.
- Nieuwe MW-route toegevoegd: `GET /capabilities`.
- De sproc levert registryfuncties en directe dependencies als één JSON-resultaat.
- Het endpoint gebruikt de bestaande SSO-middleware en wijzigt geen bestaande public paths of endpoints.
- Het optionele laatste stack-manifest wordt gelezen via `STACK_MANIFEST_PATH`; een ontbrekend manifest levert `stackManifest: null`.
- Databasefouten worden niet naar de client gelekt; het endpoint geeft een generieke 500-melding.
- Nieuwe tests toegevoegd in `MW/test_capabilities.py`.

**Validatie**:

- Gerichte endpointtests: 3 geslaagd.
- Nieuwe sproc geïnstalleerd in lokale Dev-MariaDB `familiez-mysql` en `CALL GetFunctionCapabilities()` succesvol uitgevoerd.
- Dev-resultaat: `CompletedOk=0`, geldige JSON met sleutels `functions` en `dependencies`, momenteel 0 functies en 0 dependencies.
- Volledige MW-testset: 93 tests geslaagd, 0 failures.
- Bestaande deprecation warnings blijven aanwezig; er zijn geen nieuwe failures.
- De BE-read-sproc is lokaal gecommit met Conventional Commit-message `feat: add function capabilities procedure` in commit `777dc5c9a8e86310aea21273c82c782e35162d06`; er is niets gepusht.
- Het MW-endpoint en de tests zijn lokaal gecommit met Conventional Commit-message `feat: add capabilities endpoint` in commit `aca11f3f423e57ce78dfea42bf23e1097f4b3835`; er is niets gepusht.

---

## Stap 9: FE Release Dashboard

**Wat**: nieuwe, geïsoleerde pagina/component die het capabilities-endpoint aanroept en de huidige stack-status toont.

**Waarom**: runtime-voorziening uit de checklist, zichtbaar maken van de nieuwe registry voor gebruikers/beheerders.

**Opbrengst**: werkend dashboard, los van de bestaande `FamiliezInfo.jsx` (die pas in de allerlaatste stap verdwijnt).

**Bestanden**: nieuwe component + eventueel nieuwe route, nieuwe service-functie in `services/`.

**Status**: Afgerond op 2026-09-10.

**Uitvoering en resultaat**:

- Nieuwe capabilities-service toegevoegd in `FE/src/services/familyDataService.js`.
- Nieuwe pagina toegevoegd: `FE/src/pages/ReleaseDashboardPage.jsx`.
- Nieuwe beveiligde route toegevoegd: `/release-dashboard` in `FE/src/app.jsx`.
- Nieuwe tests toegevoegd in `FE/src/test/release-dashboard.test.jsx`.
- Het dashboard toont stack-buildnummer, compatibiliteitsstatus, componentversies, registryfuncties en dependencies.
- Loading-, fout- en lege-manifeststates zijn afgedekt.
- De bestaande `FamiliezInfo.jsx` en oude releasefunctionaliteit zijn niet gewijzigd.
- De route gebruikt de bestaande `RequireAuth`-beveiliging en de bestaande MUI-shellconventies.

**Validatie**:

- Gerichte dashboardtests: 2 geslaagd.
- Volledige FE-testset: 8 testbestanden geslaagd, geen failures.
- `npm run build`: geslaagd, 1570 modules getransformeerd.
- Gerichte ESLint-controle op de nieuwe dashboard-, test- en generatorbestanden: geslaagd, geen meldingen.
- De volledige lintbaseline blijft falen met 76 bestaande errors en 1 warning in andere bestanden; Stap 9 heeft geen nieuwe lintmeldingen toegevoegd.
- Het FE Release Dashboard en de tests zijn lokaal gecommit met Conventional Commit-message `feat: add release capabilities dashboard` in commit `df810c82991c9c2a0157a868c5d6527f9b45bef3`; er is niets gepusht.
- Checkpoint na Stap 9: op 2026-09-10 zijn de featurebranches van BE, MW, FE en Deploy gecontroleerd en naar `origin/feature/familiez-versioning-system` gepusht; FE had nieuwe commits, BE/MW/Deploy waren al up-to-date. Er is niets naar `main` of `master` gemerged.

**Addendum (2026-09-10, na Stap 6a)**: het linkermenu (`FE/src/LeftDrawer.jsx`) toonde tot dusver geen zichtbare ingang naar `/release-dashboard`; "Familiez info" wees alleen naar de oude `FamiliezInfo.jsx`. Het menu is aangepast van een generieke label→slug-afleiding naar expliciete label/pad-paren, zodat label en route niet meer 1:1 hoeven te matchen:
- "Familiez info" wijst nu naar `/release-dashboard` (nieuwe systematiek).
- "Familiez info (oud)" is toegevoegd en wijst naar de ongewijzigde `/familiez-info`.
Er zijn geen routes, endpoints of bestaande pagina's gewijzigd of verwijderd — uitsluitend het menu-label/route-koppelbestand. Volledige FE-testset (123 tests) bleef groen na deze wijziging. FE is lokaal gecommit met Conventional Commit-message `feat: point familiez info menu entry to release dashboard` in commit `935367a736c6403446967978ec7259de4e39e85c`, en gepusht naar `origin/feature/familiez-versioning-system`.

---

## Stap 10: Lokale orchestrator (vervangt GitHub Actions-aanpak)

**Besluit (2026-09-10)**: Frans wil de triggering/aansturing van het versiesysteem bewust lokaal houden op deze ontwikkelmachine en geen gebruik maken van GitHub Actions. De oorspronkelijke stappen 10 en 11 (component-workflows + self-hosted runner) zijn daarom **vervallen** en integraal verplaatst naar de sectie **"Legacy: oorspronkelijke GitHub Actions-stappen"** onderaan dit document, puur ter naslag — ze worden niet uitgevoerd.

**Wat**: één samenvoegend orchestratiescript (bijv. `Deploy/versioning/run_local_release.sh` of een Python-CLI) dat de al bestaande, losstaande lokale scripts per component na elkaar aanroept: scanner → `next_version` (bump-engine, Stap 6a) → `generate_manifest` → de scanresultaten via `UpdateFunctionRegistry`/`AddFunctionDependency` in de registry laden → `Deploy/versioning/stack_manifest.py` draaien en het resultaat wegschrijven naar het pad waar MW's `STACK_MANIFEST_PATH` naar wijst. Handmatig te starten door Frans wanneer hij een nieuwe versie wil vastleggen.

**Waarom**: dit is de ontbrekende schakel die de al bestaande losse onderdelen (Stap 0 t/m 9) daadwerkelijk end-to-end verbindt, zonder afhankelijkheid van GitHub Actions of een self-hosted runner.

**Opbrengst**: één lokaal aanroepbaar commando dat de volledige versie-pijplijn uitvoert.

**Bestanden**: nieuw orchestratiescript in `Deploy/versioning/`.

**Status**: Afgerond op 2026-09-11.

**Uitvoeringsnotitie (2026-09-11, vóór uitvoering)**:

- Stap 10 wordt uitgevoerd als een lokaal Python-CLI in `Deploy/versioning/run_local_release.py`.
- De CLI roept de bestaande manifestgenerators en `stack_manifest.py` aan en schrijft een registry-export en stack-manifest naar configureerbare lokale paden.
- Database-sync is expliciet opt-in via `--database` en gebruikt uitsluitend `UpdateFunctionRegistry` en `GetFunctionCapabilities`; productie en het bestaande deployscript vallen buiten deze stap.
- De eerste validatie bestaat uit gerichte orchestrator-tests en een lokale dry-run zonder database-mutaties. Daarna volgt, na afzonderlijke controle, een Dev-database-run.

**Uitvoering en resultaat**:

- Nieuwe orchestrator toegevoegd: `Deploy/versioning/run_local_release.py`.
- Gerichte tests toegevoegd: `Deploy/versioning/test_run_local_release.py`.
- De orchestrator laadt de bestaande `MW/.env` dependencyvrij met Python-regel parsing, zodat speciale tekens in databasecredentials niet door shell-parsing worden beschadigd.
- De pipeline genereert FE-, MW- en DB-manifesten, synchroniseert functies via `UpdateFunctionRegistry`, leest de registry terug via `GetFunctionCapabilities` en genereert het stack-manifest.
- Database-sync is expliciet opt-in via `--database`; zonder die optie schrijft `--dry-run` alle artefacten uitsluitend naar een tijdelijke map.
- De dry-run is succesvol uitgevoerd met compatibility status `passed`; er zijn geen projectartefacten of databasegegevens gewijzigd.
- De lokale Dev-run is succesvol uitgevoerd met exitcode 0.
- Gegenereerde componentversies: FE `2.0.0`, MW `2.0.0`, DB `2.0.0`.
- Registry-export: `Deploy/versioning/registry.json`.
- Stack-manifest: `Deploy/versioning/stack-manifest.json`, `stackBuildNumber` `2`, `compatibilityCheck` `passed`, zonder compatibiliteitsfouten.
- Registry-resultaat: 45 FE-functies, 38 MW-functies en 69 unieke BE-functies. Het BE-manifest bevat 310 proceduredefinities, waarvan 241 dubbele namen; de registry bewaart conform het schema één record per laag en functienaam.
- Er zijn momenteel 0 registry-dependencies. De bestaande scanners leveren geen cross-layer dependencygegevens; dit moet vóór een betekenisvolle compatibiliteitsvalidatie in Stap 13 worden aangevuld of expliciet als beperking worden vastgesteld.
- Deploy-tests: 12 geslaagd. De bestaande projecttests zijn niet aangepast.
- De bestaande deployscripts en productieomgeving zijn niet aangeroepen.

---

## Stap 12: Deploy-gate

**Wat**: de bestaande Synology-deploy-workflow uitbreiden met de verplichte compatibiliteitscheck vlak vóór deployment (besluit 11, moment 2): weiger deployment als de te deployen `StackBuildNumber` niet `compatibilityCheck: passed` heeft.

**Waarom**: de daadwerkelijke veiligheidsgate van het hele systeem.

**Opbrengst**: veilige koppeling tussen het nieuwe versie-systeem en de bestaande deploy-scripts, zonder de bestaande deploy-mechaniek te herschrijven.

**Bestanden**: aanpassing van het bestaande deploy-mechanisme in `Deploy/synology/` (enige plek waar een bestaand script wordt uitgebreid, niet vervangen).

**Besluit (2026-09-10)**: de compatibiliteitscheck wordt rechtstreeks lokaal aangeroepen vanuit het bestaande `Deploy/synology/deploy_to_synology.sh` (bijv. `python -m versioning.stack_manifest --check` o.i.d.), zonder self-hosted runner of GitHub Actions — consistent met het besluit om het versiesysteem volledig lokaal te laten draaien (zie Stap 10).

**Voorwaarde vooraf (toegevoegd 2026-09-10, voldaan in Stap 10)**: de manifesten zijn bewust zonder expliciete `--version` opnieuw gegenereerd. FE, MW en DB staan nu op `2.0.0` en weerspiegelen de actuele functiesignaturen; het stack-manifest is opnieuw opgebouwd en heeft `compatibilityCheck: passed`.

**Status**: Afgerond op 2026-09-11.

**Uitvoering en resultaat**:

- `Deploy/synology/deploy_to_synology.sh` bevat nu een verplichte preflight-gate vóór de NAS-SSH-check, FE-build, database-sync en uploadstappen.
- De gate controleert het bestaan van de FE-, MW-, BE-manifesten, de registry-export en het stack-manifest.
- Daarna wordt `Deploy/versioning/stack_manifest.py` opnieuw aangeroepen tegen de actuele componentmanifesten en registry. Alleen `compatibilityCheck: passed` laat het deployscript verdergaan.
- De paden zijn configureerbaar via `STACK_MANIFEST_PATH`, `STACK_REGISTRY_PATH`, `STACK_FE_MANIFEST`, `STACK_MW_MANIFEST` en `STACK_BE_MANIFEST`; de standaardwaarden wijzen naar de lokale Familiez-workspace.
- Positieve test: de actuele lokale manifesten en registry gaven exitcode 0 en `compatibilityCheck: passed`.
- Negatieve test: een tijdelijk ongeldig registrybestand gaf exitcode 1, meldde `Deployment blocked` en bereikte de NAS-SSH-preflight niet.
- `bash -n` op het deployscript is geslaagd.
- Het volledige deployscript is bewust niet gestart; er is geen contact met de NAS en geen productie-deployment uitgevoerd.
- De eerder vastgelegde voorwaarde voor Stap 13 is inmiddels ingevuld met twee cross-layer dependencies voor één echte FE → MW → BE-aanroepketen.

---

## Stap 13: End-to-end validatie

**Wat**: een complete testronde met een echte, kleine wijziging in elke laag (FE/MW/BE), om te controleren dat scanner → bump → manifest → registry → stack-manifest → capabilities-endpoint → dashboard → deploy-gate allemaal correct samenwerken.

**Waarom**: dit is de validatie-sectie uit het ontwerp, in de praktijk getoetst.

**Opbrengst**: aantoonbaar werkend systeem, met een concreet testverslag in dit logboek.

**Zie ook**: de inmiddels vervulde voorwaarde bij Stap 12 — deze validatieronde moet plaatsvinden met de vers gegenereerde manifesten (via Stap 6a), niet met de oorspronkelijke bootstrap-manifesten uit Stap 6.

**Bevindingen vooraf (2026-09-10)**: bij het voor het eerst bekijken van `/release-dashboard` met echte (ingelogde) gebruikersdata bleek het scherm leeg: "Stack build: Niet beschikbaar", 0 geregistreerde functies, 0 afhankelijkheden, geen stack-manifest. Onderzoek wees uit dat dit geen fout is, maar de correcte weerspiegeling van de huidige staat:
- `function_registry` en `function_dependencies` bevatten 0 rijen (geverifieerd via directe DB-query). In Stap 1 zijn `UpdateFunctionRegistry`/`AddFunctionDependency` gevalideerd met drie tijdelijke testfuncties, die na afloop bewust weer zijn verwijderd. Er bestaat nog geen script dat de echte scanresultaten (44 FE-, 37 MW-, 309 BE-functies) daadwerkelijk via deze sprocs in de registry laadt.
- MW's `/capabilities`-endpoint leest een stack-manifest via de omgevingsvariabele `STACK_MANIFEST_PATH`; deze staat niet in `MW/.env`, dus `stackManifest` is altijd `null`. Het stack-manifest uit Stap 7 is alleen lokaal/handmatig gegenereerd en getest, nooit weggeschreven naar een locatie die MW uitleest.

Conclusie: elk onderdeel (scanners, bump-engine, manifestgenerator, registry-sprocs, capabilities-endpoint, dashboard) is individueel gebouwd en getest, maar nog nooit voor het eerst end-to-end met echte data aan elkaar geregen. Dat is exact waar deze Stap 13 voor bedoeld is; de daadwerkelijke uitvoering (registry vullen + stack-manifest publiceren) staat nog open en wordt in een volgende sessie opgepakt.

**Uitvoering tot en met 2026-09-11**:

- Een echte keten is vastgelegd in `Deploy/versioning/dependencies.json`: `FE:getPersonDetails` → `MW:get_person_details` → `DB:GetPersonDetails_v2`, beide met minimale functieversie `v1`.
- De lokale orchestrator ondersteunt nu het vullen van dependencies via `AddFunctionDependency` en vertaalt de interne BE-laag correct naar de stacklaag DB.
- De compatibiliteitscontrole behandelt ontbrekende functieversies in oudere scanner-manifesten als de afgesproken initiële versie `v1`.
- De lokale Dev-pipeline is opnieuw uitgevoerd met database-sync en exitcode 0.
- Registry-resultaat: 152 functies en 2 dependencies.
- Stack-resultaat: `stackBuildNumber` 5, `compatibilityCheck: passed`, zonder compatibiliteitsfouten.
- MW capabilities-tests: 3 geslaagd. FE Release Dashboard-tests: 2 geslaagd. Deploy-versioning-tests: 14 geslaagd.
- De deploy-gate is opnieuw gecontroleerd tegen de registry met beide echte dependencies en slaagde. Het volledige deployscript is niet gestart; NAS en productie zijn niet benaderd.

**Aanvulling na wijziging-per-laag-test (2026-09-12)**:

- FE-validatie-item toegevoegd in `FE/src/services/familyDataService.js`: `getVersioningValidationProbe`.
- MW-validatie-item toegevoegd in `MW/main.py`: `GET /versioning-validation-probe`.
- DB-validatie-item toegevoegd in `BE/GetVersioningValidationProbe.sql`: `GetVersioningValidationProbe()`.
- De nieuwe procedure is uitsluitend in de lokale Dev-MariaDB geïnstalleerd en gaf `versioning-validation-ok` terug.
- De echte lokale MW-route is met TestClient en de echte Dev-database aangeroepen: HTTP 200 met `ProbeStatus=versioning-validation-ok`.
- De wijziging werd door alle scanners gevonden. De nieuwe componentmanifesten zijn FE `3.0.0` (46 functies), MW `3.0.0` (39 functies) en DB `3.0.0` (311 proceduredefinities).
- De lokale orchestrator liep met database-sync succesvol door met exitcode 0.
- Registry-resultaat: 155 functies en 2 dependencies.
- Stack-resultaat: `stackBuildNumber` 6, `compatibilityCheck: passed`, zonder compatibiliteitsfouten.
- De FE-scanner/dashboardtests, FE-build, MW-tests en Deploy-versioning-tests zijn opnieuw uitgevoerd en geslaagd; de expliciete eind-gate gaf exitcode 0.
- Het deployscript is niet gestart; NAS en productie zijn niet benaderd.
- Stap 13 is hiermee afgerond. De drie geïsoleerde validatie-items blijven in de featurebranch staan als bewijs en testoppervlak van de nieuwe keten.

---

## Stap 14: Verwijderen oude versie-/release-logica (allerlaatste stap)

**Wat**: verwijderen van de in besluit 12 geïnventariseerde oude logica:
- BE: `fe_releases`, `fe_release_changes`, `mw_releases`, `mw_release_changes`, `be_releases`, `be_release_changes`, sproc `GetReleasesByComponent`, de `UpdateVersion_*.sql`-scripts.
- MW: endpoint `GET /GetReleases`, `fetch_releases()`, tests `TestFetchReleases`.
- FE: `getReleases()` in `familyDataService.js`, pagina `FamiliezInfo.jsx`.

**Waarom**: conform het uitgangspunt "oude versie-logica verwijderen als laatste stap" — pas nadat het nieuwe systeem aantoonbaar volledig werkt (stap 13 succesvol afgerond).

**Opbrengst**: schone codebase, geen dubbele/verouderde versie-systemen meer naast elkaar.

**Bestanden**: verwijdering in alle drie de repo's, plus een opruim-SQL-script voor de oude tabellen/sproc.

**Randvoorwaarde**: dit is de **enige** stap waarin bestaande functionaliteit wordt verwijderd — pas uit te voeren met expliciete, aparte toestemming, na succesvolle afronding van stap 13.

**Uitvoering en resultaat (2026-09-12)**:

- Oude FE-pagina `FamiliezInfo.jsx`, route `/familiez-info`, menu-item `Familiez info (oud)` en `getReleases()` zijn verwijderd.
- Oude MW-helper `fetch_releases()` en endpoint `GET /GetReleases` zijn verwijderd; de bijbehorende tests zijn verwijderd.
- Oude BE-sproc `GetReleasesByComponent`, init-SQL, releasehistoriedata en de `UpdateVersion_*.sql`-scripts zijn verwijderd.
- De oude release-tabellen en wijzigingstabellen zijn uit de actieve init-schema's verwijderd.
- Nieuw opruimscript toegevoegd: `BE/RemoveLegacyReleaseLogic.sql`. Dit verwijdert de oude DB-objecten idempotent uit bestaande omgevingen.
- De lokale Dev-database is opgeschoond. Controle bevestigde dat alle zeven oude tabellen en `GetReleasesByComponent` verdwenen zijn.
- `GetFunctionCapabilities` en `GetVersioningValidationProbe` bleven lokaal werken.
- De registry bevat na de cleanup 152 actieve functies, 3 `removed` legacyrecords en 2 dependencies. De oude functies blijven alleen als audit/statushistorie bewaard en worden niet meer door capabilities gepubliceerd.
- De componentmanifesten zijn opnieuw gegenereerd op FE/MW/DB `4.0.0`; de lokale stack is opnieuw opgebouwd met compatibiliteitsstatus `passed`.
- README-database-instructies zijn aangepast van het oude releaseproces naar de lokale versioning-orchestrator.
- Validatie: FE 27 tests en build geslaagd; MW 94 tests geslaagd; BE 8 tests geslaagd; Deploy 14 tests geslaagd.
- Een bronzoekactie vond geen resterende actieve verwijzingen naar de oude release-logica.
- Geen productieomgeving, NAS of deployscript is aangeroepen.

## Stap 15: Database-backed component- en stackmanifesten

**Wat**: de gegenereerde FE-, MW- en DB-componentmanifesten en het compatibele stack-manifest naast de bestaande JSON-release-artifacts ook opslaan in de `humans`-database.

**Waarom**: runtime-componenten moeten de actieve stackstatus kunnen lezen zonder afhankelijk te zijn van een lokaal bestandspad of een Docker-volume tussen `Deploy` en MW.

**Ontwerpbesluit**:

- `function_registry`, `function_dependencies` en `function_registry_audit` blijven ongewijzigd de bron voor functies, dependencies en functieversies.
- Nieuwe componenten gebruiken `FE`, `MW` en `DB`; de bestaande registry blijft `FE`, `MW` en `BE` gebruiken. De DB-component is de manifestrepresentatie van de BE-repository.
- Functieversies blijven integerwaarden in de registry; componentversies blijven semver (`4.0.1`, `5.0.0`).
- JSON-release-artifacts blijven bestaan voor build, review, deploy-gate en rollback. De database bevat de runtimekopie en historie.
- Alleen een manifest met `compatibilityCheck: passed` kan actief worden.

**Uitvoering en resultaat (2026-09-13)**:

- Nieuwe tabellen toegevoegd in `BE/CreateVersioningManifests.sql`: `component_manifests` en `stack_manifests`.
- Nieuwe sprocs toegevoegd: `RegisterComponentManifest`, `PublishStackManifest` en `GetActiveStackManifest`.
- Componentmanifesten worden idempotent geregistreerd met component, semver, image-tag, source-commit, SHA-256 en volledige JSON.
- `PublishStackManifest` supersedeert de vorige actieve stack atomair en activeert alleen een compatibele stack.
- MW `GET /capabilities` leest de actieve stack via `GetActiveStackManifest`; het oude lokale `STACK_MANIFEST_PATH`-bestand is geen runtime-afhankelijkheid meer.
- De lokale orchestrator publiceert na succesvolle stackgeneratie de drie componentmanifesten en de actieve stack naar de database. De JSON-bestanden blijven op hun bestaande paden staan.
- De BE-schema-generator neemt de nieuwe manifesttabellen mee in de reproduceerbare initflow.

**Lokale validatie**:

- MariaDB 10.6.25: tabellen en sprocs succesvol aangemaakt.
- Lokale database-run met venv-interpreter geslaagd.
- Componentmanifesten in database: 3, status `registered`.
- Actieve stackmanifesten in database: 1, `StackBuildNumber=11`, status `active`.
- Registry: 155 functies en 2 dependencies.
- Gegenereerde componentversies: FE `4.0.1`, MW `4.0.1`, DB `5.0.0`.
- Compatibiliteitscontrole: `passed`.
- Lokale MW `/capabilities`: HTTP 200 en stack build 11 zichtbaar.
- MW-tests: 44 geslaagd; Deploy-versioning-tests: 14 geslaagd; BE-versioning-tests: 8 geslaagd.
- `bash -n` op `BE/scripts/prepare-schema.sh`: geslaagd.
- NAS, productie en het deployscript zijn niet aangeroepen.

## Stap 15a: Expliciete releasekeys en DEV→PROD-promotiecontract

**Status**: Ontwerpbesluit toegevoegd op 2026-09-13; implementatie nog niet gestart.

### Aanleiding en correctie op eerdere interpretatie

De bestaande DEV-releaseketen registreert en valideert de release-inhoud al. Er wordt geen tweede ontwikkel- of registratiepipeline gebouwd. DEV blijft de enige bron van waarheid voor alle gewenste veranderingen, inclusief toevoegingen, wijzigingen en verwijderingen.

De eerdere formulering van PROD-import als het opnieuw opbouwen van functies, dependencies en manifesten in PROD was te sterk. PROD ontvangt uitsluitend een gevalideerde promotie van de DEV-release. De technische importstappen bestaan alleen om die DEV-state veilig in de PROD-database toe te passen.

### Expliciete stabiele keys

Database-ID's zoals `FunctionID` en `DependencyID` zijn in het gekozen eindmodel geen onderdeel meer van de functionele release-identiteit en worden volledig uitgefaseerd. Ze worden niet tussen DEV en PROD gekopieerd.

De overdraagbare release-identiteiten worden expliciet en deterministisch:

```text
FunctionKey            FE:getPersonDetails
DependencyKey          FE:getPersonDetails->MW:get_person_details
ComponentManifestKey   FE:4.0.1
StackManifestKey       stack:11
ReleaseKey             release:20260913_153000
```

De keys worden door de release tooling bepaald, niet door een database `AUTO_INCREMENT`. Dezelfde key moet in DEV, de release bundle en PROD behouden blijven.

De gewenste gegevensstructuur is conceptueel:

```text
function_registry
------------------
FunctionKey      expliciete stabiele release-identiteit
Layer
FunctionName
Version
SignatureHash
Status
```

```text
function_dependencies
---------------------
DependencyKey
CallerFunctionKey
CalleeFunctionKey
RequiredMinVersion
```

Foreign keys of equivalente unieke referentieconstraints moeten de expliciete keys bewaken. In het gekozen eindmodel worden `FunctionID`, `CallerFunctionID`, `CalleeFunctionID` en `DependencyID` volledig verwijderd; voor release-export, import en compatibiliteitscontrole zijn uitsluitend expliciete keys leidend.

### Compact besluit

- DEV blijft de bron van waarheid; PROD ontvangt uitsluitend een gevalideerde promotie.
- Audit blijft environment-local en wordt niet standaard geëxporteerd.
- De release bundle bevat expliciete keys, checksum en gewenste state; geen database-ID's.
- PROD importeert via key-gebaseerde registry-/manifest-sprocs en publiceert de stack als laatste.
- De bestaande scanners, bump-engine, manifestgeneratoren en DEV-orchestrator worden niet opnieuw gebouwd.

Benodigd vóór DEV→PROD-promotie: key-schema en sprocs, key-gebaseerde bundle-export/import, PROD-validatie en tests voor key-determinisme, verwijderingen en idempotentie.

## Stap 15b: Migratie van interne FunctionID's naar expliciete keys

**Status**: Ontwerpbesluit toegevoegd op 2026-09-13; implementatie nog niet gestart.

**Gekozen optie**: optie B. `FunctionID` en alle daarvan afhankelijke database-relaties worden volledig verwijderd uit het eindmodel. Expliciete, deterministische keys worden de enige functionele identiteit van functies, dependencies en auditregels.

### Doelmodel

```text
function_registry
------------------
FunctionKey       expliciete stabiele primaire identiteit
Layer
FunctionName
Version
SignatureHash
LastChangedCommit
LastChangedAt
Status
```

```text
function_dependencies
---------------------
DependencyKey
CallerFunctionKey
CalleeFunctionKey
RequiredMinVersion
```

```text
function_registry_audit
-----------------------
AuditID               technische auditidentiteit
FunctionKey           expliciete foreign key naar function_registry
OldVersion
NewVersion
BumpReason
ChangedBy
ChangedAt
```

`FunctionKey` is uniek en immutable. De voorgestelde waarde wordt deterministisch opgebouwd uit laag en functienaam, bijvoorbeeld `FE:getPersonDetails`, `MW:get_person_details` en `BE:GetPersonDetails_v2`. `DependencyKey` wordt deterministisch opgebouwd uit caller- en callee-key, bijvoorbeeld `FE:getPersonDetails->MW:get_person_details`.

De overige release-entiteiten blijven hun expliciete keys gebruiken:

```text
ComponentManifestKey
StackManifestKey
ReleaseKey
```

Alle release bundles, DEV→PROD-promoties, compatibiliteitscontroles en auditverwijzingen gebruiken deze keys. Er is geen fallback naar `FunctionID`.

### Compacte uitvoeringsvolgorde

1. Inventariseer alle ID-gebruikers en leg het keycontract vast.
2. Voeg keys toe, backfill bestaande DEV-data en voeg unieke constraints/foreign keys toe.
3. Migreer sprocs, audit, orchestrator, APIs, FE/MW/Deploy-consumers en exports/imports.
4. Vergelijk oude/nieuwe resultaten en test DEV-herinitialisatie, verwijderingen, idempotentie en key-promotie.
5. Verwijder pas na expliciete goedkeuring alle ID-foreign keys, kolommen, indexes en parameters.
6. Valideer fresh-install, bestaande DEV-migratie, capabilities, dashboard en release bundle.

### Scope van de wijzigingen

BE-schema/sprocs/migratie-SQL, MW capabilities/API en tests, FE dashboard/tests, Deploy-orchestrator/export/import/validatie, init-SQL en documentatie.

### Rollbackgrens

De definitieve verwijdering is DEV-only; bij fouten wordt DEV opnieuw geïnitialiseerd vanuit de schema-/initbestanden. Productiebackup en productie-restore zijn pas vereist bij de latere PROD-migratie. Definitieve kolomverwijdering vereist succesvolle DEV-validatie en expliciete goedkeuring.

---

## Legacy: oorspronkelijke GitHub Actions-stappen (10/11), niet uitgevoerd

**Waarom dit hier staat**: op 2026-09-10 is besloten de triggering/aansturing van het versiesysteem bewust lokaal te houden op de ontwikkelmachine, zonder GitHub Actions. De onderstaande, oorspronkelijke stappen 10 en 11 zijn daarom nooit uitgevoerd en vervangen door Stap 10 (Lokale orchestrator) en de lokale-aanroep-aanvulling bij Stap 12. Deze tekst is ongewijzigd bewaard ter naslag, buiten de actieve stappenrange.

### Stap 10 (optioneel, later): GitHub Actions — component-workflows

**Wat**: per component-repo (FE/MW/BE) een workflow die bij push dezelfde lokaal aanroepbare scripts uitvoert die al in stappen 2 t/m 6 zijn gebouwd (scanner + bump-engine + manifest-generatie + registry-sproc-aanroep), en een `repository_dispatch`-event naar Familiez-Deploy stuurt.

**Waarom**: automatisering van het hele versiebeheer-proces, conform besluit 5/9. Conform besluit 14 is dit een dunne automatiseringslaag bovenop bestaande scripts, geen nieuwe implementatie.

**Opbrengst**: werkende CI per component.

**Bestanden**: nieuwe `.github/workflows/*.yml` per repo (roepen de bestaande scripts uit stap 2/3/4/5/6 aan).

**Randvoorwaarde**: pas te starten nadat Frans zich voldoende vertrouwd voelt met GitHub Actions (expliciet afgesproken in besluit 5) — deze stap wordt dus pas aangeboden na een aparte leerfase, los van dit implementatieplan. Tot die tijd kunnen stappen 0 t/m 9 volledig lokaal/handmatig worden gebruikt (besluit 14).

### Stap 11 (optioneel, later): GitHub Actions — self-hosted runner + orkestrator

**Wat**: inrichten van de self-hosted runner (besluit 5, aanvulling) op een nog te kiezen machine binnen het interne netwerk, en de orkestrerende workflow in Familiez-Deploy die op dispatch-events reageert (besluit 9). Tot deze stap wordt uitgevoerd, wordt de orkestratie/compatibiliteitscheck (stap 7) handmatig lokaal aangeroepen (besluit 14).

**Waarom**: veilige, interne toegang tot de database vanuit CI/CD, en centrale orkestratie van de compatibiliteitscheck.

**Opbrengst**: werkende, veilige koppeling tussen GitHub Actions en de `humans`-database.

**Bestanden**: runner-installatie (buiten repo, op de gekozen machine), orkestrator-workflow in Familiez-Deploy met `concurrency`-instelling.

**Open randvoorwaarde**: welke machine dit wordt (nog te bepalen bij deze stap).

---

## Vervolg na Stap 17: Toekomstige DEV-, promotie- en productie-roadmap

Stap 0 t/m 15 zijn historische implementatiestappen. Stap 16 en 17 zijn afgerond; alleen de reminder bij 17.6 blijft open. De volgende stappen zijn toekomstig en worden afzonderlijk beschreven, ter toestemming aangeboden en daarna gelogd.

### Stap 16: Afrondende documentatie en reviewvoorbereiding

**Status**: Afgerond op 2026-09-13.

**Uitvoering en resultaat**:

- De recente database-backed stackmanifest-opslag is vastgelegd als Stap 15.
- De publieke route `GET /versioning/stack-build` en de FE-weergave van het actieve stack buildnummer zijn aan de reviewscope toegevoegd.
- De recente FE-, MW- en BE-wijzigingen zijn afzonderlijk gecommit en naar `feature/familiez-versioning-system` gepusht.
- De vier repositories staan op de featurebranch en hebben een schone werkboom; Deploy had geen openstaande wijzigingen.
- De lokale validatie is uitgevoerd; NAS en productie zijn niet benaderd.

**Reviewscope voor Stap 17**:

- database-backed component- en stackmanifesten;
- `GetActiveStackBuildNumber`, `/versioning/stack-build` en de loginweergave;
- Release Dashboard, component-accordions en de afhankelijkheidstekst;
- lokale orchestrator en deploy-gate;
- verwijdering van de legacy release-logica;
- branch-, commit-, test- en secretstatus.

### Stap 17: Gezamenlijke code-review van de featurebranches

**Status**: Afgerond met openstaande 17.6-reminder op 2026-09-13.

**Werkwijze voor de reviewpunten**:

- Elk reviewpunt wordt afzonderlijk aangeboden.
- Voor de start van elk punt geeft Frans expliciet aan of uitvoering noodzakelijk is.
- Zonder die expliciete keuze wordt uitsluitend context verzameld of een voorstel beschreven; er wordt niets gewijzigd, gecommit, gepusht, gemerged of uitgerold.
- Na uitvoering wordt het resultaat, inclusief tests en eventuele resterende risico's, hier vastgelegd voordat het volgende punt wordt aangeboden.

**Wat**: de wijzigingen in FE, MW, BE en Deploy gezamenlijk beoordelen, met speciale aandacht voor:

- verwijdering van `Familiez info (oud)` en de oude releasefunctionaliteit;
- `RemoveLegacyReleaseLogic.sql` en de gevolgen voor bestaande databases;
- de lokale orchestrator en deploy-gate;
- de geregistreerde FE → MW → DB-dependencyketen;
- `GetActiveStackBuildNumber`, de publieke `/versioning/stack-build`-route en de loginweergave;
- de database-opslag van component- en stackmanifesten;
- het Release Dashboard, inclusief de componentgerichte inklapbare Function Registry;
- het buiten Git houden van `.env`-bestanden, wachtwoorden en SSH-sleutels.

#### Reviewpunt 17.1: Lokale databasebeschikbaarheid en integratiecontrole

**Status**: Afgerond op 2026-09-13.

Controleren waarom MariaDB tijdens een eerdere review niet via de lokale socket bereikbaar was, en daarna de actieve stackprocedures read-only opnieuw controleren. Daarbij worden de actieve stack, het aantal actieve stackrecords en het buildnummer gecontroleerd. Er wordt geen data gewijzigd.

**Resultaat**:

- Lokale verbinding met MariaDB geslaagd via de bestaande MW-configuratie en niet-root applicatiecredentials.
- MariaDB-versie: `10.6.25-MariaDB-ubu2204`.
- `component_manifests` en `stack_manifests` bestaan.
- `GetActiveStackBuildNumber()` gaf `CompletedOk=0`, `Result=200`, `ErrorMessage=NULL` en `StackBuildNumber=11`.
- `GetActiveStackManifest()` gaf `CompletedOk=0`, `Result=200` en een niet-lege JSON-respons.
- Er is precies één actieve stackmanifestrecord: build `11`, compatibiliteit `passed`, status `active`.
- Een eerste controle rapporteerde tijdelijk build `0` door onjuiste verwerking van meerdere procedure-resultsets; na correcte consumptie van alle resultsets is build `11` bevestigd.
- Er zijn geen data- of schemawijzigingen uitgevoerd. NAS en productie zijn niet benaderd.

#### Reviewpunt 17.2: Publieke stack-buildroute

**Status**: Afgerond op 2026-09-13.

Beoordelen en testen dat `/versioning/stack-build` bewust publiek is en uitsluitend het stack buildnummer teruggeeft. Te controleren situaties: zonder token, databasefout, geen actieve stack en ongeldig procedure-resultaat.

**Resultaat**:

- Ongeauthenticeerde toegang is toegestaan via `PUBLIC_PATHS`.
- Succesrespons: HTTP 200 met uitsluitend `{"stackBuildNumber": 11}`.
- Geen actieve stack: HTTP 200 met `{"stackBuildNumber": null}`.
- Databasefout: HTTP 500 met een generieke foutmelding.
- Ongeldig procedure-resultaat (`CompletedOk != 0`): HTTP 500 met een generieke foutmelding.
- Manifestdata, registrydata en interne databasefoutteksten worden niet aan de client blootgesteld.
- De controle is uitgevoerd met tijdelijke in-memory mocks; er zijn geen bestanden, databases, NAS- of productiesystemen gewijzigd of benaderd.

#### Reviewpunt 17.3: Idempotentie en gelijktijdige publicatie

**Status**: Afgerond op 2026-09-13.

Controleren dat herhaalde registratie van hetzelfde componentmanifest en herhaalde publicatie van dezelfde stack geen ongewenste duplicaten of meerdere actieve stacks veroorzaakt. Gelijktijdige publicatie wordt alleen getest als dat lokaal veilig en noodzakelijk blijkt.

**Resultaat**:

- Herhaalde registratie van hetzelfde tijdelijke componentmanifest resulteerde in maximaal één componentrecord.
- Herhaalde publicatie van dezelfde tijdelijke stack resulteerde in precies één actieve stack.
- Twee gelijktijdige publicaties via afzonderlijke databaseverbindingen slaagden zonder deadlock.
- Na de gelijktijdige publicatie bleef precies één actieve stack over.
- De oorspronkelijke actieve stack is hersteld: build `11`, compatibiliteit `passed`.
- Tijdelijke component- en stacktestrecords zijn verwijderd; resterende tijdelijke records: `0`.
- Een eerste testpoging gebruikte een onjuist hashformaat en werd door de procedurevalidatie afgewezen; na correctie naar exact 64 hextekens zijn alle tests succesvol uitgevoerd.
- Er zijn geen niet-testgegevens, schema's, NAS- of productiesystemen gewijzigd.

#### Reviewpunt 17.4: JSON- en hashconsistentie

**Status**: Afgerond op 2026-09-13.

Controleren dat de canonical JSON-serialisatie en SHA-256-berekening in de lokale orchestrator overeenkomen met de opgeslagen manifestwaarden en de waarden die door MW worden gelezen. Hierbij worden geen productie-artifacts gewijzigd.

**Resultaat**:

- De canonical hashhelpers van de orchestrator en stack-manifestgenerator produceren voor hetzelfde object hetzelfde resultaat.
- FE `4.0.1`, MW `4.0.1` en DB `5.0.0` zijn als `registered` opgeslagen; hun canonical JSON-hashes matchen de actuele componentmanifesten.
- De ruwe teksthashes van componentbestanden verschillen door JSON-opmaak (whitespace/veldvolgorde); de canonical hashes matchen correct.
- Het actieve stackmanifest is valide JSON van type object.
- `compatibilityCheck` in bestand en database is `passed`.
- `stackBuildNumber` in bestand en database is `11`.
- De canonical hash van de opgeslagen stack-JSON matcht `StackManifestSha256` en de stackmanifest-hash.
- Een eerste controle gaf een `null`-compatibiliteitswaarde door een onjuiste JSON-extractiequery; directe JSON-inspectie heeft `passed` bevestigd.
- Componentstatus `registered` is volgens het ontwerp; de actieve runtime-status wordt door `stack_manifests` bepaald.
- Alleen read-only controles uitgevoerd; geen productie-artifacts, databasegegevens of schema's gewijzigd.

#### Reviewpunt 17.5: Lege en fouttoestanden

**Status**: Afgerond op 2026-09-13.

Controleren van de situaties: geen actieve stack, database niet beschikbaar, malformed JSON en ontbrekende capabilities. De loginpagina moet dan gecontroleerd `Build onbekend` tonen en het Release Dashboard mag geen geldige stackstatus suggereren.

**Resultaat**:

- Geen actieve stack of niet-beschikbare middleware/database toont op het login-scherm:
	`Build onbekend (middleware of database niet actief)`.
- Een ongeldige of niet-numerieke stack-buildrespons toont:
	`Build onbekend (ongeldige versie-informatie ontvangen)`.
- De service behandelt malformed JSON en ongeldige payloads als ongeldige versie-informatie.
- Het bestaande Release Dashboard behoudt de lege-manifestweergave en toont geen geldige stackstatus als het manifest ontbreekt.
- De bestaande MW error/capabilities-tests zijn groen: 45 tests geslaagd.
- Nieuwe FE LoginPage-tests controleren de infrastructuurmelding en de melding voor ongeldige versie-informatie: 2 tests geslaagd.
- De bestaande Release Dashboard-tests zijn opnieuw geslaagd: 2 tests.
- FE productie-build is geslaagd.
- Wijzigingen voor dit reviewpunt: `FE/src/pages/LoginPage.jsx`, `FE/src/services/familyDataService.js`, `FE/src/test/LoginPage.test.jsx`.
- Geen productiegegevens, NAS of productiesystemen zijn benaderd.

#### Reviewpunt 17.6: Fresh-install en initflow

**Status**: Afgerond met openstaand integratierisico op 2026-09-13.

> **OPENSTAANDE REMINDER — LATER APART OPPAKKEN**
>
> De volledige fresh-installatie van alle nieuwe versioning-stored procedures is nog niet bewezen. De schema-installatie en tabellen zijn wel succesvol gecontroleerd, maar de geïsoleerde Docker/MariaDB-test blijft tijdens de routine-installatiefase hangen of eindigt in een tijdelijke testharness-/authenticatiefout. Dit moet later als afzonderlijk technisch onderzoek worden opgepakt vóór productie-uitrol. Niet vergeten: controleer daarbij een volledig verse database, de echte initvolgorde, alle procedure-afhankelijkheden en de lege aanroep van `GetActiveStackBuildNumber()`.

Controleren dat een nieuwe database-installatie automatisch de tabellen `component_manifests` en `stack_manifests` plus alle nieuwe versioning-sprocs aanmaakt. Dit gebeurt in een geïsoleerde lokale testomgeving of via statische initcontrole, nooit op productie.

**Resultaat**:

- Statische initcontrole geslaagd: `prepare-schema.sh` neemt `component_manifests` en `stack_manifests` mee.
- Statische initcontrole geslaagd: `prepare-init.sh` neemt de nieuwe versioning-sprocs mee en houdt schema vóór routines.
- Schema-only test in een tijdelijke MariaDB 10.6-container geslaagd: beide manifesttabellen werden aangemaakt.
- De volledige geïsoleerde routine-installatie is niet betrouwbaar afgerond. Meerdere testpogingen werden geblokkeerd door tijdelijke testharnessproblemen bij procedure-aanvoer/afhankelijkheden; de laatste poging faalde al bij authenticatie van de tijdelijke container.
- Daardoor is nog niet bewezen dat alle nieuwe routines in één volledig verse database-installatie worden aangemaakt en aangeroepen.
- Dit is een open integratierisico voor een volledig nieuwe database-installatie, niet een geconstateerde fout in de bestaande ontwikkelomgeving.
- De bestaande ontwikkel-database, repositorybestanden, NAS en productie zijn niet gewijzigd of benaderd.

#### Reviewpunt 17.7: Deploy-gate dry-run

**Status**: Afgerond op 2026-09-13.

Controleren van een positieve en negatieve compatibiliteitscheck van de deploy-gate zonder NAS-SSH, upload, Docker Compose-deployment of andere productieactie. Alleen de gate zelf mag worden aangeroepen.

**Resultaat**:

- Positieve lokale controle met de actuele FE-, MW-, DB-, registry- en stackmanifesten: exitcode `0`, `compatibilityCheck=passed`.
- Negatieve lokale controle met een tijdelijk ongeldig registrybestand: exitcode `2`, `compatibilityCheck=failed` en deployment geblokkeerd.
- Configureerbare manifestpaden zijn gebruikt en correct verwerkt.
- De negatieve controle bereikte geen SSH-, NAS-, rsync-, SCP- of Dockeropdracht.
- Tijdelijke testbestanden zijn verwijderd; repositorybestanden zijn niet gewijzigd.
- Secretcontrole op de testuitvoer: schoon.
- Geen commit, push, merge of productieactie uitgevoerd.

#### Reviewpunt 17.8: Root-secret- en branchhygiëne

**Status**: Afgerond met beperkte eigenaar-review op 2026-09-13.

Controleren dat root `.env.prod` en andere secretachtige bestanden niet in de featurebranches of commits terechtkomen. Als `.env.prod` echte credentials bevat, worden geen waarden gelezen of weergegeven; eventuele rotatie wordt afzonderlijk als operationele actie aangeboden.

**Resultaat**:

- Root staat op `main`, lokaal één commit voor op `origin/main` door de gerichte documentatiecommit.
- Root bevat daarnaast bestaande, afzonderlijke wijzigingen in `.gitignore` en een verwijderd rootbestand; deze zijn niet meegenomen in de documentatiecommit.
- Root `.env.prod` is niet getrackt, maar wordt momenteel niet door de root-ignore-regels afgedekt. Dit is een concreet openstaand secret-hygiënerisico.
- Een naam-/tekstscan van tracked historie vond secretachtige patronen in root (5 commits/28 matches), BE (1 commit/3 matches), MW (13 commits/356 matches), FE (0) en Deploy (1 commit/2 matches). Er zijn geen waarden weergegeven; deze matches kunnen deels false positives zijn en vereisen content-veilige handmatige beoordeling.
- In nested historie werden onder andere `BE/CheckPassword.sql`, `MW/.env.example` en `FE/.env.example` als secretachtige paden gemeld. `.env.example`-bestanden zijn niet automatisch secrets; `CheckPassword.sql` vereist nadere inhoudscontrole zonder waarden bloot te leggen.
- Er zijn geen secretwaarden gelezen of weergegeven en er is geen credentialrotatie uitgevoerd.
- De nested repositories zijn niet gewijzigd door dit reviewpunt; de branch-/upstreamstatus is niet als volledige security-pass vrijgegeven zolang de genoemde matches niet zijn beoordeeld.
- Geen NAS-, productie-, SSH- of remote-wijziging uitgevoerd.

**Uitgevoerde follow-up**:

- Root `.gitignore` aangevuld met een expliciete `.env.prod`-regel; `git check-ignore` bevestigt `.gitignore:13`.
- `.env.prod` bevat 24 niet-lege configuratie-instellingen en 4 secretachtige sleuteltypen. De waarden zijn niet gelezen of weergegeven; rotatie is niet uitgevoerd.
- `BE/CheckPassword.sql` bevat na commentaar- en stringverwijdering geen gedetecteerde secret-literals. Een beperkte eigenaar-review blijft verstandig omdat het bestand password-gerelateerde applicatielogica bevat.
- De historische secretachtige matches zijn geclassificeerd als context-/logicamatches in code, documentatie, voorbeelden en configuratie; er is geen bevestigde gelekte waarde vastgesteld.
- Feature-diffs van BE, MW, FE en Deploy bevatten geen secretachtige bestandspaden.
- Resterend aandachtspunt: eigenaar bevestigt later afzonderlijk de inhoudelijke bedoeling van `BE/CheckPassword.sql` en de historische contextmatches; dit blokkeert de lokale branch-/ignorecontrole niet.

**Opbrengst**: expliciete goedkeuring voor samenvoegen en uitrollen.

**Randvoorwaarde**: geen merge naar `main` of `master` voordat deze review is afgerond.

### Stap 18: DEV-only migratie naar expliciete keys

**Status**: Nog niet gestart.

**Wat**: optie B uitvoeren in DEV: `FunctionID`, `CallerFunctionID`, `CalleeFunctionID` en `DependencyID` vervangen door expliciete keys, inclusief schema, foreign keys, stored procedures, consumers, tests en backfill.

**Herstel bij fout**: DEV-database opnieuw opbouwen vanuit de initiële schema-/initbestanden; geen productiebackup of productieactie.

**Resultaat**: DEV gebruikt uitsluitend expliciete keys en `FunctionID` bestaat niet meer in het eindmodel.

### Stap 19: DEV-release bundle en DEV-validatie

**Status**: Nog niet gestart.

**Wat**: de bestaande DEV-releaseorchestrator gebruiken, een key-gebaseerde release bundle maken en DEV volledig valideren.

**Inhoud**: functies, dependencies, componentmanifesten, stackmanifest, expliciete keys, checksum en compatibiliteitsstatus; geen database-ID’s of auditgeschiedenis.

### Stap 20: DEV→PROD-promotieontwerp en lokale test

**Status**: Nog niet gestart.

**Wat**: release bundle importeren via expliciete keys en bestaande registry-/manifest-sprocs, zonder DEV/PROD-ID-mapping. Eerst testen in een tijdelijke PROD-achtige database; geen productieactie.

### Stap 21: Productiebackup, deployvoorbereiding en gecontroleerde merge

**Status**: Nog niet gestart.

**Wat**: na succesvolle DEV-validatie productiebackup, FE/MW-backup, bundlevalidatie, PR’s en gecontroleerde merges voorbereiden. Geen productie-uitrol in deze stap.

### Stap 22: Gecontroleerde productie-uitrol

**Status**: Nog niet gestart.

**Wat**: na expliciete toestemming de key-gebaseerde DEV-release naar PROD promoten, PROD valideren, FE/MW uitrollen, healthchecks en smoke test uitvoeren. Bij fouten geldt de centrale `Backup/<ReleaseId>/BE|MW|FE`-rollbackprocedure.

**Randvoorwaarden**:

- geen productieactie zonder afzonderlijke expliciete toestemming;
- geen secrets in Git of command-output;
- release bundle, BE/databasebackup en FE/MW-backups moeten gevalideerd en beschikbaar zijn;
- rollbackbeslissing en restoreprocedure moeten vooraf zijn vastgesteld.

### Uitvoeringslog Stap 18: DEV-only migratie naar expliciete keys

**Status**: Voorbereiding en codewijzigingen uitgevoerd; DEV-databasemigratie geblokkeerd vóór uitvoering op 2026-09-14.

**Goedkeuring**:

- Frans heeft op 2026-09-14 expliciet toestemming gegeven voor de volledige DEV-only migratie, inclusief het uiteindelijk verwijderen van `FunctionID`, `CallerFunctionID`, `CalleeFunctionID` en `DependencyID` uit de DEV-database.
- NAS, productie en productiegegevens vallen uitdrukkelijk buiten deze toestemming.

**Stap 18.1 — Inventarisatie**:

- Actief gebruik van de oude ID's is gevonden in `BE/CreateFunctionRegistry.sql`, `BE/UpdateFunctionRegistry.sql`, `BE/AddFunctionDependency.sql`, `BE/GetFunctionCapabilities.sql`, `Deploy/versioning/run_local_release.py` en de bijbehorende Deploy-tests.
- FE en MW hadden geen actieve afhankelijkheid van deze numerieke registry-ID's.
- De oude IDs waren daarmee zowel een database-identiteit als een intern communicatieformaat tussen BE en Deploy; alleen schemawijziging was onvoldoende.

**Stap 18.2 — Key-besluit**:

- `FunctionKey` is deterministisch: `Layer:FunctionName`, bijvoorbeeld `FE:getPersonDetails` en `BE:GetPersonDetails_v2`.
- `DependencyKey` is deterministisch: `CallerFunctionKey->CalleeFunctionKey`.
- Keys zijn ASCII/case-sensitive (`ascii_bin`) en vormen de functionele identiteit tussen DEV, release bundle en later PROD.
- Database-ID's blijven niet bestaan als fallback in het eindmodel.

**Stap 18.3 — Uitgevoerde codewijzigingen**:

- `BE/CreateFunctionRegistry.sql` gebruikt de key-kolommen als primaire en refererende sleutels.
- `BE/UpdateFunctionRegistry.sql` maakt en retourneert `FunctionKey` en schrijft auditregels op basis van die key.
- `BE/AddFunctionDependency.sql` accepteert en retourneert `CallerFunctionKey`, `CalleeFunctionKey` en `DependencyKey`.
- `BE/GetFunctionCapabilities.sql` publiceert `key`, `callerFunctionKey` en `calleeFunctionKey` in plaats van numerieke ID-velden.
- `Deploy/versioning/run_local_release.py` zoekt functies en dependencies op keys en geeft key-waarden door aan de databaseprocedure.
- `Deploy/versioning/test_run_local_release.py` is aangepast aan het key-contract.
- Nieuw migratiescript toegevoegd: `BE/MigrateFunctionRegistryToKeys.sql`. Dit backfillt keys, vervangt constraints, verwijdert de oude ID-kolommen en herstelt key-gebaseerde foreign keys.

**Stap 18.4 — Codevalidatie**:

- BE-versioningtests: 8 geslaagd.
- Deploy-versioningtests: 14 geslaagd.
- `bash -n` voor `BE/scripts/prepare-schema.sh` en `BE/scripts/prepare-init.sh`: geslaagd.
- Statische controle van het migratiescript: geslaagd; backfill, oude constraint-/kolomverwijdering en key-foreign keys zijn aanwezig.
- Actieve codezoekactie vond na de wijziging geen oude capability-velden `callerFunctionId`/`calleeFunctionId` en geen zelfstandige oude ID-symbolen in BE, Deploy, MW of FE, buiten gegenereerde manifest-/documentatiecontext.

**Stap 18.5 — DEV-uitvoering en resultaat**:

- Eerste uitvoeringspoging stopte tijdens validatie omdat het resultaat niet overeenkwam met de verwachte key-gebaseerde capabilities. Een latere gezaghebbende controle toonde dat de actieve DEV-database toen nog volledig het oude schema en de oude proceduredefinitie bevatte; er was dus geen aantoonbare schemawijziging door die poging.
- Tweede, gecontroleerde poging stopte vóór backup en vóór migratie omdat authenticatie als `HumansService` tegen de lokaal draaiende `familiez-mysql`-container faalde.
- Er is geen `/tmp`-backup aangemaakt, omdat de verplichte database-preflight niet slaagde.
- `MigrateFunctionRegistryToKeys.sql` is in de tweede poging niet uitgevoerd.
- De drie gewijzigde procedures zijn niet opnieuw geïnstalleerd.
- Er zijn geen DEV-databasewijzigingen uitgevoerd of opnieuw geprobeerd na de authenticatiefout.
- NAS en productie zijn niet benaderd.

**Aanvulling 2026-09-14 na herstel lokale authenticatie**:

- De lokale verbinding is afzonderlijk opnieuw gecontroleerd: de container `familiez-mysql` draait en zowel root als `HumansService` konden een niet-sensitieve query uitvoeren.
- Er is een backup gemaakt buiten de repository: `/tmp/familiez-step18-b0db637r.sql`, 48.137 bytes. De backup bevat de drie registrytabellen met schema en data; de inhoud is niet in uitvoer weergegeven.
- De eerste migratie-uitvoering stopte op een DDL-fout vóór het opnieuw installeren van procedures. De fouttekst is door de uitvoeromgeving niet bewaard. Read-only controle toont dat de key-kolommen wel zijn toegevoegd en volledig/backfill-correct zijn, maar dat de oude primary keys, unieke indexen en foreign keys nog actief zijn.
- De key-backfill is gecontroleerd: 158 unieke `FunctionKey`-waarden, 2 unieke `DependencyKey`-waarden en correcte dependencykey-samenstelling; auditkeys zijn niet-null. De registry bevat 158 rijen, dependencies 2 rijen en audit 309 rijen.
- Oorzaakcorrectie: het migratiescript is aangepast zodat eerst `UQ_FUNCTION_REGISTRY_KEY` wordt aangemaakt voordat key-gebaseerde foreign keys worden opgebouwd. Dit voorkomt dat MariaDB een foreign key naar een niet-geïndexeerde key afwijst.
- De statische controle van de nieuwe DDL-volgorde is geslaagd.
- Een vervolgpoging kon de resterende DDL niet starten omdat de uitvoeromgeving de lokale `DEV_DB_HOST`, `DEV_DB_USER` en `DEV_DB_PASSWORD` niet meekreeg. Er zijn bij deze poging geen bestanden of databaseobjecten gewijzigd.

**Tussenstand**:

- De migratie is inhoudelijk voorbereid en de data-backfill is aanwezig in DEV, maar Stap 18 is nog niet voltooid.
- De DEV-database bevindt zich in een gedeeltelijke migratiestand: key-kolommen bestaan en zijn gevuld, terwijl de oude ID-kolommen/constraints nog bestaan. De gewijzigde procedures zijn nog niet geïnstalleerd.
- De resterende uitvoering moet plaatsvinden vanuit een omgeving die de bestaande lokale MW-configuratie daadwerkelijk laadt: backup controleren, resterende DDL uitvoeren, procedures installeren en de volledige eindvalidatie herhalen.

**Open blokkade**:

- De lokale MariaDB-container draait, maar de actuele lokale credentials voor `HumansService` worden niet geaccepteerd. Zonder werkende DEV-authenticatie kan de backup-voorwaarde en daarna de migratie niet veilig worden uitgevoerd.
- De repositorycode staat gedeeltelijk op het nieuwe key-contract, terwijl de actieve DEV-database nog op het oude contract staat. De applicatie moet daarom niet als volledig gemigreerd beschouwd worden totdat de procedures en database succesvol zijn bijgewerkt.

**Volgende actie na herstel van de blokkade**:

1. Alleen de lokale DEV-credentials corrigeren of de bestaande lokale databasegebruiker herstellen, zonder secrets in output of Git vast te leggen.
2. Backup maken buiten de repository.
3. `BE/MigrateFunctionRegistryToKeys.sql` één keer uitvoeren.
4. De drie gewijzigde procedures installeren.
5. Keys, constraints, aantallen, idempotentie, capabilities en de lokale orchestrator opnieuw valideren.
6. Daarna de definitieve resultaten en eventuele resterende risico's in dit plan vastleggen.

**Afronding DEV-uitvoering 2026-09-14**:

- De lokale DEV-databaseverbinding is hervat via `127.0.0.1`, database `humans`; credentials zijn niet weergegeven.
- De eerder gemaakte backup `/tmp/familiez-step18-b0db637r.sql` is gecontroleerd en behouden als herstelreferentie.
- De resterende key-migratie is succesvol uitgevoerd. Tijdens de DDL moest rekening worden gehouden met MariaDB `AUTO_INCREMENT`-metadata; dit is lokaal correct afgehandeld.
- `function_registry` gebruikt nu `FunctionKey` als primaire sleutel; `FunctionID` is verwijderd.
- `function_dependencies` gebruikt nu `DependencyKey` als primaire sleutel, `CallerFunctionKey` en `CalleeFunctionKey` als referenties; `DependencyID`, `CallerFunctionID` en `CalleeFunctionID` zijn verwijderd.
- `function_registry_audit` gebruikt nu `FunctionKey` als verwijzing; `FunctionID` is verwijderd. Meerdere auditregels per `FunctionKey` blijven toegestaan en zijn correct als historie behouden.
- Er zijn drie actieve key-gebaseerde foreign keys aanwezig, allemaal verwijzend naar `function_registry.FunctionKey`.
- De drie gewijzigde procedures zijn opnieuw geïnstalleerd vanuit de BE-bronbestanden: `UpdateFunctionRegistry`, `AddFunctionDependency` en `GetFunctionCapabilities`.

**Definitieve validatie**:

- `function_registry`: 158 rijen; geen null- of dubbele `FunctionKey`-waarden.
- `function_dependencies`: 2 rijen; geen null- of dubbele `DependencyKey`-, `CallerFunctionKey`- of `CalleeFunctionKey`-waarden.
- `function_registry_audit`: 309 rijen; geen null-`FunctionKey`-waarden. De vijf groepen met meerdere auditregels per functie zijn verwacht gedrag.
- Oude kolommen `FunctionID`, `DependencyID`, `CallerFunctionID` en `CalleeFunctionID` zijn in de drie registrytabellen afwezig.
- `GetFunctionCapabilities()` gaf geldige JSON terug (`JSON_VALID=1`) met het key-gebaseerde capabilities-contract; volledige JSON is niet in uitvoer getoond.
- BE-versioningtests: 8 geslaagd.
- Deploy-versioningtests: 14 geslaagd.
- Er is geen NAS- of productieverbinding gebruikt.

**Opmerking over uitvoeringsruis**:

- Enkele tussentijdse controles faalden door dotenv-shellparsing, een te strikte routinebloktelling, een boolean-formatteerfout in het validatiescript en een onjuiste PyMySQL `nextset()`-aanroep. Deze fouten hadden geen database-impact; na correctie zijn de routines geïnstalleerd en de inhoudelijke controles geslaagd.

**Stap 18-status**: DEV-only migratie naar expliciete keys afgerond op 2026-09-14. De volgende geplande stap is Stap 19: DEV-release bundle en DEV-validatie. Productiepromotie blijft geblokkeerd totdat Stap 19, 20 en 21 succesvol zijn afgerond en voor Stap 22 afzonderlijke expliciete toestemming is gegeven.

### Uitvoeringslog Stap 19: DEV-release bundle en DEV-validatie

**Status**: Afgerond op 2026-09-14.

**Goedkeuring**:

- Frans heeft op 2026-09-14 met `Akkoord` toestemming gegeven om Stap 19 uit te voeren.
- De uitvoering is beperkt gebleven tot de lokale DEV-database en lokale release-artifacts. NAS en productie zijn niet benaderd.

**Stap 19.1 — Bundlecontract en besluitvorming**:

- De bestaande lokale orchestrator maakt naast de componentmanifesten, registry en stackmanifest nu ook één expliciete `release-bundle.json`.
- De bundle bevat `schemaVersion`, `releaseKey`, `generatedAt`, de drie componentmanifesten (`FE`, `MW`, `DB`), de key-gebaseerde registry en het compatibele stackmanifest.
- De checksum is een canonical SHA-256 over de bundle-inhoud zonder het checksumveld zelf. Hierdoor kan later worden gecontroleerd of de bundle onderweg is gewijzigd.
- Oude database-ID-velden (`FunctionID`, `DependencyID`, `CallerFunctionID`, `CalleeFunctionID` en de oude JSON-velden `id`, `callerFunctionId`, `calleeFunctionId`) worden recursief geweigerd.
- Alleen een stackmanifest met `compatibilityCheck: passed` kan in een bundle worden opgenomen.
- De bundle gebruikt uitsluitend de stabiele keys uit Stap 18; database-ID's en auditgeschiedenis zijn geen onderdeel van de overdraagbare release-identiteit.

**Stap 19.2 — Implementatie**:

- Nieuw bestand: `Deploy/versioning/release_bundle.py`.
- Nieuwe tests: `Deploy/versioning/test_release_bundle.py`.
- `Deploy/versioning/run_local_release.py` is uitgebreid met `--bundle-output` en `--release-key` en schrijft de bundle na succesvolle stackgeneratie.
- De bestaande orchestrator blijft verantwoordelijk voor scanner, bump-engine, manifesten, registry-sync, compatibiliteitscheck en databasepublicatie.
- De bestaande orchestrator-test is aangepast zodat de stackgenerator-mock een compatibel stackmanifest oplevert.

**Stap 19.3 — Validatie vóór DEV-mutatie**:

- Dry-run succesvol uitgevoerd met tijdelijke artifacts; de DEV-database bleef onaangeraakt.
- Bundle bevatte alle verplichte top-level velden en de componenten FE, MW en DB.
- Registry en stackmanifest waren aanwezig en compatibel.
- Checksumformaat en herberekening waren correct.
- Recursieve controle vond geen verboden oude ID-velden.
- Deploy-versioningtests na implementatie: 17 geslaagd.
- Python syntaxcontrole van de nieuwe en aangepaste modules: geslaagd.

**Stap 19.4 — Echte DEV-run**:

- De bestaande lokale orchestrator is uitgevoerd met `--database`.
- Bundle: `Deploy/versioning/release-bundle.json`.
- Registry-artifact: `Deploy/versioning/registry.json`.
- Stack-artifact: `Deploy/versioning/stack-manifest.json`.
- De bundle is aangemaakt met drie componenten: DB, FE en MW.
- Checksumvalidatie is geslaagd met checksum `sha256:d747e8bdded259058998c6cf5158423d0b550366f80a568b3a065cead6d23c85`.
- De bundle bevat een `releaseKey`; deze is aanwezig en wordt door de bundlevalidatie gecontroleerd.
- Registrycontrole: key-fields-only, geen oude ID-velden.
- Stackcompatibiliteit: `passed`.
- Databasecomponent- en stackmanifesten zijn consistent met de lokale artifacts.
- Er is precies één actieve stack; dubbele actieve stacks: 0.
- BE-versioningtests: 8 geslaagd.
- Deploy-versioningtests: 17 geslaagd.
- Eindfouten: 0.

**Stap 19.5 — DEV-conclusie**:

- De huidige DEV-state is verpakt in een controleerbare, key-gebaseerde release bundle.
- De bundle kan als invoer dienen voor de volgende promotiefase, maar is nog niet naar PROD geïmporteerd.
- Productiepromotie blijft geblokkeerd totdat Stap 20 en Stap 21 zijn uitgevoerd en voor Stap 22 afzonderlijke expliciete toestemming is gegeven.

**Stap 19-status**: afgerond op 2026-09-14. De volgende geplande stap is Stap 20: DEV→PROD-promotieontwerp en lokale test.

---

## LEGACY-NASLAG — oorspronkelijke GitHub Actions-stappen 10/11

Deze historische sectie staat bewust helemaal onderaan en maakt geen deel uit van de actuele uitvoeringsvolgorde. Op 2026-09-10 is besloten de aansturing van het versiesysteem lokaal te houden zonder GitHub Actions. De lokale orchestrator en lokale deployflow zijn de actuele aanpak.

### Oorspronkelijke Stap 10: GitHub Actions — component-workflows

Per component-repo zouden workflows de lokaal aanroepbare scanners, bump-engine, manifestgeneratie en registry-aanroepen uitvoeren en daarna een `repository_dispatch` naar Familiez-Deploy sturen. Deze optie is niet uitgevoerd.

### Oorspronkelijke Stap 11: GitHub Actions — self-hosted runner en orchestrator

Een self-hosted runner en centrale dispatch-orchestrator zouden interne database-toegang via CI/CD mogelijk maken. Deze optie is niet uitgevoerd; de gekozen aanpak blijft lokaal en handmatig.

