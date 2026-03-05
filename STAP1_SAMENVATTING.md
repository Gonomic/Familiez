# Stap 1: Opslagstructuur & Middleware Basis - VOLTOOID

**Datum:** 5 maart 2026  
**Branch:** `feature/files-step1-storage`  
**Status:** ✅ Voltooid

## Overzicht

In deze stap is de basis gelegd voor het bestanden beheersysteem van Familiez. De focus lag op de opslagstructuur op schijf en de middleware basis zonder database-afhankelijkheden.

## Wat is geïmplementeerd

### 1. File Utilities Module (`MW/file_utils.py`)

Een complete utility module met de volgende functies:

- **`slugify(text)`**: Converteert tekst naar een veilige bestandsnaam/pad
  - Lowercase conversie
  - Verwijderen van accenten en diakritische tekens
  - Alleen [a-z0-9_] karakters behouden
  - Spaties en koppeltekens naar underscore
  - Multiple underscores reduceren tot enkele
  - Leading/trailing underscores strippen

- **`generate_filename(entity_id, document_type, year, extension)`**:
  - Genereert unieke bestandsnamen volgens patroon: `<id>_<type>_<jaar>_<uuid>.<ext>`
  - Jaar is optioneel (wordt weggelaten als 0 of None)
  - UUID zorgt voor uniciteit

- **`get_person_path(base_path, person_id, first_name, last_name)`**:
  - Genereert pad: `<base>/<person_id>/<slugified_naam>/`
  - Voorbeeld: `/data/123/jan_de_vries/`

- **`get_family_path(...)`**:
  - Genereert pad: `<base>/<vader_id>_<moeder_id>/<slugified_vadernaam>_<slugified_moedernaam>/`
  - Voorbeeld: `/data/123_456/jan_bakker_marie_jansen/`

- **`ensure_directory_exists(path)`**: Maakt directories aan (inclusief parent directories)

- **`get_storage_base_path(environment)`**: Retourneert juiste base path voor development/production

### 2. Configuratie Uitbreiding

**`.env.example`** uitgebreid met:
```env
STORAGE_ENVIRONMENT=development
STORAGE_BASE_PATH=/home/frans/Documenten/Dev/Familiez/BESTANDEN
MAX_FILE_UPLOAD_SIZE=52428800  # 50MB
```

**`main.py`** configuratie variabelen toegevoegd:
- `STORAGE_ENVIRONMENT`
- `STORAGE_BASE_PATH`
- `MAX_FILE_UPLOAD_SIZE`

### 3. API Endpoints Structuur

In `MW/main.py` zijn de volgende endpoint skeletons toegevoegd:

- **`POST /api/files/upload`**: Upload een bestand
  - Parameters: file, scope ("person"/"family"), entity_id, document_type, year, person_data
  - Bevat file size validatie (max 50MB)
  - Volledige implementatie volgt in stap 2 (na database setup)

- **`GET /api/files/{file_id}`**: Download een bestand
  - Skeleton retourneert 501 (pending database)

- **`GET /api/files/{file_id}/thumbnail`**: Thumbnail van een afbeelding
  - Skeleton retourneert 501 (pending implementation)

- **`GET /api/person/{person_id}/files`**: Alle bestanden van een persoon
  - Skeleton retourneert lege lijst

- **`GET /api/family/{father_id}/{mother_id}/files`**: Alle bestanden van een familie
  - Skeleton retourneert lege lijst

### 4. Tests

**`MW/test_file_utils.py`** aangemaakt met 23 tests:
- ✅ Alle tests slagen (23/23 passed)
- Dekking: slugify, generate_filename, path generation, directory creation
- Tests valideren correcte handling van:
  - Accenten en diakritische tekens
  - Speciale karakters
  - Edge cases (lege strings, multiple underscores, etc.)
  - Complexe namen (Jan-Willem, François Müller, etc.)

### 5. Import Updates

FastAPI imports uitgebreid met:
- `UploadFile`, `File`, `Form` voor file uploads
- `StreamingResponse`, `FileResponse` voor downloads

## Pad Voorbeelden

**Development:**
```
/home/frans/Documenten/Dev/Familiez/BESTANDEN/
├── 123/
│   └── jan_de_vries/
│       ├── 123_portret_1950_a1b2c3d4.jpg
│       └── 123_geboorteakte_e5f6g7h8.pdf
└── 123_456/
    └── jan_bakker_marie_jansen/
        └── 123_456_familiefoto_2000_xyz123.jpg
```

**Production:**
```
/docker/familiez/media/
├── 123/
│   └── jan_de_vries/
│       └── ...
└── 123_456/
    └── jan_bakker_marie_jansen/
        └── ...
```

## Bestanden Gewijzigd/Toegevoegd

### Nieuw:
- `MW/file_utils.py` (195 regels)
- `MW/test_file_utils.py` (179 regels)

### Gewijzigd:
- `MW/.env.example` (+6 regels config)
- `MW/main.py` (+155 regels: imports, config, endpoints)

## Technische Details

- **Bestandsnaam formaat**: `<entity_id>_<type>_<year>_<uuid>.<ext>`
- **UUID**: Eerste 8 karakters van UUID4 voor kortere maar nog steeds unieke IDs
- **Slugify algoritme**: NFKD normalisatie + ASCII encoding voor accent removal
- **Directory structuur**: Geschikt voor duizenden personen (geen flat structure)

## Volgende Stap

**Stap 2: Database Setup**
- `files` tabel met metadata
- `person_files` koppeltabel
- `family_files` koppeltabel
- SQL migratie scripts
- Integratie met MW endpoints
- Versie-informatie update in database

## Git Info

- **Branch**: `feature/files-step1-storage`
- **Commits**: Pending
- **Merge status**: Pending naar main

---

**Notities voor volgende stappen:**
- De `BESTANDEN/` folder bestaat al op het development systeem
- Alle endpoint skeletons zijn klaar om geïntegreerd te worden met database in stap 2
- Thumbnail generatie logica is nog niet geïmplementeerd (PIL/Pillow needed?)
- Database schema moet rekening houden met hergebruik van bestanden (één fysiek bestand, meerdere koppelingen)
