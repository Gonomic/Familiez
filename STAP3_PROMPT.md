# Stap 3: Frontend Implementatie - START PROMPT

Kopieer alles onder deze regel en plak het in een NIEUWE Copilot Chat:

---

Lees eerst deze bestanden uit de Familiez root folder:

1. "Ontwikkelstap bestanden.md" - originele requirements
2. "STAP1_SAMENVATTING.md" - wat in stap 1 gedaan is
3. "STAP2_SAMENVATTING.md" - wat in stap 2 gedaan is  
4. "DATABASE_MIGRATION_TEST.md" - migraties zijn uitgevoerd en getest

Database en middleware zijn volledig klaar. We gaan nu beginnen met stap 3: **Frontend implementatie**.

## Stap 3 Vereisten:

In React (FE folder) moet je implementeren:

### 1. Menu optie "Bestanden"
- Toevoegen in PersonContextMenu component
- Trigger door klik op persoon driehoek op canvas

### 2. Upload UI in RightDrawer
- Scope picker: "person" of "family"
- Document type dropdown:
  - portret
  - familiefoto
  - trouwakte
  - geboorteakte
  - overlijdensakte
  - opleidingsdocument
  - werkdocument
  - overig
- Jaar input (optioneel)
- File picker / file input
- Upload button met loading state

### 3. Bestandenoverzicht
- Thumbnail grid met geüploade bestanden
- Thumbnails van `/api/files/{id}/thumbnail`
- Klik op thumbnail → preview popup

### 4. Preview Popup
```javascript
window.open("/api/files/"+fileId, "familiezPreview", "width=900,height=700,menubar=no,toolbar=no,location=no,status=no,resizable=yes,scrollbars=yes");
```

### 5. Groepering
- Twee secties in RightDrawer:
  - "Persoonlijke documenten" (person scope)
  - "Familie documenten" (family scope)

### 6. API Integratie
- POST /api/files/upload (multipart form-data)
- GET /api/person/{person_id}/files
- GET /api/family/{father_id}/{mother_id}/files
- GET /api/files/{file_id}/thumbnail
- Axios of fetch voor HTTP calls
- SSO token via request headers (Authorization: Bearer)

## Workflow:

1. **Git branch aanmaken**: `feature/files-step3-frontend`
2. **Per stap approve vragen** voordat implementation start
3. **Nieuwe componenten** waar nodig
4. **Updates bestaande components** (PersonContextMenu, RightDrawer)
5. **Tests** waar mogelijk
6. **Samenvatting opslaan** in Familiez root
7. **Git workflow**: commit → push → merge → push main

Let op: Zorg dat je bestandsnaam pattern en pad generatie identiek is aan MW (file_utils.py patterns gebruiken of repliceren in JS).

Go!
