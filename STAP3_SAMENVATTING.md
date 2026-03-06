# Stap 3: Frontend Implementatie Bestandenbeheer - VOLTOOID

**Datum:** 5 maart 2026  
**Branch:** `feature/files-step3-frontend` (FE) + `feature/files-step3-frontend-version` (BE)  
**Status:** ✅ Voltooid

## Overzicht

In stap 3 is de frontend-integratie voor bestandenbeheer gerealiseerd in de React-app (`FE`).
De middleware- en databasefunctionaliteit uit stap 1 en 2 wordt nu volledig gebruikt vanuit de UI.

## Wat is geimplementeerd

### 1. Context menu uitgebreid met `Bestanden`

**Bestand:** `FE/src/components/PersonContextMenu.jsx`

- Nieuwe menu-optie toegevoegd: `Bestanden`
- Klik op `Bestanden` opent de rechterdrawer in bestandsbeheer-modus voor de geselecteerde persoon

### 2. RightDrawer uitgebreid met nieuwe mode `files`

**Bestand:** `FE/src/RightDrawer.jsx`

- Nieuwe drawer mode toegevoegd: `files`
- Integratie van nieuw component `PersonFilesForm`
- Bestaande modes (`select`, `edit`, `delete`, `add`, `view`) blijven intact

### 3. Nieuwe upload en bestanden UI

**Bestand:** `FE/src/components/PersonFilesForm.jsx` (nieuw)

Geimplementeerde UI-functionaliteit:

- Scope picker:
  - `person`
  - `family`
- Document type dropdown met exact vereiste waardes:
  - `portret`
  - `familiefoto`
  - `trouwakte`
  - `geboorteakte`
  - `overlijdensakte`
  - `opleidingsdocument`
  - `werkdocument`
  - `overig`
- Optioneel jaarveld
- File picker + upload knop
- Validatie op gekozen bestand
- Succes- en foutmeldingen

### 4. Thumbnail grid + preview popup

**Bestand:** `FE/src/components/PersonFilesForm.jsx`

- Twee aparte grids met groepering:
  - `Persoonlijke documenten`
  - `Familiedocumenten`
- Thumbnail URL gebruikt:
  - `/api/files/{id}/thumbnail`
- Preview popup via `window.open`:
  - `window.open("/api/files/"+fileId, "familiezPreview", "width=900,height=700,menubar=no,toolbar=no,location=no,status=no,resizable=yes,scrollbars=yes")`
- Fallback icoon voor niet-afbeeldingsbestanden of thumbnail-fouten

### 5. API service integratie

**Bestand:** `FE/src/services/familyDataService.js`

Nieuwe functies:

- `uploadDocumentFile(...)` -> `POST /api/files/upload`
- `getPersonFiles(personId)` -> `GET /api/person/{id}/files`
- `getFamilyFiles(fatherId, motherId)` -> `GET /api/family/{fatherId}/{motherId}/files`

### 6. Event flow gekoppeld van canvas -> drawer

Aangepaste bestanden:

- `FE/src/components/FamilyTreeCanvas.jsx`
- `FE/src/FamiliezBewerken.jsx`
- `FE/src/app.jsx`

Resultaat:

- Klik op persoondriehoek -> context menu -> `Bestanden`
- Rechterdrawer opent met volledige upload- en beheerflow

## Build en validatie

Uitgevoerd in `FE`:

- `npm run build` -> ✅ geslaagd

Opmerking:

- Er bestaan al pre-existente lintissues in andere, niet-step3 bestanden.
- De nieuwe step 3 bestandenfunctionaliteit zelf geeft geen IDE errors op de gewijzigde bestanden.

## Bestanden gewijzigd

### FE

- `src/components/PersonFilesForm.jsx` (nieuw)
- `src/components/PersonContextMenu.jsx`
- `src/RightDrawer.jsx`
- `src/components/FamilyTreeCanvas.jsx`
- `src/FamiliezBewerken.jsx`
- `src/app.jsx`
- `src/services/familyDataService.js`

### BE

- `UpdateVersion_2026_03_05_FE_FileManagement_UI.sql` (nieuw)

## Sync status

✅ **Alles voltooid op 5 maart 2026:**

- FE wijzigingen gepusht naar `origin` (branch `main`)
  - PR #1 gemerged naar `main`
  - Commit: `3ba16b6`
- BE versie SQL gepusht naar `origin` (branch `master`)
  - PR #4 gemerged naar `master`
  - Commit: `c2e70b7`
  - SQL script: `UpdateVersion_2026_03_05_FE_FileManagement_UI.sql` (commit `8d1318c`)
- ✅ SQL script uitgevoerd in database
  - FE Release v0.9.1 geregistreerd: **2026-03-05 10:31:56**
  - ReleaseID: 7
  - Status: Actief in database
