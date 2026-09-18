# Implementatie van het nieuwe greenfield versie- en release-systeem voor Familiez

## Samenvatting

We gaan een volledig nieuw, greenfield versie- en release-systeem implementeren voor de Familiez-stack (FE, MW, DB).

Het nieuwe systeem draait volledig extern (CI/CD, manifests, Function Registry, capabilities endpoint) en wijzigt de bestaande code niet, behalve het verwijderen van oude versie-logica in de allerlaatste stap.

Het oude versie-/release-systeem is verouderd, inconsistent, incompleet en heeft geen waarde.
Het wordt niet gemigreerd, niet gebruikt, niet vergeleken, en pas als laatste verwijderd.

Alle nieuwe versies starten op:
- FE/MW/DB: 1.0.0
- Functies: v1

De implementatie gebeurt in logische stappen, waarbij Copilot:
- elke stap beschrijft
- toestemming vraagt
- uitvoert
- terugkoppeling geeft
- alles logt in dit Markdown-bestand
- pas daarna de volgende stap aanbiedt

Dit bestand dient als voortgangslogboek, zodat de implementatie over meerdere dagen kan worden uitgevoerd.

## Uitgangspunten

- Greenfield versie-systeem
- Geen migratie van oude versies
- Geen gebruik van oude release-logica
- Oude versie-logica verwijderen als laatste stap
- Bestaande FE/MW/DB code blijft onaangetast
- Nieuwe versie-architectuur draait extern
- CI/CD voert alle bumping en validatie uit
- AI bepaalt bump-types
- Manifests worden automatisch gegenereerd
- Stack manifest wordt automatisch opgebouwd
- Function Registry wordt centrale bron van waarheid
- Compatibiliteit checks worden automatisch uitgevoerd
- Rollback-veiligheid wordt ingebouwd

## Beslissingenlog (uitwerking tijdens dialoog)

### 1. Bepaling bump-type (patch/minor/major)

Besloten: geen live AI-call als primaire beslisser. In plaats daarvan een deterministische, reproduceerbare heuristiek, met AI alleen als tie-breaker bij ambiguïteit.

Volgorde van bronnen:
1. **Hash-vergelijking (structureel, primaire bron)** — hash van de publieke interface (functiehandtekening/parameters/return-type/route-signature) per functie/procedure/component.
   - Signature gewijzigd (parameter toegevoegd/verwijderd/type gewijzigd) → **major**-kandidaat
   - Enkel implementatie/body gewijzigd, signature gelijk → **patch**-kandidaat
2. **Commit-tag-analyse (expliciete intentie, primaire bron)** — conventional-commit-achtige prefixes (`feat:`, `fix:`, `BREAKING CHANGE:`, `chore:`) geven de expliciete intentie van de developer; deterministisch en reproduceerbaar.
3. **Diff-analyse (ondersteunend)** — extra signaal om bijv. comment/logging-only wijzigingen te onderscheiden van echte logicawijzigingen; verfijning, geen primaire bron.
4. **AI-analyse (tie-breaker, niet-permanent)** — alleen ingezet wanneer hash-classificatie en commit-tag-classificatie **tegenstrijdig of ontbrekend** zijn. AI-voorstel wordt gelogd in dit Markdown-bestand en een mens bevestigt (conform het "toestemming vragen"-principe).

Bump-regel: `max(hash-classificatie, commit-tag-classificatie)`, met diff-analyse als verfijning bij twijfel en AI-analyse alleen als expliciete, gelogde tie-breaker bij conflict.

Motivatie: reproduceerbaarheid (zelfde wijziging → zelfde bump-beslissing), auditeerbaarheid (elke beslissing herleidbaar naar een concrete regel), lagere kosten/snelheid (geen onnodige AI-calls in de pipeline), en consistentie met het greenfield-principe (duidelijke regels, AI als tie-breaker in plaats van hoofdbeslisser).

### 2. Locatie Function Registry

Besloten: de Function Registry draait als onderdeel van de bestaande `humans`-database (geen aparte database).

FE en MW moeten worden aangepast om de registry te kunnen uitvragen en tonen:
- MW krijgt een nieuw, geïsoleerd capabilities-endpoint dat de registry uitleest.
- FE krijgt een nieuw, geïsoleerd Release Dashboard-onderdeel dat dit endpoint aanroept.

Deze toevoegingen zijn nieuwe, geïsoleerde code — geen wijziging van bestaande FE/MW-functionaliteit. De regel "bestaande code blijft onaangetast" geldt voor bestaande functionaliteit en wordt niet geschonden door het toevoegen van deze nieuwe, afgebakende onderdelen.

### 3. Definitie van "functie" per laag + aanroepketen

Per laag betekent "functie" iets anders, en de Function Registry legt ook de onderlinge aanroepketen vast:
- **BE**: een stored procedure, met haar IN/OUT-parameters als signature.
- **MW**: een Python-functie/route-handler (endpoint), die één of meer BE-sprocs aanroept.
- **FE**: een React-functie/component/hook, die één of meer MW-endpoints aanroept.

De registry houdt per laag een versie bij, én de aanroepketen (FE-functie → MW-functie(s) → BE-sproc(s)), zodat end-to-end compatibiliteit gecontroleerd kan worden: kan FE-functie X (versie n) nog MW-functie Y (versie m) aanspreken, en kan die nog BE-sproc Z (versie p) aanspreken?

### 4. Procesregel: geen codewijzigingen tijdens de ontwerpdialoog

Verduidelijking van "bestaande code blijft onaangetast": dit is zowel een architectuurregel (zie punt 2) als een procesregel. Zolang Frans en Copilot nog niet volledig akkoord zijn over de volledige opzet en aanpak, worden er **geen enkele wijzigingen** aan de code doorgevoerd — ook geen kleine of voorbereidende wijzigingen. Pas na volledige overeenstemming over het plan start de uitvoeringsfase, stap voor stap, met expliciete toestemming per stap.

### 5. Locatie CI/CD-pipeline

Besloten (voorlopig): de CI/CD-pipeline draait op **GitHub Actions**, niet op de Synology-server. Synology blijft uitsluitend het productie-runtime-doel (FE/MW/DB-containers).

Voorgestelde taakverdeling:
- **GitHub Actions**: functie-scanners, hash-vergelijking, commit-tag-analyse, bump-engine, manifest-generatie (FE/MW/DB/stack), manifestvalidatie, wegschrijven naar de Function Registry (in `humans`-db op Synology, via beveiligde verbinding of via de bestaande deploy-stap), initiëren van rollback.
- **Synology**: uitsluitend runtime — het draaien van FE/MW/DB inclusief het nieuwe capabilities-endpoint (MW) en Release Dashboard (FE), en het uitvoeren van rollback via het bestaande deploy-mechanisme.

Status: Frans wil eerst meer kennis opdoen over GitHub Actions voordat dit daadwerkelijk wordt ingericht. Deze stap wordt dus pas na een leerfase concreet uitgevoerd.

**Connectivity naar de database (aanvulling)**: Frans wil niet dat de database rechtstreeks vanaf het internet bereikbaar is. Besloten (voorlopig, kan nog wijzigen naarmate meer kennis over GitHub Actions is opgedaan): een **self-hosted GitHub Actions runner**, geïnstalleerd op een machine binnen het interne netwerk (waar ook de Synology-database staat). Deze runner haalt taken op bij GitHub via een uitgaande verbinding (initiatief ligt bij het interne netwerk) en voert de registry-schrijfstap lokaal uit, met rechtstreekse toegang tot de database — zonder dat de database ooit vanaf het internet bereikbaar hoeft te zijn. Open aandachtspunt: welke machine dit wordt, en dat deze aan/online moet zijn wanneer de pipeline draait.

### 6. Scope: MOB buiten beschouwing

Besloten: de mobiele app (MOB) valt vooralsnog buiten scope van dit versie-systeem. Wordt later (mogelijk) alsnog toegevoegd.

### 7. Function Registry-schema

Voorlopig schema (kan later nog verfijnd worden tijdens implementatie):

**Tabel `function_registry`** — één rij per functie/procedure/component, per laag:
- `FunctionId` (PK)
- `Layer` — enum: `FE` / `MW` / `BE`
- `FunctionName` — React-componentnaam, Python-functienaam, of sproc-naam
- `Version` — versie van de functie (zie versienummering hieronder)
- `SignatureHash` — hash van de publieke interface
- `LastChangedCommit` — commit-hash die tot de laatste versiewijziging leidde
- `LastChangedAt` — timestamp
- `Status` — actief/deprecated/removed

**Tabel `function_dependencies`** — legt de aanroepketen vast:
- `DependencyId` (PK)
- `CallerFunctionId` (FK → `function_registry`)
- `CalleeFunctionId` (FK → `function_registry`)
- `RequiredMinVersion` — minimale versie van de callee die de caller nodig heeft

**Tabel `function_registry_audit`** — structurele, bevraagbare audit-trail (aanvullend op, niet ter vervanging van, de bestaande `testlog`-conventie voor procedurele diagnostiek):
- `AuditId` (PK)
- `FunctionId` (FK)
- `OldVersion`, `NewVersion`
- `BumpReason` — welke bron gaf de doorslag (hash/commit-tag/AI-tie-breaker)
- `ChangedBy` — pipeline-run-id / commit-auteur
- `ChangedAt`

**Versienummering per functie**: eenvoudige oplopende integer (`v1`, `v2`, `v3`, …), niet semver. Ophogen gebeurt alleen wanneer de `SignatureHash` wijzigt (dus bij een minor- of major-bump volgens de bump-engine); een pure patch (alleen implementatie/body gewijzigd, signature gelijk) verhoogt de functieversie niet. Componentniveau (FE/MW/DB) blijft wél volledig semver (`1.0.0`), afgeleid van de zwaarste onderliggende functie-bump. Dit houdt de vergelijking in `RequiredMinVersion` een eenvoudige integer-vergelijking (`>=`).

**Audit-aanpak**: aparte, structurele `function_registry_audit`-tabel (bevraagbaar voor Release Dashboard en compatibiliteitschecks), naast de bestaande `testlog`-conventie voor operationele diagnose bij sproc-executie.

Besloten: `function_dependencies` legt alleen **directe** aanroeprelaties vast (FE→MW, MW→BE). Geen aparte FE→BE-rij. Motivatie: MW zit architectonisch altijd tussen FE en BE (FE roept nooit rechtstreeks een sproc aan), dus een directe FE→BE-relatie zou dubbele, foutgevoelige boekhouding zijn. End-to-end compatibiliteit wordt afgeleid door de keten te wandelen: FE-functie → (via `function_dependencies`) MW-functie → (via `function_dependencies`) BE-sproc, via een eenvoudige 2-staps join-query.

### 8. Manifest-inhoud

**FE/MW/DB-manifest** (per component, gegenereerd bij elke release, opgeslagen in de eigen repo):
```json
{
  "component": "MW",
  "version": "1.2.0",
  "dockerImageTag": "familiez-mw:1.2.0",
  "generatedAt": "2026-09-07T12:00:00Z",
  "sourceCommit": "abc1234",
  "functions": [
    { "name": "get_person", "version": "v3", "signatureHash": "sha256:...", "status": "active" }
  ]
}
```
Besloten: wel Docker image-tag (nodig om de omgeving reproduceerbaar te kunnen opbouwen); geen testresultaten (als tests falen, wordt er sowieso niet naar productie gepromoot, dus vastleggen heeft geen waarde). Optioneel: een verwijzing naar de GitHub Actions run-URL i.p.v. de testresultaten zelf, voor traceerbaarheid.

**Stack-manifest** (aggregatie van FE/MW/DB, aparte plek nodig omdat het niet bij één component hoort):
```json
{
  "stackBuildNumber": 42,
  "generatedAt": "2026-09-07T12:00:00Z",
  "components": {
    "FE": { "version": "1.2.0", "manifestRef": "..." },
    "MW": { "version": "1.2.0", "manifestRef": "..." },
    "DB": { "version": "1.1.0", "manifestRef": "..." }
  },
  "compatibilityCheck": "passed"
}
```
Besloten: FE/MW/DB-manifests worden opgeslagen in de eigen repo (blijft dicht bij de bron). Het stack-manifest wordt opgeslagen in de **Familiez-Deploy-repo**, omdat het een aggregatie is die niet bij één specifiek component hoort.

Besloten: het stack-manifest krijgt een eigen, simpele identifier: een automatisch oplopend `StackBuildNumber` (integer, geen semver), gegenereerd bij elke succesvolle build waarin FE+MW+DB samen gevalideerd zijn. Geen semver, want het stack-manifest is geen artefact waar iets tegen compatibel hoeft te zijn (dat is al geregeld via de function-versies/dependencies) — het is een snapshot-referentie, vooral bedoeld voor rollback-doeleinden (terugrollen naar `StackBuildNumber` X).

Aandachtspunt (later concreet op te lossen bij CI/CD-inrichting): als de pipeline manifests terugschrijft (commit) naar de eigen repo, moet worden voorkomen dat die commit zelf weer een nieuwe pipeline-run triggert (bijv. via `[skip ci]` in de commit-message of een aparte branch/tag voor manifests).

### 9. Orkestratie over de repositories

Besloten model: **`repository_dispatch` vanuit component-repo's naar een centrale orkestrator in Familiez-Deploy**.

1. Elke component-repo (FE/MW/BE) heeft een eigen, onafhankelijke workflow die bij een push draait: functie-scanner → hash-vergelijking → commit-tag-analyse → bump-engine → eigen manifest bijwerken (in de eigen repo) → Function Registry bijwerken (via de self-hosted runner).
2. Na succesvolle afronding stuurt die workflow een `repository_dispatch`-event naar de Familiez-Deploy-repo, met daarin: welk component, welke nieuwe versie, en een verwijzing naar het eigen manifest/commit.
3. Familiez-Deploy heeft een orkestrerende workflow die op zo'n dispatch-event reageert: haalt de actuele Function Registry op (bevat al de dependency-graph), voert de end-to-end compatibiliteitscheck uit (FE→MW→BE-keten wandelen), genereert het stack-manifest met een nieuw `StackBuildNumber`, en beslist of dit richting deployment mag.

Motivatie:
- Losse, snelle feedback per component: een wijziging in bijv. BE hoeft niet te wachten op FE/MW om zijn eigen versie/manifest bij te werken.
- Native GitHub-mechanisme (`repository_dispatch`), geen eigen polling-mechanisme nodig.
- De Function Registry is de bron van waarheid voor de dependency-graph, niet de dispatch-payload zelf — consistent met het uitgangspunt "Function Registry wordt centrale bron van waarheid".
- Geen race-condition-risico: de Registry-write gebeurt in de componentworkflow vóór de dispatch, dus de orkestrator leest altijd actuele data.
- Sluit aan bij het besluit dat het stack-manifest in Familiez-Deploy hoort (punt 8) — dezelfde repo genereert het manifest én doet de orkestratie.

Aandachtspunt (later concreet op te lossen bij CI/CD-inrichting): als twee component-repo's kort na elkaar pushen, moet de orkestrator-workflow dit sequentieel verwerken (bijv. via GitHub Actions' `concurrency`-instelling), om te voorkomen dat parallelle runs elkaars registry-lezing overschrijven.

### 10. Rollback-veiligheid: scope en aanpak

Besloten scenario: rollback betekent "terug naar een eerdere, geregistreerde `StackBuildNumber`-combinatie" (bijv. na een mislukte productie-release), niet het corrigeren van een foutieve automatische bump (dat wordt afgedekt door de audit-trail, geen rollback-mechanisme nodig).

Besloten: FE/MW en BE hebben een fundamenteel verschillend rollback-risicoprofiel:
- **FE/MW** zijn stateless: rollback = de oude Docker image-tag (vastgelegd in het manifest) opnieuw draaien. Veilig en instant.
- **BE (DB)** is stateful: rollback van een sproc betekent het oude `CREATE PROCEDURE`-script opnieuw uitvoeren. Dit systeem versiebeheert alleen de sproc-signature, niet de onderliggende tabelstructuur.

Besloten: **schema-rollback (tabelstructuur) valt buiten scope** van dit versie-systeem. Motivatie: het zou een aparte migratielaag vereisen (up/down-scripts, eigen schema-versieregistry) met een wezenlijk risicoprofiel (dataverlies bij "down"-migraties) en zou de scope en doorlooptijd van dit project sterk vergroten.

Besloten: in plaats daarvan geldt de conventie dat **schemawijzigingen in BE altijd backward-compatible/additief zijn** (nieuwe kolommen nullable/met default, geen hernoemen of verwijderen van bestaande kolommen in dezelfde release). Hierdoor blijven oudere sproc-versies gewoon werken op een uitgebreid schema, en is schema-rollback niet nodig — je gaat alleen vooruit met compatibele toevoegingen. Definitieve opschoning van verouderde kolommen gebeurt pas als losstaande, bewuste actie na meerdere releases, niet als onderdeel van een rollback.

Samenvatting rollback-garantie: dit systeem garandeert rollback op **code-niveau** (FE/MW-images + BE-sproc-scripts + Function Registry-status), niet op **data/schema-niveau**.

### 11. Trigger-moment compatibiliteitschecks

Besloten: compatibiliteitschecks draaien op twee momenten, met een verschillende functie:

1. **Continu, bij elke push (informatief)**: bij elke `repository_dispatch` (zie punt 9) draait de compatibiliteitscheck en wordt het stack-manifest bijgewerkt. Dit blokkeert niets, maar houdt Registry en dashboard actueel en geeft snelle feedback.
2. **Vlak vóór deployment (verplichte gate)**: de deploy-workflow controleert opnieuw, op het moment van daadwerkelijk deployen, of de te deployen `StackBuildNumber` nog steeds `compatibilityCheck: passed` heeft volgens de laatste registry-status. Zo niet: deployment wordt geweigerd. Dit voorkomt dat een verouderd of inmiddels-ongeldig "passed"-resultaat alsnog naar productie gaat.

### 12. Inventarisatie "oude versie-logica" (te verwijderen in de allerlaatste stap)

Op basis van een read-only inventarisatie van de bestaande code is dit de oude versie-/release-logica:

**BE (database)**:
- Tabellen: `fe_releases`, `fe_release_changes`, `mw_releases`, `mw_release_changes`, `be_releases`, `be_release_changes` (zie `humans_releases.sql`)
- Sproc `GetReleasesByComponent`
- De reeks `UpdateVersion_*.sql`-scripts die deze tabellen vullen bij elke release

**MW (middleware)**:
- Endpoint `GET /GetReleases` en helper `fetch_releases()` in `main.py`
- Bijbehorende tests `TestFetchReleases` in `test_main.py`

**FE (frontend)**:
- Service-functie `getReleases()` in `services/familyDataService.js`
- Pagina `FamiliezInfo.jsx` (releases per component + `versionLabel`/`latestFeRelease`)

Dit wordt pas verwijderd in de allerlaatste implementatiestap, nadat het nieuwe systeem volledig operationeel is (conform het uitgangspunt "oude versie-logica verwijderen als laatste stap").

### 13. Aanvullende besluiten uit de tweede integrale review

**A. FE-scanner scope + TypeScript**: FE is plain JavaScript/JSX (geen TypeScript), waardoor een betrouwbare signature-hash voor willekeurige React-componenten niet goed haalbaar is. Besloten: de FE-functiescanner richt zich vooralsnog alleen op de functies in `src/services/` (die de MW-endpoints aanroepen, en die zijn de enige laag die telt in de aanroepketen FE→MW, zie punt 3), met hun expliciete argumenten als quasi-signature. Een eventuele latere migratie naar TypeScript (los project, buiten scope van dit versie-systeem; geschatte impact op de huidige FE-codebase van ~32 bestanden/~10.657 regels: enkele dagen tot ~2 weken, incrementeel uit te voeren dankzij `allowJs`) zou de hash-betrouwbaarheid verder verbeteren, maar is geen blokkade om nu te starten.

**B. Registry-writes via sproc, conform BE-conventies**: besloten dat de Function Registry nooit rechtstreeks met losse SQL-statements vanuit de pipeline wordt bijgewerkt. In plaats daarvan komt er een dedicated sproc (bijv. `UpdateFunctionRegistry`) die het standaard BE-patroon volgt (`SQL SECURITY INVOKER`, geen `DEFINER`, `testlog`-logging, exit-handler, één `SELECT` als resultaat). De self-hosted runner roept alleen deze sproc aan.

**C. Conventional-commit-conventie als AI-regel**: omdat commits/pushes namens Frans door AI worden uitgevoerd, wordt vastgelegd dat elke AI-sessie die commit/push doet het conventional-commit-patroon (`feat:`, `fix:`, `chore:`, `BREAKING CHANGE:`, etc.) consequent toepast. Dit maakt punt 1 (commit-tag-analyse) betrouwbaar zonder dat dit een handmatige gedragsverandering voor Frans vereist.

### 14. Kernlogica als lokaal aanroepbare scripts, los van GitHub Actions

Vraag: kan een lokaal mechanisme (bijv. npm-scripts/Python-CLI) GitHub Actions vervangen, gezien Frans vooralsnog de enige developer is?

Besloten: de kernlogica (functie-scanners, bump-engine, manifest-generatie, registry-writes — stappen 2 t/m 7 van het implementatieplan) wordt gebouwd als **losstaande, lokaal aanroepbare scripts** (npm-scripts voor FE, Python-CLI voor MW/BE/Familiez-Deploy), onafhankelijk van GitHub Actions. Een eventuele GitHub Actions-workflow zou later niets anders doen dan diezelfde scripts aanroepen — er hoeft dus niets dubbel gebouwd te worden.

Dit ontkoppelt bewust "wat het systeem doet" (de scripts) van "wanneer/hoe het wordt aangeroepen" (handmatig, via git-hooks, of via GitHub Actions). Voordelen: geen wachten op GitHub Actions-kennis om te kunnen starten, volledige controle, geen self-hosted-runner-vraagstuk nodig zolang lokaal gedraaid wordt.

Afwegingen, bewust geaccepteerd voor de huidige situatie (solo-developer):
- **Geen afdwingbaarheid**: een lokaal script kan vergeten of bewust overgeslagen worden (in tegenstelling tot een verplichte GitHub Actions-check met branch-protection). Voor een solo-developer is dit een kwestie van zelfdiscipline, geen technisch risico.
- **Geen automatische, centrale run-historie**: dit gemis wordt grotendeels ondervangen doordat de `function_registry_audit`-tabel (besluit 7) toch al een eigen, structurele audit-trail bijhoudt.
- **Cross-repo triggering (besluit 9, `repository_dispatch`) wordt handmatig**: na een wijziging in bijv. BE moet het orkestratiescript in Familiez-Deploy dan zelf worden aangeroepen, in plaats van automatisch te triggeren.

Overdraagbaarheid naar toekomstige developers: het lokale mechanisme is overdraagbaar zolang toekomstige developers dezelfde tooling (Node/Python) en — vanwege de connectivity-keuze in besluit 5 — toegang tot hetzelfde interne netwerk/de database hebben. Dit is een gevolg van de eerder gemaakte connectivity-keuze, niet van de keuze lokaal vs. GitHub Actions.

Status: GitHub Actions blijft het voorlopige einddoel voor automatisering (besluit 5), maar de kernlogica wordt zo gebouwd dat lokaal, handmatig gebruik vanaf het begin mogelijk is, en automatisering via GitHub Actions een latere, niet-blokkerende toevoeging is.

## Checklist (Copilot moet alles afvinken)

### Architectuur
- [ ] Greenfield versie-systeem
- [ ] Geen migratie van oude versies
- [ ] Geen gebruik van oude release-logica
- [ ] Oude versie-logica verwijderen als laatste stap

### Versiebeheer
- [ ] Functie-scanners FE/MW/DB
- [ ] Hash-vergelijking
- [ ] Commit-tag-analyse
- [ ] AI-analyse
- [ ] Bump-engine (patch/minor/major)
- [ ] Automatische functie-versie-verhoging
- [ ] Automatische FE/MW/DB versie-verhoging

### Manifests
- [ ] FE manifest
- [ ] MW manifest
- [ ] DB manifest
- [ ] Stack manifest
- [ ] Manifestvalidatie

### Registry
- [ ] MariaDB Function Registry
- [ ] Schema
- [ ] Insert/update-logica
- [ ] Audit-trail

### CI/CD
- [ ] Pipeline scripts
- [ ] Build-stappen
- [ ] Validatie-stappen
- [ ] Deployment-stappen
- [ ] Rollback-veiligheid

### Runtime
- [ ] FastAPI capabilities endpoint
- [ ] React Release Dashboard

### Proces
- [ ] Markdown-logboek aanmaken
- [ ] Elke stap beschrijven
- [ ] Toestemming vragen
- [ ] Uitvoeren
- [ ] Terugkoppeling geven
- [ ] Volgende stap pas daarna beschrijven

## Validatie-sectie

### Functionele validatie
- [ ] Scripts syntactisch correct
- [ ] Manifests valide JSON
- [ ] Bump-regels correct toegepast
- [ ] Functieversies correct verhoogd
- [ ] Componentversies correct verhoogd
- [ ] Compatibiliteit checks correct

### CI/CD validatie
- [ ] Pipeline compileert
- [ ] Pipeline valideert manifests
- [ ] Pipeline voert bump-engine correct uit
- [ ] Pipeline schrijft naar registry
- [ ] Pipeline genereert stack manifest

### Runtime validatie
- [ ] Capabilities endpoint werkt
- [ ] Release Dashboard toont juiste data

### Procesvalidatie
- [ ] Stap volledig uitgevoerd
- [ ] Stap gelogd in Markdown
- [ ] Terugkoppeling gegeven
- [ ] Checklist-items afgevinkt

## Copilot werkwijze (verplicht)

Copilot moet het volledige implementatieplan opdelen in logische stappen/fasen.
Per stap uitleggen wat, waarom, opbrengst, welke bestanden/scripts/configs worden aangemaakt, toestemming vragen, daarna uitvoeren, alles loggen, terugkoppeling geven en pas daarna doorgaan.

## Belangrijk

Copilot mag geen enkele stap uitvoeren zonder expliciete toestemming.
Copilot moet alles in dit Markdown-bestand loggen.
Copilot moet nooit de bestaande FE/MW/DB code wijzigen, behalve in de allerlaatste stap waarin oude versie-logica wordt verwijderd.

*Einde van de prompt.*
