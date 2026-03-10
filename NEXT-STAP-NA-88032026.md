# NEXT STAP NA 88032026

Dit bestand is bedoeld als direct herbruikbare prompt-context voor Copilot in een volgende sessie.

## Huidige status (bevestigd)
- Probleem opgelost: AddPerson blijft werken na JWT-expiry.
- Root cause was: `USE_SERVER_SESSIONS` kwam niet in de `mw` container.
- Fix is toegepast in compose:
  - `docker-compose.prod.yml` -> onder `services.mw.environment` toegevoegd:
    - `ENVIRONMENT: ${ENVIRONMENT:-production}`
    - `USE_SERVER_SESSIONS: ${USE_SERVER_SESSIONS:-true}`
  - `docker-compose.yml` idem toegevoegd voor consistentie.
- Productie werkt met handmatige kopie via Nemo naar Synology (geen git deploy, geen ssh workflow).
- Runtime code in `MW-build` op Synology wordt gebruikt voor build/deploy.

## Stap 1 (al uitgevoerd)
- Tijdelijke debug-logging verwijderd uit:
  - `MW/session_manager.py`
  - `MW/main.py`

## Cleanup nog uitvoeren op productie (later)
Doel: ook op Synology de debug-cleanup live zetten.

Te doen:
1. Kopieer met Nemo deze 2 lokale bestanden naar Synology `MW-build`:
  - `MW/session_manager.py` -> `MW-build/session_manager.py`
  - `MW/main.py` -> `MW-build/main.py`
2. Rebuild/deploy de stack in Container Manager.
3. Controleer MW-log:
  - Geen `[Sessions DEBUG]` regels meer.
  - Login en `AddPerson` blijven werken (geen regressie).

## Openstaande acties voor later

### Stap 2 - Korte regressietest (functioneel)
Doel: bevestigen dat auth/sessie-flow stabiel blijft na cleanup.

Uit te voeren checks:
1. Login op productie.
2. `AddPerson` direct uitvoeren (moet slagen).
3. 5+ minuten wachten (JWT is kortlevend).
4. Nogmaals `AddPerson` uitvoeren (moet ook slagen via server-side sessie).
5. Logout en opnieuw login.
6. Nogmaals `AddPerson` uitvoeren (moet slagen).

Te noteren:
- Tijdstip van elke teststap.
- Of er ergens 401 terugkomt.
- Relevante MW logregels rond eventuele fouten.

### Stap 3 - TLS verificatie verbeteren
Doel: waarschuwing oplossen:
- `InsecureRequestWarning: Unverified HTTPS request is being made to host 'sso.dekknet.com'`

Plan:
1. Controleer of certificaatketen van `sso.dekknet.com` volledig en vertrouwd is binnen de MW-container.
2. Voeg indien nodig CA-certificaat toe aan container trust store.
3. Zet daarna in productieconfig:
   - `SYNOLOGY_OIDC_VERIFY_SSL=true`
4. Rebuild/deploy stack.
5. Controleer logs: warning moet weg zijn.
6. Volledige login-flow opnieuw testen.

Risico:
- Als certificaatketen niet correct is, kan login-flow falen zodra SSL-verificatie aan staat.

## Prompt-template voor volgende Copilot sessie
Gebruik onderstaande tekst 1-op-1 als prompt:

"""

## Laatste toevoeging (afsluiting 2026-03-08)
- Alle relevante wijzigingen zijn gepusht naar de centrale repos (`Familiez`, `Familiez-MW`, `Familiez-BE`).
- DB-versie-informatie is opgenomen via script: `BE/UpdateVersion_2026_03_08_MW_SessionFallback_ProdCompose.sql`.
- Let op: dit script moet nog op de live database worden uitgevoerd tijdens een volgende deploy-run om de versie ook fysiek in prod DB te registreren.
- Sessie afgerond op verzoek gebruiker.

## Extra aandachtspunt - compose warning in dev
- Bij `docker compose stop` in dev verschenen waarschuwingen dat deze variabelen niet gezet waren:
  - `VITE_SYNOLOGY_DISCOVERY_URL`
  - `VITE_API_BASE`
  - `VITE_SYNOLOGY_AUTH_URL`
- Impact:
  - Voor `stop` is dit onschuldig.
  - Voor `up/build` van FE kan dit wel leiden tot verkeerde of lege frontend runtime-config.
- Actie voor later (alleen indien dev stack weer gebruikt wordt):
  1. Controleer `.env` in de root van `Familiez` op bovenstaande `VITE_*` variabelen.
  2. Zet correcte dev-waarden.
  3. Start dev stack opnieuw en verifieer FE login/API routes.
Context:
- Project: Familiez (MW/FE/BE), productie op Synology NAS via Container Manager.
- Deploymethode: handmatige kopie met Nemo van lokale bestanden naar Synology projectmap; daarna stack rebuild/deploy in Container Manager.
- Geen git-based productie deploy.
- Productie composebestand: docker-compose.prod.yml in root van Familiez map op Synology.
- MW draait vanaf MW-build map in compose.

Wat al opgelost is:
- AddPerson 401 na JWT-expiry was veroorzaakt doordat USE_SERVER_SESSIONS niet in mw container stond.
- Compose fix is toegevoegd: ENVIRONMENT en USE_SERVER_SESSIONS onder services.mw.environment.
- Functionaliteit werkt nu in productie.
- Tijdelijke debug logging is al verwijderd uit MW/session_manager.py en MW/main.py.

Wat ik nu wil:
1) Begeleid me bij een korte regressietest voor login/sessie/AddPerson (5+ min wachttest inbegrepen).
2) Daarna begeleid me om SYNOLOGY_OIDC_VERIFY_SSL veilig op true te zetten en InsecureRequestWarning op te lossen, inclusief risico-check en rollback-plan.

Werkstijl:
- Geef concrete stappen in kleine blokken.
- Houd rekening met Synology Container Manager workflow (GUI-first).
- Gebruik alleen commando's als ik daar expliciet om vraag.
"""
