
# Familiez status update — 2 augustus 2026

## Huidige focus
Deze sessie stond in het teken van het corrigeren van de tekenvolgorde in de stamboomlayout, zodat onderliggende generaties primair door oudervolgorde worden bepaald en niet door losse heuristiek.

## Wat is al aangepast
- In [FE/src/components/FamilyTreeCanvas.jsx](FE/src/components/FamilyTreeCanvas.jsx) is de generatie-opbouw aangepast naar een deterministischer model.
- De globale her-sortering die de oudervolgorde kon overschrijven is verwijderd.
- De plaatsing gebeurt nu in 2 passes:
  - eerst maximale generatiebreedte bepalen
  - daarna generaties sequentieel plaatsen, zodat ouder-ankers beschikbaar zijn wanneer kindgroepen worden bepaald
- De volgorde voor kinderen in onderliggende generaties volgt nu de bovenliggende oudervolgorde; leeftijd geldt alleen binnen de eigen oudergroep.
- Tijdelijke debug-logging voor layoutanalyse is toegevoegd en later weer verwijderd.

## Belangrijke technische status
- FE: build meerdere keren geverifieerd met `npm run build`.
- FE-wijzigingen zijn gecommit en gepusht op branch `backup/family-tree-equal-width-layout-2026-07-26`.
- MW: auth-fallback bij verlopen JWT (server-side sessie) afgerond, tests geverifieerd (`test_auth.py`), gecommit en gepusht op branch `feature/nieuwe-wijzigingen-2026-06-28`.

## Branches / Git status
- FE branch: `backup/family-tree-equal-width-layout-2026-07-26` (up-to-date met origin)
- MW branch: `feature/nieuwe-wijzigingen-2026-06-28` (up-to-date met origin)

## Volgende stap
- Nieuwe menu-items functioneel testen in FE (o.a. Broer toevoegen en verwante nieuwe acties).
- Pas na die testfase bepalen of extra layout-finetuning nog nodig is.

## Expliciete actie voor de volgende keer
- Testscenario's doorlopen voor de nieuwe menu-items (Broer toevoegen, etc.).
- Bevindingen noteren per actie (verwacht gedrag vs. werkelijk gedrag).
- Eventuele regressies eerst functioneel afhandelen, daarna pas eventueel visuele polish.

## Opmerking
Er is in deze sessie naast FE-layout ook MW-auth code aangepast en veiliggesteld in Git.



