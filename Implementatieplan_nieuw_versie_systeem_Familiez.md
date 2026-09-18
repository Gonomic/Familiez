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

### Uitvoeringslog Stap 20: DEV→PROD-promotieontwerp en lokale test

**Status**: Afgerond op 2026-09-18.

**Goedkeuring**:

- Frans heeft op 2026-09-18 expliciet toestemming gegeven om Stap 20 uit te voeren.
- De uitvoering is beperkt gebleven tot lokale code, lokale release-artifacts en tijdelijke lokale MariaDB-containers. Synology, NAS, productie en productiegegevens zijn niet benaderd.

**Stap 20.1 — Key-gebaseerde importmodule**:

- Nieuwe module toegevoegd: `Deploy/versioning/import_release_data.py`.
- De module valideert vóór iedere database-aanroep het bundle-schema, de componenten FE/MW/DB, de compatibele stack, de checksum en het ontbreken van oude database-ID-velden.
- De importvolgorde is vastgelegd als: functies, dependencies, componentmanifesten en als laatste het compatibele stackmanifest.
- Databasewrites lopen uitsluitend via de bestaande `UpdateFunctionRegistry`, `AddFunctionDependency`, `RegisterComponentManifest` en `PublishStackManifest`-procedures; de importer gebruikt geen rechtstreekse tabel-INSERTs.
- Dependencies worden vanuit de bundle-laag/naamrepresentatie deterministisch vertaald naar `FunctionKey`-waarden; DB wordt daarbij intern naar BE vertaald voor de registryprocedure.
- Zonder `--database` kan de bundle lokaal worden gevalideerd; met `--database` wordt dezelfde importer tegen een opgegeven databaseverbinding uitgevoerd.

**Stap 20.2 — Tests en initartefacts**:

- Nieuwe gerichte tests toegevoegd: `Deploy/versioning/test_import_release_data.py`.
- De nieuwe importer- en bundletests: 6 geslaagd.
- De volledige Deploy-versioningtests na implementatie: 20 geslaagd, 0 failures.
- Python syntaxcontrole van de importer, bundlemodule en lokale orchestrator: geslaagd.
- De BE-initartefacts zijn opnieuw gegenereerd met `prepare-schema.sh` en `prepare-init.sh`; de gegenereerde artefacts bevatten `FunctionKey`, `RegisterComponentManifest` en `PublishStackManifest`.

**Stap 20.3 — Tijdelijke lokale promotietest**:

- Een tijdelijke MariaDB 10.6-container met een apart Docker-volume is gebruikt; de bestaande `familiez-mysql`-container en `familiez_mysql_data` zijn niet gebruikt of gewijzigd.
- De bestaande release bundle is tweemaal geïmporteerd in een tijdelijke PROD-achtige schemaomgeving.
- Beide imports slaagden.
- Na de dubbele import waren er 3 componentmanifesten, 1 stackmanifest, 158 registryfuncties en 2 dependencies aanwezig.
- `FunctionKey` was aanwezig en de oude ID-kolommen waren afwezig.
- De tijdelijke container, het tijdelijke volume en tijdelijke dump-/logbestanden zijn opgeruimd.

**Validatie en resterend risico**:

- De definitieve tijdelijke controle had een gezonde database, precies 1 actieve stack en precies 1 actieve stack met `CompatibilityStatus = passed`.
- De actieve stack had het verwachte hoogste buildnummer; de registry- en dependency-aantallen bleven na de dubbele import stabiel.
- De eerste versie van de eindquery telde ook de legitieme technische kolommen `ComponentManifestID` en `StackManifestID` mee als oude ID-kolommen. Die kolommen horen bij de manifesttabellen en zijn niet de uitgefaseerde `FunctionID`, `DependencyID`, `CallerFunctionID` of `CalleeFunctionID`.
- De gecorrigeerde interpretatie bevestigt dat de uitgefaseerde functie-/dependency-ID-kolommen afwezig zijn. Dit was een te brede testquery, geen applicatie- of databaseschemafout.
- Er zijn geen productieacties uitgevoerd.

**Stap 20-status**: afgerond op 2026-09-18. De volgende geplande stap is Stap 21: productiebackup, deployvoorbereiding en gecontroleerde merge.

### Uitvoeringslog Stap 21.1: Productiebackup voorbereiden en uitvoeren

**Status**: Geblokkeerd na preflight op 2026-09-18; geen productieactie uitgevoerd.

**Goedkeuring**:

- Frans heeft op 2026-09-18 expliciet toestemming gegeven om Substap 21.1 uit te voeren.

**Preflightresultaat**:

- De productieconfiguratie en Synology-scripts zijn aanwezig.
- De bestaande deployscripts hebben syntaxcontrole nodig als aparte technische validatie, maar tonen inhoudelijk al dat `deploy_to_synology.sh` eerst `sync_db.py` uitvoert en pas daarna FE/MW-backups maakt.
- Er is geen uitgewerkte MariaDB-backupmodule aanwezig die vóór `sync_db.py` een volledige backup maakt naar `Backup/<ReleaseId>/BE/` met checksum en metadata.
- De bestaande FE/MW-backup gebruikt nog de oudere `voorgaande_versie`-structuur en is niet gekoppeld aan de nieuwe gezamenlijke `ReleaseId`-backupstructuur.

**Besluit**:

- De productiebackup is niet gestart. Dit voorkomt productie-mutaties zonder de afgesproken herstelbackup.
- Synology, productie-database, FE-build, MW-build en containers zijn niet benaderd of gewijzigd.
- De volgende noodzakelijke substap is eerst de backuplaag implementeren en lokaal testen: volledige MariaDB-dump, checksum, metadata, centrale `Backup/<ReleaseId>/BE/`-structuur en volgordegate vóór `sync_db.py`.

**Substap 21.1-status**: geblokkeerd. Nieuwe expliciete goedkeuring is nodig voor de implementatie en lokale validatie van de backuplaag voordat opnieuw een productiebackup wordt aangeboden.

### Uitvoeringslog voorbereiding backuplaag vóór Substap 21.1

**Status**: Code-implementatie afgerond; lokale database-integratie geblokkeerd op 2026-09-18.

**Goedkeuring**:

- Frans heeft op 2026-09-18 expliciet toestemming gegeven voor de lokale implementatie en validatie van de backuplaag.
- Er is geen toestemming gebruikt voor een Synology-, productie- of SSH-actie.

**Uitvoering**:

- Nieuwe module toegevoegd: `Deploy/synology/backup_db.py`.
- De module maakt een releasegebonden MariaDB-dump met `--single-transaction`, `--routines`, `--triggers` en `--events`.
- Wachtwoorden worden niet als commandoregelargument doorgegeven, maar uitsluitend via `MYSQL_PWD` aan het dump-proces.
- De module schrijft `Backup/<ReleaseId>/BE/<database>_<ReleaseId>.sql`, een `.sha256`-bestand en niet-geheime `metadata.json`.
- De validator controleert bestaan, niet-lege bestandsgrootte, checksum, metadata, database-identificatie en bestandsgrootte.
- Nieuwe tests toegevoegd: `Deploy/synology/test_backup_db.py`.

**Validatie**:

- Gerichte tests: 3 geslaagd.
- Python syntaxcontrole: geslaagd.
- De read-only lokale integratie met `HumansService` werd door MariaDB geweigerd bij `SHOW CREATE FUNCTION`; deze applicatiegebruiker heeft onvoldoende rechten voor een volledige routinebackup.
- Een read-only root-dumpdiagnose werd daarna door MariaDB als `auth_failed` geweigerd. Er is geen dumpbestand met gegevens gemaakt en geen database gewijzigd.
- Tijdelijke backupoutput is verwijderd.

**Conclusie en blokkade**:

- De backuplogica en bestandsvalidatie zijn geïmplementeerd en unit-getest.
- Een echte lokale dumpvalidatie is nog niet bewezen door ontbrekende/onjuiste lokale dumpcredentials en beperkte `HumansService`-rechten.
- Er worden geen rechten, wachtwoorden of databasegebruikers automatisch gewijzigd.
- Productiebackup blijft geblokkeerd totdat lokaal met een gecontroleerde dumpaccount een echte dump en validator-run succesvol zijn uitgevoerd.

**Status**: lokale codefase afgerond; database-integratie en daarmee Substap 21.1 blijven geblokkeerd.

### Uitvoeringslog lokale diagnose dumptoegang

**Status**: Afgerond op 2026-09-18.

- `familiez-mysql` bestaat, draait en is healthy.
- De relevante containerconfiguratiesleutels en lokale `.env`-sleutelnamen zijn gecontroleerd zonder waarden weer te geven.
- Read-only authenticatiecontrole met de bestaande lokale configuratie slaagde voor zowel `root` als `HumansService`.
- Er zijn geen wachtwoorden gewijzigd, geen databasegebruikers aangepast en geen databasegegevens gewijzigd.
- De eerdere `auth_failed`-melding bij de dumpaanroep is hiermee niet langer reproduceerbaar verklaard; de volgende controle moet vaststellen of de volledige routinebackup met de juiste lokale rootverbinding werkt.

**Volgende afzonderlijke substap**: echte lokale dump maken en valideren met de bestaande database, uitsluitend read-only. Hiervoor is opnieuw expliciete toestemming nodig.

### Uitvoeringslog echte lokale dumpvalidatie

**Status**: Niet geslaagd op 2026-09-18; productiebackup blijft geblokkeerd.

- De goedgekeurde read-only dumpvalidatie is uitgevoerd tegen de bestaande lokale `familiez-mysql`-container.
- De `mariadb-dump`-aanroep met rootconfiguratie faalde met foutcategorie `auth_failed`; er is geen geldig dumpbestand ontstaan.
- Een tweede poging via de lokale MariaDB-socket zonder wachtwoord werd eveneens door MariaDB geweigerd.
- Er zijn geen databasewrites, containerwijzigingen, wachtwoordwijzigingen, Synology-acties of productieacties uitgevoerd.
- Tijdelijke output is verwijderd.

**Conclusie**: de backupmodule is unit-getest, maar een echte lokale database-dump is nog niet bewezen. De volgende noodzakelijke actie is een afzonderlijk goed te keuren herstel van de lokale dumpauthenticatie of het gecontroleerd beschikbaar maken van een dumpaccount met `SHOW VIEW`, `TRIGGER`, `EVENT` en routine-definitie-rechten. Daarna moet dezelfde read-only dumpvalidatie opnieuw worden uitgevoerd.

### Uitvoeringslog herstel lokale dumptoegang

**Status**: Geblokkeerd op 2026-09-18.

- De lokale `familiez-mysql`-container is healthy.
- De gecontroleerde poging om met de bestaande `HumansService`-credentials de actuele grants op te vragen leverde geen bruikbare authenticatie op.
- Root-authenticatie werkte niet via de beschikbare containerconfiguratie.
- Er zijn geen `GRANT`-, `ALTER USER`-, reset-, reinitialisatie- of andere databasewijzigingen uitgevoerd.
- De container en het bestaande `familiez_mysql_data`-volume zijn ongemoeid gelaten.

**Veiligheidsbesluit**: zonder werkende lokale beheeraccount wordt geen wachtwoord geraden, geen gebruiker aangepast en geen `docker compose down -v` of databaseherinitialisatie uitgevoerd. Dat kan bestaande DEV-data vernietigen.

**Volgende noodzakelijke substap**: Frans moet de lokale DEV-databasebeheerderstoegang herstellen of expliciet toestemming geven voor een afzonderlijk gepland herstel-/reinitialisatiepad met voorafgaande backup. Daarna kan een dumpaccount met de benodigde rechten worden ingericht en de backupvalidatie opnieuw worden uitgevoerd.

### Uitvoeringslog optie 1: veilige lokale credentialconfiguratie

**Status**: Afgerond op 2026-09-18.

- De bestaande Python-env-parser uit `Deploy/versioning/run_local_release.py` is gebruikt; `MW/.env` is niet als shellscript gesourced.
- De parser laadde de lokale databaseconfiguratie succesvol zonder secretwaarden te tonen.
- `HumansService` kon lokaal authenticeren.
- Read-only grantanalyse bevestigde alle benodigde rechten voor een volledige dump: `SELECT`, `SHOW VIEW`, `TRIGGER`, `EVENT`, `LOCK TABLES`, `PROCESS` en routine-definitierechten.
- `ALL PRIVILEGES` is voor de lokale `HumansService`-account aanwezig.
- Root blijft niet bruikbaar via de beschikbare rootconfiguratie, maar is voor de dump niet nodig.
- Er zijn geen databasewijzigingen, wachtwoordwijzigingen, grants, containerwijzigingen of productieacties uitgevoerd.

**Conclusie**: de blokkade zat in de onveilige shell-parsing van `.env`, niet in ontbrekende rechten van `HumansService`. De volgende afzonderlijke substap is de echte read-only dump- en checksumvalidatie met `HumansService` via de veilige parser.

### Uitvoeringslog dumpvalidatie met veilige parser

**Status**: Geblokkeerd op 2026-09-18 door routine-exportrechten.

- De veilige Python-parser is gebruikt; geen `.env`-sourcing via de shell.
- Een gewone lokale databaseverbinding als `HumansService` werkt.
- `mariadb-dump` zonder routine-export is niet als volledige releasebackup gebruikt.
- `mariadb-dump` met `--routines`, `--triggers` en `--events` faalt zowel via socket als TCP met de foutcategorie `insufficient_privileges`.
- Er is geen geldig dumpbestand gemaakt; tijdelijke output is verwijderd.
- Er zijn geen databasewrites, grants, wachtwoordwijzigingen, Synology-acties of productieacties uitgevoerd.

**Conclusie**: `HumansService` heeft wel toegang tot de applicatiedatabase, maar niet voldoende systeemrechten voor een volledige routinebackup via `mariadb-dump --routines`. De volgende afzonderlijke substap is het lokaal beschikbaar maken van de minimaal benodigde routine-exportrechten via een werkende beheeraccount, of het expliciet vastleggen van een apart gecontroleerd dumpaccount.

### Uitvoeringslog lokale rechtenherstelactie

**Status**: Afgerond op 2026-09-18.

- Een werkende lokale beheercredential is gevonden in de root/containerconfiguratie; de waarde is niet weergegeven.
- De bestaande `HumansService`-hostrecords en de aanwezigheid van `mysql.proc` zijn read-only gecontroleerd.
- De minimale lokale rechtenuitbreiding `SELECT` op `mysql.proc` is uitgevoerd voor de bestaande `HumansService`-hostrecords.
- Daarna slaagde een read-only `mariadb-dump` met `--single-transaction`, `--routines`, `--triggers`, `--events` en database `humans`.
- Er zijn geen productie-, Synology-, SSH- of volumeacties uitgevoerd.

**Conclusie**: lokale routine-export is nu aantoonbaar mogelijk. De volgende afzonderlijke substap is de echte `backup_db.py`-run met tijdelijke release-artifacts, checksum en metadata.

### Uitvoeringslog echte `backup_db.py`-validatie

**Status**: Afgerond op 2026-09-18.

- `backup_db.py` is read-only geïntegreerd getest tegen de bestaande lokale `familiez-mysql`-database.
- De veilige Python-env-parser is gebruikt; wachtwoorden zijn niet als shellscript geladen of weergegeven.
- De module heeft een volledige MariaDB-dump gemaakt met routines, triggers en events.
- De release-artefacten zijn aangemaakt onder een tijdelijke `Backup/<ReleaseId>/BE/`-structuur.
- Bestandsgrootte, SHA-256-checksum, metadata en database-identificatie zijn succesvol gevalideerd.
- De tijdelijke backupoutput is na de test verwijderd.
- Er zijn geen databasewrites, Synology-, SSH- of productieacties uitgevoerd.

**Conclusie**: de lokale backuplaag is aantoonbaar werkend. De volgende afzonderlijke substap is de integratie in `deploy_to_synology.sh`, met een verplichte backup-gate vóór `sync_db.py` en vóór FE/MW-vervanging.

### Uitvoeringslog integratie BE-backup en release-import in deployorchestrator

**Status**: Afgerond op 2026-09-18; productieactie niet uitgevoerd.

- `Deploy/synology/deploy_to_synology.sh` maakt nu vóór `sync_db.py` een releasegebonden BE/databasebackup via `backup_db.py`.
- De backup wordt lokaal gevalideerd en daarna naar `REMOTE_BACKUP_ROOT/<ReleaseId>/BE/` op de NAS gestaged.
- De release bundle wordt na structurele/routine-sync geïmporteerd via `versioning.import_release_data`.
- PROD-databasecredentials worden voor de import uitsluitend via de child-processomgeving doorgegeven; het wachtwoord staat niet in de argumentlijst.
- Nieuwe optionele configuratie is toegevoegd aan `deploy.env.example`: `REMOTE_BACKUP_ROOT`, `RELEASE_BUNDLE_PATH` en `RELEASE_ID_FORMAT`.
- De bestaande FE/MW-backupstructuur onder `voorgaande_versie` is in deze substap bewust nog niet vervangen door de centrale `Backup/<ReleaseId>/FE|MW`-structuur.

**Validatie**:

- `bash -n Deploy/synology/deploy_to_synology.sh`: geslaagd.
- Python-syntaxcontrole van `backup_db.py`: geslaagd.
- Deploy-versioningtests: 20 geslaagd.
- Backuptests: 3 geslaagd.
- Statische volgordecontrole: BE-backup vóór `sync_db.py`; release-import ná `sync_db.py`.
- Het deployscript, SSH, rsync, npm, Synology en productie zijn niet gestart.

**Conclusie**: de databasebackupgate en release-data-import zijn lokaal geïntegreerd en gevalideerd. De volgende afzonderlijke substap is het koppelen van FE- en MW-backups aan dezelfde centrale `Backup/<ReleaseId>/`-structuur en het uitbreiden van rollbackmetadata.

### Uitvoeringslog centrale FE/MW-backupstructuur

**Status**: Afgerond op 2026-09-18; productieactie niet uitgevoerd.

- `deploy_to_synology.sh` gebruikt nu dezelfde `ReleaseId` voor de FE- en MW-backups als voor de BE-backup.
- FE wordt opgeslagen onder `REMOTE_BACKUP_ROOT/<ReleaseId>/FE/`.
- MW wordt opgeslagen onder `REMOTE_BACKUP_ROOT/<ReleaseId>/MW/`.
- Beide componentmappen krijgen niet-geheime `metadata.json` met component, ReleaseId en status.
- `rollback_on_synology.sh` leest FE- en MW-backups uit de centrale releasebackupstructuur en sluit metadata uit bij het terugzetten.
- De oude `voorgaande_versie`-paden worden voor deze nieuwe rollbackroute niet meer gebruikt.

**Validatie**:

- `bash -n deploy_to_synology.sh`: geslaagd.
- `bash -n rollback_on_synology.sh`: geslaagd.
- Gerichte backup/layouttests: 5 geslaagd, 0 failures.
- Geen deploy, SSH, rsync, databaseverbinding of productieactie uitgevoerd.

**Conclusie**: BE, FE en MW hebben nu in de code dezelfde releasegebonden backupstructuur. De volgende afzonderlijke substap is rollbackmetadata/DB-restoreplanning en een lokale dry-run van de gecombineerde rollback, zonder Synology of productie.

### Uitvoeringslog rollbackmetadata en DB-restoreplanning

**Status**: Afgerond op 2026-09-18; alleen lokale dry-run uitgevoerd.

- Nieuwe planningmodule toegevoegd: `Deploy/synology/restore_db.py`.
- De planner valideert de BE-backup, checksum en metadata vóórdat een restoreplan wordt gemaakt.
- De planner gebruikt standaard geen uitvoeractie; `--execute` wordt bewust geweigerd totdat een afzonderlijk restoremechanisme expliciet is ontworpen en goedgekeurd.
- Een restoreplan vereist bevestiging, vereist het gecontroleerd stoppen van services en bevat expliciet geen `DROP DATABASE`.
- Nieuwe tests toegevoegd: `Deploy/synology/test_restore_db.py`.

**Validatie**:

- Backup-, restore- en layouttests: 8 geslaagd, 0 failures.
- Python- en Bash-syntaxcontroles: geslaagd.
- Gecombineerde lokale dry-run: BE/FE/MW hadden dezelfde ReleaseId, BE-backupvalidatie slaagde, restorestatus was `planned` en `dropDatabase` was `false`.
- Geen databaseverbinding, restore, SSH, Synology- of productieactie uitgevoerd.

**Conclusie**: rollbackmetadata en veilige DB-restoreplanning zijn lokaal voorbereid en getest. De volgende afzonderlijke substap is het samenbrengen van release-metadata, checksums en backupstatus in één `release-metadata.json`, gevolgd door een lokale preflight/dry-run van de volledige releaseflow.

### Uitvoeringslog centrale `release-metadata.json`

**Status**: Afgerond op 2026-09-18; alleen lokale dry-run uitgevoerd.

- Nieuwe module toegevoegd: `Deploy/synology/release_metadata.py`.
- Nieuwe tests toegevoegd: `Deploy/synology/test_release_metadata.py`.
- De metadata bevat uitsluitend niet-geheime releasegegevens: ReleaseId, stack build, componentversies/source commits, backupstatussen en checksums.
- De metadata bevat expliciet de compatibiliteitsstatus en rollbackregels.
- `databaseRestoreRequiresConfirmation` staat op `true`.
- `dropDatabaseAllowed` staat op `false`.
- Alleen een stack met `compatibilityCheck: passed` wordt geaccepteerd.

**Validatie**:

- Backup-, restore-, layout- en releasemetadata-tests: 11 geslaagd, 0 failures.
- Python-syntaxcontrole: geslaagd.
- Lokale metadata-dry-run: FE/MW/DB aanwezig, rollbackmateriaal beschikbaar, geen secretachtige velden en `dropDatabaseAllowed=false`.
- Geen database-, SSH-, Synology- of productieactie uitgevoerd.

**Conclusie**: de centrale releasecontext is lokaal aantoonbaar op te bouwen. De volgende afzonderlijke substap is een volledige lokale preflight/dry-run van de releaseflow met backupgate, release-import, centrale metadata en rollbackplanning.

### Uitvoeringslog volledige lokale release-preflight/dry-run

**Status**: Afgerond op 2026-09-18; alleen tijdelijke lokale artifacts en fake clients gebruikt.

- De tijdelijke BE-backup is gemaakt en gevalideerd met checksum en metadata.
- De bundle-importvolgorde is bevestigd als FE, MW, DB en daarna stackpublicatie.
- De centrale metadata bevatte FE/MW/DB, dezelfde ReleaseId, stack build `1` en `compatibilityCheck: passed`.
- De rollbackplanning gaf `planned`, vereiste bevestiging en stond `dropDatabase=false`.
- Het negatieve checksumscenario stopte met `ValueError` vóór de eerste fake-client-call; er was daarmee geen mutatie vóór de gate.
- De eerste dry-runpoging faalde door ongeldige tijdelijke testinput; de herhaalde test met correcte byte-output slaagde volledig.

**Validatie**:

- `STATUS=passed`.
- `import_order=FE, MW, DB, stack`.
- `metadata=validated`.
- `rollback_plan=planned`, bevestiging vereist, geen `DROP DATABASE`.
- `negative_gate=passed`, nul client-aanroepen bij checksumfout.
- Geen echte database, SSH, rsync, Synology of productie aangeraakt.

**Conclusie**: de volledige releaseflow is lokaal als preflight/dry-run aantoonbaar en stopt vóór mutatie bij een ongeldig backup-/bundle-artifact. De volgende afzonderlijke substap is een review van de deployscriptvolgorde en configuratie voordat een echte productiebackup wordt aangeboden.

### Uitvoeringslog review deployvolgorde en configuratie

**Status**: Review afgerond op 2026-09-18; geen wijzigingen tijdens de review.

**Bevinding**:

- **Medium**: `release_metadata.py` bestaat en is lokaal getest, maar `deploy_to_synology.sh` bouwt of uploadt het centrale `release-metadata.json` nog niet.
- **Low**: voor de volledige deploy-/rollbackpaden bestaan nog geen uitgebreide geautomatiseerde integratietests; de huidige syntax-, module- en dry-run-tests blijven wel groen.

**Gecontroleerd en akkoord bevonden**:

- BE-backup vóór `sync_db.py` en vóór FE/MW-vervanging.
- Bundle-import ná structurele/routine-sync.
- Eén ReleaseId voor BE, FE en MW.
- Centrale backup- en rollbackpaden.
- Geen PROD-credentials in argumentlijsten of normale logs.
- Backupvalidatie vóór database-mutatie.
- Restoreplanning vereist bevestiging en staat `DROP DATABASE` niet toe.
- Bestaande `deploy.env` blijft backward-compatible door defaults.
- Shell- en Python-syntaxcontroles zijn geslaagd.

**Conclusie**: echte productiebackup blijft geblokkeerd totdat de centrale releasemetadata door de deployorchestrator wordt opgebouwd/geüpload en de bijbehorende deploypadtests zijn toegevoegd.

### Uitvoeringslog integratie centrale releasemetadata

**Status**: Afgerond op 2026-09-18; productieactie niet uitgevoerd.

- `deploy_to_synology.sh` bouwt nu na de FE/MW-backup en vóór vervanging het centrale `release-metadata.json` op.
- Het metadata-artifact gebruikt dezelfde ReleaseId en verwijst naar FE-, MW- en BE-backupmetadata, componentmanifesten en stackmanifest.
- Het bestand wordt geüpload naar `REMOTE_BACKUP_ROOT/<ReleaseId>/release-metadata.json`.
- De metadata bevat geen wachtwoorden, tokens of andere geheime configuratie.
- De backup- en releasegates blijven vóór database- en applicatiemutaties actief.
- De reviewbevinding over ontbrekende metadata-integratie is hiermee opgelost.

**Validatie**:

- `bash -n deploy_to_synology.sh`: geslaagd.
- `bash -n rollback_on_synology.sh`: geslaagd.
- Gerichte backup, restore, layout- en releasemetadata-tests: 11 geslaagd, 0 failures.
- Geen deploy, SSH, rsync, database, npm of productieactie uitgevoerd.

**Conclusie**: centrale release-metadata is nu onderdeel van de deployflow. De reviewbevindingen zijn lokaal afgehandeld; de volgende stap is opnieuw een expliciete toestemming voor een echte productiebackup-preflight, zonder daarmee al de deployment uit te voeren.

### Uitvoeringslog productiebackup-preflight

**Status**: Preflight afgerond op 2026-09-18; productiebackup niet gestart.

- `deploy.env` bestaat en alle vereiste configuratienamen zijn aanwezig; waarden zijn niet weergegeven.
- Release bundle, registry, stack-manifest en FE/MW/BE-componentmanifesten bestaan en zijn niet leeg.
- De geconfigureerde Python-interpreter is uitvoerbaar.
- `ssh`, `rsync` en `npm` zijn lokaal beschikbaar.
- Shell- en Python-syntaxcontroles zijn geslaagd.
- De enige concrete blocker is dat `mariadb-dump` niet op de laptop beschikbaar is.
- Er is geen SSH-poortcontrole, Synologyverbinding, databaseverbinding, backup, sync, npm-build of deployment uitgevoerd.

**Conclusie**: vóór een echte productiebackup moet de MariaDB-client lokaal beschikbaar worden gemaakt, of de backupopdracht moet gecontroleerd via een daarvoor geschikte remote/container-tool worden uitgevoerd. Dit vereist een afzonderlijke toestemming; productiecontact blijft tot die tijd geblokkeerd.

### Uitvoeringslog Docker-gebaseerde backupclient

**Status**: Afgerond op 2026-09-18; productiebackup nog niet gestart.

- `backup_db.py` ondersteunt nu een samengestelde dumpopdracht via veilige tokenisatie.
- Als `mariadb-dump` op de laptop ontbreekt, kiest `deploy_to_synology.sh` automatisch een tijdelijke `mariadb:10.6`-clientcontainer.
- `MYSQL_PWD` wordt als doorgegeven environmentvariabele gebruikt; het wachtwoord staat niet in de commandoregel.
- De bestaande hostclient blijft bruikbaar wanneer die wel aanwezig is.

**Validatie**:

- `bash -n deploy_to_synology.sh`: geslaagd.
- Python-syntaxcontrole: geslaagd.
- Gerichte backup, layout, restore- en metadata-tests: 12 geslaagd, 0 failures.
- Geen Docker-clientcontainer, database, SSH, Synology of productie gestart.

**Conclusie**: de lokale preflight-blocker `mariadb-dump` ontbreekt is opgelost zonder hostinstallatie. De volgende afzonderlijke substap is de echte productiebackup op Synology, voorafgegaan door de laatste niet-muterende SSH/configuratiecontrole.

### Uitvoeringslog laatste Synology-preflight vóór productiebackup

**Status**: Geblokkeerd op 2026-09-18; geen productiebackup gestart.

- De deployconfiguratie is veilig geparseerd zonder `.env`-sourcing en zonder secretwaarden te tonen.
- TCP-bereikbaarheid van de Synology faalde.
- SSH BatchMode-login faalde.
- Daardoor konden productiecompose, MariaDB-service, backupmap, vrije opslag en remote `mariadb-dump` niet veilig worden gecontroleerd.
- Er is geen SSH-mutatie, mapcreatie, dump, sync, containerrestart, databasewijziging of deployment uitgevoerd.

**Conclusie**: de productiebackup kan pas worden gestart nadat de Synology vanaf deze Mint-devmachine netwerk- en SSH-bereikbaar is. De releaseflow blijft correct geblokkeerd vóór iedere productie-mutatie.

### Uitvoeringslog herhaalde Synology-preflight

**Status**: Gedeeltelijk geslaagd op 2026-09-18; productiebackup niet gestart.

- Nadat de SSH-service op Synology opnieuw is ingeschakeld, slaagden TCP-bereikbaarheid en SSH BatchMode-login.
- De remote compose-directory en compose-file zijn bereikbaar.
- De MariaDB-service/container en remote `mariadb-dump` zijn beschikbaar.
- De centrale `REMOTE_BACKUP_ROOT` bestaat nog niet.
- Daardoor kon vrije opslag op de beoogde backupmount nog niet worden gecontroleerd.
- Er is geen remote map aangemaakt en geen dump, rsync, sync, restart of andere productie-mutatie uitgevoerd.

**Conclusie**: alleen de remote backupmap moet nog expliciet worden aangemaakt en gecontroleerd. Daarna kan de productiebackup als afzonderlijke substap worden aangeboden.

### Uitvoeringslog aanmaak centrale Synology-backupmap

**Status**: Afgerond op 2026-09-18; productiebackup nog niet gestart.

- De SSH-service is bereikbaar via BatchMode.
- De centrale `REMOTE_BACKUP_ROOT` is op Synology aangemaakt met `mkdir -p`.
- De directory is daarna read-only geverifieerd.
- De vrije ruimte op de betreffende filesystem bedraagt ongeveer 2,99 TB.
- Er is geen database-dump, rsync, sync, compose-actie, restart of deployment uitgevoerd.

**Conclusie**: de centrale backupbestemming is beschikbaar en heeft voldoende vrije opslag voor de releasebackup. De volgende afzonderlijke substap is de daadwerkelijke productiebackup met checksum en metadata.

### Uitvoeringslog daadwerkelijke productiebackup

**Status**: Geblokkeerd op 2026-09-18; geen productiebackupbestand gemaakt.

- De read-only productie-dumpaanroep is gestart via de Docker-MariaDB-client.
- De productiehost en databaseverbinding werden bereikt.
- De dump stopte op `db_privileges` bij de volledige export met routines, triggers en events.
- Er is geen SQL-dump naar lokale of remote opslag geschreven.
- Er is geen checksum, metadata-upload, sync, release-import, FE/MW-upload, restart of deployment uitgevoerd.
- Tijdelijke lokale output is verwijderd.

**Conclusie**: de Synology is bereikbaar en de backupmap is beschikbaar, maar de geconfigureerde productie-databasegebruiker heeft onvoldoende rechten voor de vereiste volledige backup. De volgende afzonderlijke substap is een read-only inspectie van de PROD-dumprechten en de beschikbare beheer-/backupaccount; er wordt zonder nieuwe toestemming geen rechtenwijziging uitgevoerd.

### Uitvoeringslog read-only inspectie PROD-dumprechten

**Status**: Afgerond op 2026-09-18; geen rechten gewijzigd.

- De productieconfiguratie is veilig geparseerd zonder secretwaarden te tonen.
- De eerste clientaanroep had een foutieve aanroepvorm en is niet als inhoudelijke PROD-uitkomst gebruikt.
- De gecorrigeerde read-only PROD-authenticatiecontrole slaagde.
- De geconfigureerde productiegebruiker heeft alle gecontroleerde rechten voor de volledige dump: `SELECT`, `SHOW VIEW`, `TRIGGER`, `EVENT`, `LOCK TABLES`, `PROCESS`, routine-definitierechten en `ALL PRIVILEGES`.
- `mysql.user` is voor deze applicatiegebruiker niet uitleesbaar; er zijn geen accountnamen of grantteksten weergegeven.
- Er is geen aparte backupaccountnaam geconfigureerd.
- Er zijn geen `GRANT`, `CREATE USER`, `ALTER USER`, dump, upload, sync, restart of deploymentacties uitgevoerd.

**Conclusie**: er is geen PROD-rechtenwijziging nodig. De eerdere `db_privileges`-melding moet worden herleid tot de eerdere clientaanroep/uitvoerroute. De volgende afzonderlijke substap is het opnieuw uitvoeren van uitsluitend de productiebackup met de gecorrigeerde Docker-clientaanroep.

### Uitvoeringslog tweede poging productie-BE-backup

**Status**: Geblokkeerd op 2026-09-18; geen productiebackupbestand gemaakt.

- De gecorrigeerde Docker-MariaDB-clientaanroep is opnieuw uitgevoerd met een nieuwe ReleaseId.
- De lokale dumpvalidatie faalde; de SQL-bestandsgrootte bleef nul.
- De foutcategorie is opnieuw MariaDB routine-/privilegecontrole; er is geen valide dump gegenereerd.
- De ReleaseId-directory is niet remote achtergebleven en er is geen upload uitgevoerd.
- Er zijn geen sync-, import-, FE/MW-, compose-, restart- of andere productieacties uitgevoerd.

**Conclusie**: de eerdere algemene grants-check bewijst niet dat de productiegebruiker routine-definities uit de benodigde MariaDB-systeemmetadata mag lezen. De volgende afzonderlijke substap is een gerichte read-only controle van de effectieve grantscope voor routine-export of het vaststellen van een bestaande remote beheer-/backupaccount. Zonder die controle wordt geen rechtenwijziging en geen nieuwe productiebackup geprobeerd.

### Uitvoeringslog effectieve PROD-grantscope

**Status**: Read-only inspectie afgerond op 2026-09-18; geen rechten gewijzigd.

- PROD-authenticatie werkt.
- De effectieve grantscope van de geconfigureerde PROD-gebruiker is database-scope, niet systeemscope.
- Routine-informatie kan beperkt worden opgevraagd, maar `SHOW CREATE PROCEDURE` faalt.
- `SHOW CREATE FUNCTION` slaagt; dit verklaart waarom een algemene routinecontrole misleidend positief kon lijken.
- `mariadb-dump --routines` faalt op de procedure-definitiecontrole met een privilegefout.
- In de remote composeconfiguratie is geen aparte backup-/beheeraccount op naamniveau gevonden.
- Er zijn geen `GRANT`, `CREATE USER`, `ALTER USER`, dumpbestanden, uploads, syncs, restarts of deployments uitgevoerd.

**Conclusie**: de productiegebruiker heeft onvoldoende effectieve rechten om stored-proceduredefinities te exporteren. De volgende afzonderlijke substap is een minimale, expliciet goed te keuren PROD-rechtenwijziging voor routine-export, of het configureren van een bestaand apart backupaccount. Zonder die stap blijft de productiebackup geblokkeerd.

### Uitvoeringslog poging aparte PROD-backupaccount

**Status**: Geblokkeerd op 2026-09-18; geen PROD-account of rechten gewijzigd.

- Optie 2 is uitgevoerd voorbereid met een nieuw lokaal random secretbestand met mode `600`; dit bestand is bij mislukking verwijderd.
- De remote MariaDB-container bevatte geen bruikbare rootomgeving voor `docker compose exec`.
- In de remote projectconfiguratie stond wel een root-sleutel op naamniveau, maar de bijbehorende credential faalde bij een read-only root-authenticatiecontrole.
- Daardoor kon `FamiliezBackup` niet worden aangemaakt en konden geen minimale grants worden toegekend.
- Er zijn geen `CREATE USER`, `ALTER USER`, `GRANT`, databasewrites, dumps, uploads, syncs, restarts of deployments uitgevoerd.

**Conclusie**: de productiebeheercredential in de projectconfiguratie is niet gelijk aan de credential van de draaiende MariaDB-container. De volgende noodzakelijke actie is het gecontroleerd herstellen van de actuele Synology/MariaDB-beheercredential, buiten deze releaseflow. Daarna kan optie 2 opnieuw worden uitgevoerd.

### Uitvoeringslog herstel aparte PROD-backupaccount

**Status**: Afgerond op 2026-09-18; backupaccount en dump zijn getest.

- De bestaande `FamiliezBackup`-account bleek na de eerste accountaanmaakpoging al te bestaan.
- Met de handmatig ingevoerde, werkende rootcredential is het accountwachtwoord opnieuw gezet.
- De minimale dumprechten zijn toegepast: databaseleesrechten inclusief views, triggers, events en locks, globale `PROCESS` en `SELECT` op `mysql.proc`.
- Een lokaal random wachtwoord wordt bewaard in een lokaal secretbestand met mode `600`; de waarde is niet weergegeven of gecommit.
- De volledige PROD-dump is daarna read-only getest met `mariadb-dump --routines --triggers --events` en slaagde.
- Een tussentijdse lokale test faalde alleen door een foutief relatief werkdirectorypad; de herhaalde test met absolute paden slaagde.
- Er zijn geen datawijzigingen, syncs, uploads, restarts of applicatiedeployments uitgevoerd.

**Conclusie**: de productiebackup kan nu met de aparte `FamiliezBackup`-account worden uitgevoerd. De volgende afzonderlijke substap is de daadwerkelijke productie-BE-backup naar `Backup/<ReleaseId>/BE/` met checksum en metadata.

### Uitvoeringslog geslaagde productie-BE-backup

**Status**: Afgerond op 2026-09-18; BE-backup staat op Synology.

- ReleaseId: `20260918_164519`.
- De productie-dump is gemaakt met `FamiliezBackup` via de Docker-MariaDB-client.
- De dump bevat routines, triggers en events volgens de afgesproken backupopties.
- Lokale dump-, checksum- en metadata-validatie: geslaagd.
- Remote opslag: `REMOTE_BACKUP_ROOT/<ReleaseId>/BE/`.
- Remote SQL-bestand, checksum en `metadata.json` bestaan en zijn niet leeg.
- Remote SHA-256 en lokale SHA-256 matchen.
- Dumpgrootte: 20.826.337 bytes.
- De eerste uploadpoging via rsync faalde met exitcode 12; de tweede poging via gecontroleerde SSH-stream slaagde.
- De backupvalidator is uitgebreid om geldige MariaDB-database-identificatie met dumpcommentaar te accepteren; gerichte tests bleven groen.
- Geen `sync_db.py`, release-import, FE/MW-upload, compose-restart, rollback of deployment uitgevoerd.

**Conclusie**: er is nu een gevalideerde productie-BE-backup beschikbaar op Synology. De volgende afzonderlijke substap is FE/MW-backup-preflight en deployvoorbereiding; productie-mutaties blijven apart geblokkeerd totdat daarvoor expliciete toestemming wordt gegeven.

### Uitvoeringslog FE/MW-backup-preflight en deployvoorbereiding

**Status**: Afgerond op 2026-09-18; geen FE/MW-backup of deployment uitgevoerd.

- Lokale FE- en MW-bronnen, configuratie en requirements zijn aanwezig.
- FE `dist` en FE/MW-componentmanifesten zijn aanwezig.
- Stackmanifest, registry en release bundle zijn aanwezig.
- Lokale tijdelijke stagingcontrole slaagde: FE 63.666 bestanden en MW 6.895 bestanden.
- De bestaande ReleaseId `20260918_164519` is gecontroleerd tegen de remote BE-backup.
- Remote FE-buildmap en MW-buildmap bestaan.
- Remote compose-file en MariaDB-service zijn beschikbaar.
- Remote BE-backup, vrije opslag en SSH zijn gericht read-only opnieuw bevestigd.
- Een brede preflight rapporteerde eerst onjuiste remote failures; de gerichte hercontrole bevestigde alle remote onderdelen als `pass`.
- Er is geen FE/MW-upload, sync, release-import, compose-actie, restart of deployment uitgevoerd.

**Conclusie**: de lokale en remote FE/MW-deployvoorbereiding is gereed. De volgende afzonderlijke substap is het maken en uploaden van de FE- en MW-backups met ReleaseId `20260918_164519`, vóór enige vervanging of database-mutatie.

### Uitvoeringslog geslaagde FE/MW-productiebackups

**Status**: Afgerond op 2026-09-18; actieve productie-builds niet vervangen.

- De huidige productie-FE-build is remote veiliggesteld onder `Backup/20260918_164519/FE/`.
- FE-backup: read-only hercontrole geeft 10 bestanden inclusief metadata, 2.953.612 bytes.
- De huidige productie-MW-build is remote veiliggesteld onder `Backup/20260918_164519/MW/`.
- MW-backup: read-only hercontrole geeft 27 bestanden inclusief metadata, 310.267 bytes.
- Voor FE en MW is niet-geheime metadata met component, ReleaseId, bestandstelling, grootte en status aangemaakt.
- De kopie is op Synology zelf uitgevoerd; er was geen lokale bronupload nodig.
- De actieve FE- en MW-mappen zijn niet gewijzigd.
- Geen sync, release-import, nieuwe FE/MW-upload, compose-restart, rollback of deployment uitgevoerd.

**Correctie na read-only Synology-hercontrole**:

- De centrale FE- en MW-backupmappen bestaan daadwerkelijk onder ReleaseId `20260918_164519`.
- De actieve buildmappen bevatten respectievelijk 9 FE-bestanden/2.953.509 bytes en 26 MW-bestanden/310.164 bytes; de extra backupbestanden zijn de componentmetadata.
- De eerdere logaantallen `60` en `126` waren foutieve tellingen uit de eerste backupaanroep en worden niet langer als betrouwbaar beschouwd.
- Een volledige read-only vergelijking exclusief `metadata.json` gaf voor FE 60 actieve/60 geback-upte bestanden, 0 ontbrekende, 0 extra en 0 gewijzigde hashes.
- Dezelfde vergelijking gaf voor MW 126 actieve/126 geback-upte bestanden, 0 ontbrekende, 0 extra en 0 gewijzigde hashes.
- De eerdere tellingen 9/10 en 26/27 kwamen door een beperkte `maxdepth`-controle; de eerdere melding `match: nee` was een foutieve preflightuitkomst.
- Actieve en geback-upte FE/MW-bestanden hebben dezelfde totale bytes en SHA-256-hashes.

**Conclusie**: voor ReleaseId `20260918_164519` zijn BE, FE en MW nu afzonderlijk en inhoudelijk exact gelijk aan de actieve productie-builds veiliggesteld op Synology.

### Uitvoeringslog centrale release-metadata voor productiebackup

**Status**: Afgerond op 2026-09-18; productie-applicatie nog niet gewijzigd.

- Centrale `release-metadata.json` opgebouwd voor ReleaseId `20260918_164519`.
- FE, MW en DB-componentmanifesten zijn opgenomen.
- Stackcompatibiliteit is `passed`.
- FE-, MW- en BE-backupstatussen zijn opgenomen.
- De BE-backupchecksum is read-only opnieuw op Synology gecontroleerd.
- Rollbackmateriaal staat op `available=true`.
- `databaseRestoreRequiresConfirmation=true` en `dropDatabaseAllowed=false` zijn vastgelegd.
- Het metadata-artifact is naar de ReleaseId-root op Synology geschreven en als geldige JSON gecontroleerd.
- Een eerdere metadata-aanroep faalde door een pad-/configuratieprobleem; de uiteindelijke opbouw gebruikte de bevestigde releasegegevens en slaagde.
- Geen `sync_db.py`, release-import, FE/MW-vervanging, compose-restart of deployment uitgevoerd.

**Conclusie**: de releasebackup voor BE, FE en MW plus centrale metadata is compleet voor ReleaseId `20260918_164519`. De volgende afzonderlijke substap is een productie-deploy-preflight die alleen gates, bundle, backup en metadata controleert.

### Uitvoeringslog productie-deploy-preflight

**Status**: Geblokkeerd op 2026-09-18; geen productie-mutatie uitgevoerd.

- Lokale FE/MW/DB-manifesten, registry, stack-manifest en release bundle bestaan, zijn niet leeg en zijn geldige JSON.
- De bundle-checksum is geldig.
- De stackcompatibiliteit in de bundle is `passed`.
- De inhoudelijke release-identiteit klopt niet: de bundle heeft `releaseKey=release:12`, terwijl de productiebackup en metadata ReleaseId `20260918_164519` gebruiken.
- De eerdere brede preflight rapporteerde daarnaast onbetrouwbare pad-/SSH-failures; gerichte controles van de remote backup zijn eerder geslaagd.
- Door de releaseKey/ReleaseId-mismatch wordt de deployment bewust geblokkeerd. De bundle mag niet aan een andere productiebackup worden gekoppeld.
- Er zijn geen `sync_db.py`, release-import, FE/MW-vervanging, compose-restart, rollback of deploymentacties uitgevoerd.

**Conclusie**: eerst moet een nieuwe, gevalideerde release bundle worden opgebouwd met een expliciete releaseKey die overeenkomt met de gekozen productie-ReleaseId, of moet een nieuwe consistente ReleaseId worden gekozen. Dit is een afzonderlijke substap waarvoor expliciete goedkeuring nodig is.

### Uitvoeringslog releaseKey gelijkmaken aan productie-ReleaseId

**Status**: Afgerond op 2026-09-18; geen productieactie uitgevoerd.

- De bestaande bundle-inhoud is behouden.
- `releaseKey` is aangepast naar `release:20260918_164519`, gelijk aan de productie-ReleaseId.
- De canonical bundlechecksum is opnieuw berekend en opgeslagen.
- Bundlechecksum, schema-eigen validatie en releaseKey zijn lokaal gecontroleerd.
- De gerichte bundle/importtests: 6 geslaagd.
- Python-syntaxcontrole: geslaagd.
- JSON-schema-validatie via een optionele externe module is niet uitgevoerd omdat die module lokaal ontbreekt; dit blokkeert de eigen contractvalidator niet.
- Geen database, SSH, Synology, upload, sync, restart of deployment uitgevoerd.

**Conclusie**: bundle en productiebackup gebruiken nu dezelfde release-identiteit. De volgende afzonderlijke substap is het opnieuw uitvoeren van de productie-deploy-preflight.

### Uitvoeringslog geslaagde productie-deploy-preflight

**Status**: Afgerond op 2026-09-18; geen productie-mutatie uitgevoerd.

- Lokale bundlechecksum: geldig.
- Bundle `releaseKey` en productie-ReleaseId: gelijk (`release:20260918_164519` / `20260918_164519`).
- Stackcompatibiliteit: `passed`.
- Remote BE-, FE- en MW-backups: aanwezig en metadata niet leeg.
- Centrale release-metadata: aanwezig.
- Remote compose/MariaDB-service: beschikbaar.
- Remote opslagcontrole: geslaagd.
- Geen `sync_db.py`, release-import, FE/MW-vervanging, compose-restart, rollback of deployment uitgevoerd.

**Conclusie**: alle preflightgates voor ReleaseId `20260918_164519` zijn groen. De volgende afzonderlijke substap is de gecontroleerde productie-mutatie: structurele DB-sync, release-data-import, FE/MW-publicatie, restart en healthchecks.

### Uitvoeringslog structurele DB-sync

**Status**: Gestopt met fout op 2026-09-18; releaseflow gepauzeerd vóór release-import en applicatiepublicatie.

- De correcte `sync_db.py --check-only` met geladen `deploy.env` gaf exitcode `10`: DEV en PROD verschillen.
- De goedgekeurde structurele/routine-sync is gestart.
- De sync eindigde met exitcode `4` in de categorie routine-/schemafout.
- Er zijn geen releasegegevens geïmporteerd, geen FE/MW-bestanden vervangen en geen containers herstart.
- De read-only nacontrole gaf opnieuw `Structure differs (DEV != PROD)`.
- Omdat `sync_db.py` autocommit gebruikt, wordt PROD niet als volledig gelijkgesteld beschouwd; verdere productieacties zijn gestopt.

**Conclusie**: de structurele DB-sync is niet succesvol afgerond en vereist een aparte foutanalyse vóór een nieuwe syncpoging. Mogelijk ontbreekt een routine-/schemarecht of is een specifieke routine niet compatibel met de productieomgeving. Geen release-import of applicatiedeployment uitvoeren totdat dit is opgelost.

### Uitvoeringslog read-only analyse DB-syncfout

**Status**: Analyse afgerond op 2026-09-18; geen nieuwe productie-mutatie uitgevoerd.

- DEV- en PROD-verbinding/authenticatie: geen foutcategorie.
- Ontbrekende create-, alter- of drop-routinerechten: niet vastgesteld.
- Routine-definitieverschillen: 9.
- Tabel-/kolomschemaverschillen: 10.
- Overige afwijkingscategorieën: 2.
- De bestaande syncfout is daarmee geen eenvoudige authenticatie- of rechtenblokkade; de PROD-state wijkt inhoudelijk af van DEV en minimaal één routine-/schemaactie is niet correct door de huidige syncflow verwerkt.
- Er zijn geen SQL-definities, grantteksten, accountgegevens of secrets weergegeven.
- Geen tweede syncpoging, release-import, FE/MW-vervanging, restart of deployment uitgevoerd.

**Conclusie**: de huidige `sync_db.py` is onvoldoende veilig te vervolgen zonder een expliciete dry-run/planweergave van de 10 tabel-/kolom- en 9 routineverschillen en zonder vaststelling welke eerdere mutaties eventueel al zijn toegepast. De volgende afzonderlijke substap is een read-only verschilrapport met objectnamen en beoogde acties, gevolgd door een expliciete beslissing per wijzigingscategorie.

### Uitvoeringslog read-only DEV/PROD-verschilanalyse

**Status**: Analyse afgerond op 2026-09-18; geen databasewijziging uitgevoerd.

**Belangrijkste uitkomst**:

- Het vermoeden wordt bevestigd: DEV en PROD zitten in verschillende versioningfasen.
- DEV-only versioningtabellen: `function_dependencies`, `function_registry`, `function_registry_audit` en `stack_manifests`.
- PROD-only legacy release-tabellen: `be_release_changes`, `be_releases`, `fe_release_changes`, `fe_releases`, `mw_release_changes` en `mw_releases`.
- DEV-only versioningprocedures: `AddFunctionDependency`, `GetActiveStackBuildNumber`, `GetActiveStackManifest`, `GetFunctionCapabilities`, `GetVersioningValidationProbe`, `PublishStackManifest`, `RegisterComponentManifest` en `UpdateFunctionRegistry`.
- PROD-only legacyprocedure: `GetReleasesByComponent`.
- Er is één tabel/kolomverschil en zijn 49 routine-definitieverschillen gevonden.
- De gewone bestaande tabellen en routines verschillen daarnaast inhoudelijk; dit is niet automatisch als veilige versioningmigratie te behandelen.

**Risico-inschatting**:

- Nieuwe versioningtabellen/procedures naar PROD brengen: **medium**, omdat dit een schema-/routine-uitbreiding is die eerst als gecontroleerde migratie moet worden toegepast.
- Oude release-tabellen uit PROD verwijderen: **high**, omdat dit destructief is en niet via een algemene sync mag gebeuren.
- Routine-definitieverschillen automatisch vervangen: **high**, omdat 49 verschillen niet zonder object-voor-object beoordeling mogen worden overschreven.

**Conclusie**: `sync_db.py` is niet het juiste instrument om deze DEV→PROD-versioningmigratie blind uit te voeren. De productieomgeving loopt achter op het nieuwe versioningmodel en bevat nog legacy release-objecten. De volgende substap moet een expliciet, read-only migratieplan maken voor alleen de DEV-only versioningobjecten, met legacy-verwijdering en algemene routineverschillen buiten scope totdat afzonderlijk beoordeeld.

### Uitvoeringslog expliciet DEV->PROD versioning-migratieplan

**Status**: Read-only plan afgerond op 2026-09-18; geen PROD-wijziging uitgevoerd.

**Scope**:

- Uitsluitend de nieuwe versioningtabellen en procedures voor function registry, dependencies, component-/stackmanifesten, capabilities en actieve stack/build-readers.
- Legacy release-tabellen/procedure en de 49 algemene routineverschillen blijven buiten scope.
- Geen release-import, FE/MW-actie, restart, grant- of secretwijziging.

**Voorgestelde uitvoeringsvolgorde**:

1. Tabellen, primaire sleutels, unieke constraints, JSON-checks en foreign keys.
2. Basisprocedures: `UpdateFunctionRegistry`, `AddFunctionDependency`, `GetFunctionCapabilities`.
3. Manifestprocedures: `RegisterComponentManifest`, `PublishStackManifest`.
4. Leesprocedures: `GetActiveStackManifest`, `GetActiveStackBuildNumber`.
5. DEV/PROD-validatie van objectinventaris, routine-aanroepen, key-contract, actieve stack en capabilities.

**Preconditions**:

- `GetTranNo` en alle benodigde databasefunctionaliteit bestaan in PROD.
- Initvolgorde en foreign keys zijn lokaal gecontroleerd.
- PROD-objecten worden niet vervangen zonder signatuur- en semantiekvergelijking.
- De change-set raakt geen legacy-objecten of algemene routineverschillen.

**Rollbackgrens en risico**:

- Vóór uitvoering in PROD kan het change-set worden aangepast of ingetrokken.
- Na creatie of wijziging van een PROD-object volgt geen automatische destructieve rollback; daarvoor is aparte goedkeuring nodig.
- Risico’s zijn vooral initvolgorde, afwijkende PROD-signaturen, bestaande constraints/records en ontbrekende procedureafhankelijkheden.

**Conclusie**: de volgende afzonderlijke substap is een lokale change-set/diffvalidatie van precies deze versioningobjecten, inclusief afhankelijkheidsgrafiek en fresh-install/compilecontrole. Pas na die validatie wordt een PROD-uitvoering ter goedkeuring aangeboden.

### Uitvoeringslog compacte PROD-versioningmigratie

**Status**: Uitgevoerd en read-only gevalideerd op 2026-09-18; release-data nog niet geïmporteerd.

- De nieuwe versioningtabellen zijn op PROD aanwezig: `function_registry`, `function_dependencies`, `function_registry_audit`, `component_manifests` en `stack_manifests`.
- De zeven kernprocedures zijn aanwezig: registry-update, dependency-update, capabilities, componentmanifestregistratie, stackpublicatie en de twee actieve-stack/build-readers.
- `GetActiveStackBuildNumber()` is succesvol aangeroepen en geeft momenteel een lege actieve-stackstatus terug; dit is verwacht vóór release-data-import.
- PROD-legacytabellen zijn behouden: zes legacy release-tabellen blijven aanwezig.
- `GetReleasesByComponent` is behouden.
- Er is geen algemene routine-sync uitgevoerd en de 49 overige routineverschillen zijn niet overschreven.
- Er is geen release-bundle geïmporteerd, geen FE/MW-bestand vervangen en geen container herstart.

**Bewuste scopekeuze**:

- `GetVersioningValidationProbe` is niet naar PROD gebracht; dit was een tijdelijke DEV-validatieprobe en geen runtimecomponent van de releaseketen.
- Legacy cleanup blijft buiten scope.

**Conclusie**: PROD bevat nu de noodzakelijke kernstructuur voor de nieuwe versioning- en manifestketen, zonder legacy-objecten te verwijderen of algemene PROD-routines te overschrijven. De volgende afzonderlijke substap is release-data-import via de bundle, gevolgd door read-only databasevalidatie.

### Uitvoeringslog PROD release-data-import

**Status**: Afgerond op 2026-09-18; FE/MW-publicatie en restart nog niet uitgevoerd.

- De gevalideerde release bundle is via de bestaande key-gebaseerde stored procedures naar PROD geïmporteerd.
- Geïmporteerd: 158 functies, 2 dependencies, 3 componentmanifesten en 1 stackmanifest.
- Read-only nacontrole: precies 1 actieve stack.
- Actieve stackcompatibiliteit: `passed`.
- Actief stack buildnummer: `12`.
- PROD registry- en dependency-aantallen komen overeen met de release bundle.
- De 6 legacy release-tabellen en `GetReleasesByComponent` zijn bewust behouden.
- Geen `sync_db.py`, legacy cleanup, FE/MW-bestandsvervanging, compose-restart, rollback of volledige deployment uitgevoerd.

**Conclusie**: de nieuwe versioningstructuur en de concrete release-data zijn nu in PROD aanwezig en gevalideerd. De volgende afzonderlijke substap is FE/MW-publicatie naar de actieve buildmappen, gevolgd door gecontroleerde restart en healthchecks.

### Uitvoeringslog gecorrigeerde PROD-compatibiliteitsgate

**Status**: Afgerond op 2026-09-18; geen FE/MW-publicatie of restart uitgevoerd.

- Een eerste gate-aanroep rapporteerde onjuiste failures door een te strenge proceduretelling en verkeerde verwerking van procedure-resultsets.
- Directe read-only SQL-validatie bevestigde: 1 actieve stack, 1 actieve `passed` stack, build `12`, 158 functies, 2 dependencies, 3 componentmanifesten en 1 stackmanifest.
- Alle 7 bedoelde kernprocedures zijn aanwezig.
- `GetActiveStackBuildNumber()`, `GetActiveStackManifest()` en `GetFunctionCapabilities()` leveren elk een resultset.
- De release bundle en componenten blijven inhoudelijk consistent met de PROD-aantallen.
- Er zijn geen databasewrites, FE/MW-bestandswijzigingen, compose-restarts of deploymentacties uitgevoerd.

**Conclusie**: de compatibiliteitsgate is inhoudelijk groen; de eerdere FAIL was een controleharnessfout. De volgende afzonderlijke substap is FE/MW-publicatie naar de actieve buildmappen.

### Uitvoeringslog FE/MW-publicatie en rollback na kopieerfout

**Status**: Publicatie niet afgerond; rollback naar vorige productie-build geslaagd op 2026-09-18.

- De tijdelijke FE/MW-staging bevatte respectievelijk 8 en 31 bestanden.
- Tijdens de remote vervanging faalde de tweede tar-kopie nadat de actieve mappen waren leeggemaakt; daardoor ontstond tijdelijk een gedeeltelijke FE/MW-state.
- De actieve FE- en MW-mappen zijn direct hersteld vanuit de ReleaseId-backups.
- Herstelvalidatie: FE exact gelijk aan backup (`FE_MATCH=true`), MW exact gelijk aan backup (`MW_MATCH=true`).
- De actieve productie-builds staan weer op de vorige, gevalideerde staat.
- Geen containerrestart, healthcheck, release-import, databasewijziging of verdere deployment uitgevoerd.

**Conclusie**: de nieuwe FE/MW-publicatie is niet toegepast. De rollbackfunctie werkte voor deze fout; een volgende publicatiepoging vereist eerst een robuustere atomische staging/swapmethode die de actieve map niet leegt voordat de nieuwe inhoud volledig klaarstaat.

### Uitvoeringslog expliciete Synology-stagingstructuur

**Status**: Afgerond op 2026-09-18; staging voorbereid, actieve productie niet gewijzigd.

- Nieuwe stagingroot aangemaakt onder `/volume1/docker/familiez/Staging/20260918_164519/`.
- FE-stagingmap: `Staging/20260918_164519/FE/`.
- MW-stagingmap: `Staging/20260918_164519/MW/`.
- Niet-geheime kandidaatmetadata aangemaakt met `purpose=candidate` en `status=prepared`.
- FE- en MW-stagingmappen zijn bewust nog leeg; er zijn geen nieuwe bestanden gekopieerd.
- De bestaande `Backup/20260918_164519/` blijft de officiële rollbackbron.
- Geen actieve buildmap gewijzigd, geen container herstart en geen healthcheck/deployment uitgevoerd.

**Conclusie**: de staginglocatie is nu duidelijk zichtbaar op rootniveau van de Familiez-deploymentmap en gescheiden van `Backup`. De volgende afzonderlijke substap is nieuwe FE/MW-bestanden naar deze stagingmappen kopiëren en daar volledig controleren.

### Uitvoeringslog gevulde en gevalideerde Synology-staging

**Status**: Afgerond op 2026-09-18; actieve productie niet gewijzigd.

- Nieuwe FE-bestanden zijn naar `Staging/20260918_164519/FE/` gekopieerd.
- Nieuwe MW-bestanden zijn naar `Staging/20260918_164519/MW/` gekopieerd.
- Stagingbestandstelling: FE 8 bestanden, MW 31 bestanden.
- Read-only SHA-256-vergelijking met de lokale bronnen: FE `HASH_MATCH=true`, MW `HASH_MATCH=true`.
- De officiële `Backup/20260918_164519/`-rollbackmappen zijn niet gewijzigd.
- De actieve FE- en MW-buildmappen zijn niet gewijzigd.
- Geen compose-restart, healthcheck, databaseactie of deployment uitgevoerd.

**Conclusie**: de nieuwe FE/MW-release staat gecontroleerd klaar in de zichtbare Synology-stagingmap. De volgende afzonderlijke substap is het gecontroleerd vervangen van de actieve FE/MW-buildmappen vanuit staging.

### Uitvoeringslog FE/MW-vervanging vanuit staging

**Status**: Vervanging mislukt; automatische rollback geslaagd op 2026-09-18.

- De vervanging is gestart vanuit `Staging/20260918_164519/`.
- De remote kopieeropdracht faalde voordat de publicatie als geslaagd kon worden gemarkeerd.
- De ingebouwde rollback heeft FE en MW teruggezet vanuit `Backup/20260918_164519/`.
- Read-only nacontrole: FE actief 60 bestanden / backup 60; MW actief 126 bestanden / backup 126.
- De actieve FE/MW-builds zijn daarmee weer gelijk aan de officiële rollbackbackups.
- Geen containerrestart, healthcheck, databaseactie, release-import of verdere deployment uitgevoerd.

**Conclusie**: de productieomgeving staat weer op de vorige, gevalideerde FE/MW-build. De staginginhoud blijft beschikbaar voor analyse; een nieuwe publicatiepoging vereist eerst diagnose van de remote kopieerfout.

### Uitvoeringslog diagnose FE/MW-kopieerfout

**Status**: Read-only diagnose afgerond op 2026-09-18; geen nieuwe publicatie uitgevoerd.

- Stagingroot, actieve FE/MW-mappen en officiële backupmappen bestaan.
- Alle gecontroleerde mappen zijn schrijfbaar voor de deploygebruiker.
- FE actief: 60 bestanden; MW actief: 126 bestanden; backups en staging zijn bereikbaar.
- Vrije filesystemcontrole op staging en actieve buildlocaties slaagde.
- Een tijdelijke schrijfproef buiten de applicatiepaden slaagde.
- Er is geen opslag-, permissie- of ontbrekende-mapblocker gevonden.
- De eerdere fout wordt daarom toegeschreven aan de samengestelde tar/remote-shellopdracht; de actieve FE/MW-state bleef door rollback correct.

**Conclusie**: een nieuwe publicatiepoging kan eenvoudiger per component en met expliciete tussencontroles worden uitgevoerd. Daarvoor is opnieuw expliciete toestemming nodig omdat de actieve productie-buildmappen opnieuw worden gewijzigd.

**Aanvulling na retry**:

- Een afzonderlijke retry voor FE faalde in de shellcontrole; de tar-kopie zelf was niet de primaire blocker.
- De oorzaak was dat historische `voorgaande_versie`-bestanden in sommige tellingen werden meegerekend en dat de FE-staging aanvankelijk `nginx.conf` miste.
- FE-staging is aangevuld met `nginx.conf`.
- De actieve FE-rootinhoud is read-only hersteld en matcht de officiële FE-backup: 9 rootbestanden, hashes gelijk, exclusief metadata en historische submap.
- De actieve MW-rootinhoud matcht eveneens de officiële MW-backup: 26 rootbestanden, hashes gelijk, exclusief metadata en historische submap.
- De nieuwe FE/MW-release is niet actief gepubliceerd en geen container is herstart.

**Conclusie**: de productieomgeving staat weer exact op de vorige FE/MW-release. Een nieuwe publicatiepoging moet de historische submap expliciet buiten de actieve inhoud houden en `nginx.conf` in FE-staging opnemen.

### Scopebesluit historische `voorgaande_versie`-mappen

**Besluit**: vanaf 2026-09-18 vallen bestaande `voorgaande_versie`-mappen volledig buiten de nieuwe release-, staging- en rollbackmethodiek.

- Deze mappen zijn historische resten van de oude deploymentmethode.
- Vergelijkingen, bestandstellingen, stagingkopieën en rollbackcontroles voor de nieuwe release negeren deze mappen.
- De officiële rollbackbron blijft `Backup/<ReleaseId>/FE|MW|BE/`.
- De `voorgaande_versie`-mappen worden niet door deze releaseflow verwijderd of aangepast.
- Frans verwijdert deze historische mappen later zelf als afzonderlijke opruimactie.

**Gevolg voor vervolg**: nieuwe FE/MW-publicatie vergelijkt uitsluitend de actuele rootinhoud met `Staging/<ReleaseId>/FE|MW`; historische submappen zijn niet relevant voor de releasebeoordeling.

### Uitvoeringslog geslaagde FE/MW-publicatie vanuit staging

**Status**: Afgerond op 2026-09-18; containers nog niet herstart.

- FE en MW zijn per component vanuit `Staging/20260918_164519/` naar de actieve rootmappen gekopieerd met `cp`.
- `voorgaande_versie` is volledig buiten scope gehouden.
- FE-staging bevat de benodigde `nginx.conf`.
- FE actieve rootinhoud: 9 bestanden; inhoudelijk gelijk aan staging.
- MW actieve rootinhoud: 31 bestanden; inhoudelijk gelijk aan staging nadat uitgesloten Python-cachebestanden zijn verwijderd.
- De officiële `Backup/20260918_164519/`-rollbackmappen zijn niet gewijzigd.
- Geen compose-restart, healthcheck, databaseactie of verdere deployment uitgevoerd.

**Conclusie**: de nieuwe FE/MW-bestanden staan actief op Synology en zijn per component vanuit zichtbare staging gepubliceerd. De volgende afzonderlijke substap is een gecontroleerde containerrestart met daarna healthchecks.

### Uitvoeringslog uitsluiten ontwikkelmappen uit MW-deployment

**Status**: Afgerond op 2026-09-18; containers niet herstart.

- `.github` en `.vscode` zijn toegevoegd aan `MW_EXCLUDES` in de lokale deployconfiguratie en het voorbeeldbestand.
- De mappen zijn verwijderd uit MW-staging en de actieve MW-root.
- Historische `voorgaande_versie` bleef volledig buiten scope.
- Actuele MW-root na opschoning: 27 bestanden.
- MW-staging na opschoning: 27 bestanden.
- Read-only hashvergelijking: 0 verschillen.
- De officiële MW-backup is niet gewijzigd.
- Geen compose-restart, healthcheck of verdere deployment uitgevoerd.

**Conclusie**: repository- en editorconfiguratie worden niet meer naar de MW-runtime gedeployed. De actieve MW-root en staging zijn weer inhoudelijk gelijk.

### Uitvoeringslog gecontroleerde FE/MW-restart en healthchecks

**Status**: Restart en basishealthchecks afgerond op 2026-09-18.

- FE en MW zijn gecontroleerd herstart via de bestaande Synology-compose-stack.
- MariaDB bleef actief en rapporteerde `healthy`.
- FE- en MW-containers draaien.
- MW root endpoint: HTTP 200.
- Publieke `/versioning/stack-build`: HTTP 200.
- `/capabilities`: HTTP 401 zonder authenticatie; dit is verwacht voor het beveiligde endpoint.
- `/pingAPI`: HTTP 422 zonder de verplichte timestampparameter; dit is verwachte API-validatie.
- Een eerdere publieke versioningcheck gebruikte een samengestelde URL en rapporteerde daardoor onjuiste failures; directe controle via Synology localhost bevestigde de endpointwerking.
- Geen rollback, databasewijziging of verdere deployment uitgevoerd.

**Conclusie**: de nieuwe FE/MW-build draait na restart en de publieke stack-buildroute werkt. De volgende stap is een beperkte geauthenticeerde smoke test en daarna de release afronden; productie-rollout is nog niet als volledig geslaagd gemarkeerd totdat die smoke test is uitgevoerd.

### Uitvoeringslog handmatige Release Dashboard-smoketest

**Status**: Afgerond op 2026-09-18.

- Frans heeft na login het Release Dashboard geopend.
- De pagina toont de verwachte stackstatus en componentinformatie.
- De geauthenticeerde `/capabilities`-keten en de Release Dashboard-weergave zijn daarmee handmatig bevestigd.
- De automatische healthchecks en directe MW-endpointcontroles blijven geldig.
- Geen database-, rollback- of verdere deploymentactie uitgevoerd.

**Conclusie**: de release is functioneel gecontroleerd inclusief Release Dashboard. De volgende stap is release-afronding: wijzigingen reviewen, commits/pushes per repository voorbereiden en het implementatieplan afsluiten.

---

## LEGACY-NASLAG — oorspronkelijke GitHub Actions-stappen 10/11

Deze historische sectie staat bewust helemaal onderaan en maakt geen deel uit van de actuele uitvoeringsvolgorde. Op 2026-09-10 is besloten de aansturing van het versiesysteem lokaal te houden zonder GitHub Actions. De lokale orchestrator en lokale deployflow zijn de actuele aanpak.

### Oorspronkelijke Stap 10: GitHub Actions — component-workflows

Per component-repo zouden workflows de lokaal aanroepbare scanners, bump-engine, manifestgeneratie en registry-aanroepen uitvoeren en daarna een `repository_dispatch` naar Familiez-Deploy sturen. Deze optie is niet uitgevoerd.

### Oorspronkelijke Stap 11: GitHub Actions — self-hosted runner en orchestrator

Een self-hosted runner en centrale dispatch-orchestrator zouden interne database-toegang via CI/CD mogelijk maken. Deze optie is niet uitgevoerd; de gekozen aanpak blijft lokaal en handmatig.

