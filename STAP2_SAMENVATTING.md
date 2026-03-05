# Stap 2: Database & Middleware Implementatie - VOLTOOID

**Datum:** 5 maart 2026  
**Branches:** `feature/files-step2-database` (BE + MW)  
**Status:** ✅ Voltooid

## Overzicht

In stap 2 is de volledige database structuur aangemaakt en alle middleware endpoints volledig geïmplementeerd. Het bestandenbeheer systeem is nu volledig functioneel op de backend en middleware lagen.

## Wat is geïmplementeerd

### 1. Database Tabellen (`BE/CreateFileTables.sql`)

Drie nieuwe tabellen toegevoegd aan de `humans` database:

#### **`files` tabel**
Metadata voor geüploade bestanden:
- `FileID` (PK, AUTO_INCREMENT)
- `FilePath` - relatief pad vanaf storage base
- `FileName` - gegenereerde unieke bestandsnaam
- `OriginalFileName` - originele upload naam
- `DocumentType` - type document (portret, geboorteakte, etc.)
- `Year` - optioneel jaartal
- `FileSize` - grootte in bytes
- `MimeType` - MIME type
- `CreatedAt` - upload timestamp
- `UploadedBy` - username van uploader
- `Timestamp` - laatste wijziging

**Indexes:** DocumentType, Year, CreatedAt

#### **`person_files` tabel**  
Koppeltabel personen ↔ bestanden:
- `PersonFileID` (PK)
- `PersonID` → `persons.PersonID` (FK, CASCADE DELETE)
- `FileID` → `files.FileID` (FK, CASCADE DELETE)
- Unique constraint op `(PersonID, FileID)`

#### **`family_files` tabel**
Koppeltabel families ↔ bestanden:
- `FamilyFileID` (PK)
- `FatherID` → `persons.PersonID` (FK, CASCADE DELETE)
- `MotherID` → `persons.PersonID` (FK, CASCADE DELETE)
- `FileID` → `files.FileID` (FK, CASCADE DELETE)
- Unique constraint op `(FatherID, MotherID, FileID)`

**Voordelen:**
- Geen duplicatie: één fysiek bestand, meerdere koppelingen mogelijk
- Cascade deletes: verwijderen van persoon/bestand verwijdert automatisch koppelingen
- Referential integrity via foreign keys

### 2. Middleware Endpoints - Volledig Geïmplementeerd

#### **POST /api/files/upload**
Volledige file upload met storage en database integratie:
- **Input**: MultipartForm met file, scope, entity_id, document_type, year, person_data (JSON)
- **Scope logica**:
  - `"person"`: Opslaan in `<base>/<person_id>/<slugified_naam>/`
  - `"family"`: Opslaan in `<base>/<father_id>_<mother_id>/<slugified_names>/`
- **File verwerking**:
  - Size validatie (max 50MB)
  - Automatische directory aanmaak
  - Unieke filename generatie met UUID
  - MIME type detectie
- **Database**:
  - Insert in `files` tabel
  - Koppeling in `person_files` of `family_files`
  - Transaction met commit
- **Return**: file_id, filename, size, mime_type, etc.

#### **GET /api/files/{file_id}**
File download:
- Metadata ophalen uit database
- Full path construeren
- FileResponse met correcte headers en MIME type
- Original filename in download header

#### **GET /api/files/{file_id}/thumbnail**
Thumbnail generatie (nieuw!):
- On-the-fly thumbnail generatie met Pillow
- 200x200px met aspect ratio behouden
- RGBA → RGB conversie met witte achtergrond
- JPEG output met 85% quality
- Cache header (1 jaar)
- Alleen voor image MIME types

#### **GET /api/person/{person_id}/files**
Query alle bestanden van een persoon:
- JOIN tussen `files` en `person_files`
- Gesorteerd op upload datum (DESC)
- Return: array met file metadata

#### **GET /api/family/{father_id}/{mother_id}/files**
Query alle bestanden van een familie:
- JOIN tussen `files` en `family_files`
- Gesorteerd op upload datum (DESC)
- Return: array met file metadata

### 3. Dependencies Toegevoegd

**`MW/requirements.txt` uitgebreid met:**
- `Pillow==10.2.0` - Image processing voor thumbnails
- `python-multipart==0.0.6` - FastAPI file upload support

### 4. Imports & Utilities

**`MW/main.py` imports uitgebreid:**
```python
from PIL import Image
import io
import json
from pathlib import Path
```

Alle `file_utils` functies worden nu actief gebruikt in de endpoints.

### 5. Versie Informatie

**`BE/UpdateVersion_2026_03_05_FileManagement.sql`:**
- BE release 0.9.0 met 5 changes (tabellen, indexes, constraints)
- MW release 0.9.0 met 12 changes (endpoints, utilities, dependencies)

## Technische Hoogtepunten

### File Upload Flow
1. Client → POST multipart/form-data
2. MW: File size check
3. MW: Parse person_data JSON
4. MW: Generate storage path (scope-dependent)
5. MW: Create directories
6. MW: Write file to disk
7. MW: Insert metadata in `files`
8. MW: Create link in `person_files` / `family_files`
9. MW: Return file_id

### Thumbnail Generation
- Gebruikt PIL/Pillow
- Lazy generation (geen pre-processing)
- Aspect ratio maintained
- Format conversies (RGBA→RGB met white background)
- Efficient caching headers

### Database Design
- Normalized: geen redundantie
- Referential integrity
- Cascade deletes
- Optimized indexes voor queries
- Consistent naming (PascalCase columns)

## Bestanden Toegevoegd/Gewijzigd

### BE folder:
- **Nieuw**: `CreateFileTables.sql` (97 regels)
- **Nieuw**: `UpdateVersion_2026_03_05_FileManagement.sql` (33 regels)

### MW folder:
- **Gewijzigd**: `main.py` (+~280 regels netto, volledige endpoint implementaties)
- **Gewijzigd**: `requirements.txt` (+2 dependencies)

## Code Statistieken

- **Database tabellen**: 3 nieuwe tabellen
- **API endpoints**: 5 endpoints (allen volledig geïmplementeerd)
- **Foreign keys**: 6 FK constraints
- **Indexes**: 10 indexes voor performance
- **Dependencies**: 2 nieuwe packages

## Testing Notes

**Handmatige tests vereist:**
1. Database setup: voer `CreateFileTables.sql` uit
2. Test upload voor person scope
3. Test upload voor family scope
4. Test download
5. Test thumbnail voor images
6. Test query endpoints
7. Voer versie SQL uit: `UpdateVersion_2026_03_05_FileManagement.sql`

**Test scenario's:**
- Upload PNG/JPEG → thumbnail moet werken
- Upload PDF → thumbnail moet 400 error geven
- Upload > 50MB → moet 413 error geven
- Download niet-bestaand bestand → 404
- Query voor persoon zonder bestanden → lege array

## Volgende Stap

**Stap 3: Frontend Implementatie**
- Menu optie "Bestanden" in PersonContextMenu
- Upload UI in RightDrawer
- Thumbnail weergave
- Preview popup
- Documenttype selector
- Jaar input (optioneel)
- Groepering: persoonlijk vs familie
- Integration met bestaande React components

## Git Info

- **Branches**: 
  - `BE: feature/files-step2-database`
  - `MW: feature/files-step2-database`
- **Commits**: Pending
- **Merge status**: Pending naar main/master

---

**Notities:**
- Thumbnail generation werkt alleen voor images (intentioneel)
- File uploads zijn authenticated (via SSO middleware)
- uploaded_by komt van JWT claims (preferred_username)
- Paths zijn relatief opgeslagen voor portabiliteit dev/prod
- Een bestand kan aan meerdere personen/families gekoppeld worden (via junction tables)
- Cascade deletes: verwijderen van persoon verwijdert automatisch gekoppelde files
