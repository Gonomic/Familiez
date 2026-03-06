# Database Re-Initialisatie Instructies
**Datum:** 6 maart 2026  
**Doel:** Complete database opnieuw initialiseren met remote toegang en file management

---

## Wat is er voorbereid?

De volgende init bestanden zijn toegevoegd/bijgewerkt in `BE/init/`:

1. **00-remote-access.sql** (NIEUW)
   - Configureert root toegang vanaf 192.168.1.% netwerk
   - Jouw dev machine krijgt direct toegang
   - Gebruikt ${MYSQL_ROOT_PASSWORD} uit .env.prod

2. **01-schema.sql** (BESTAAND)
   - Basis database schema (11 tabellen)
   - Alle relaties en constraints

3. **02-xxx.sql** (BESTAAND - 60+ bestanden)
   - Alle stored procedures en functions
   - Volledig geautomatiseerd

4. **03-releases-data.sql** (BESTAAND)
   - Release tracking tabellen en initiële data

5. **04-file-tables.sql** (NIEUW)
   - Files tabel voor bestandsmetadata
   - person_files junction tabel
   - family_files junction tabel
   - Alle indexes en foreign keys

6. **05-file-management-version.sql** (NIEUW)
   - Registreert versie 0.9.0 in be_releases
   - Registreert versie 0.9.0 in mw_releases
   - Documenteert alle file management features

---

## Bestanden kopiëren naar Synology NAS

### Methode 1: Via Nemo (SFTP - Aanbevolen)

#### Stap 1: Open twee Nemo vensters
```
Window A: /home/frans/Documenten/Dev/Familiez/BE/
Window B: sftp://192.168.1.10/volume1/docker/familiez/
```

#### Stap 2: Kopieer de VOLLEDIGE init folder
1. In Window A: Klik op de `init/` folder
2. Kopieer (Ctrl+C)
3. In Window B: Ga naar `/volume1/docker/familiez/`
4. Verwijder de oude `mysql-init/` folder (als die bestaat)
5. Plak (Ctrl+V) - dit maakt een nieuwe `init/` folder
6. Hernoem `init/` naar `mysql-init/`

**Resultaat:** Alle 66+ SQL bestanden staan in `/volume1/docker/familiez/mysql-init/`

---

### Methode 2: Via Terminal (rsync - Sneller voor grote folders)

```bash
# Vanaf je dev machine
rsync -avz --delete \
  /home/frans/Documenten/Dev/Familiez/BE/init/ \
  frans@192.168.1.10:/volume1/docker/familiez/mysql-init/

# Wachtwoord invoeren wanneer gevraagd
```

**Voordeel:** --delete zorgt dat oude bestanden worden verwijderd, alleen nieuwe blijven over

---

## Database Volledig Opnieuw Initialiseren

### Stap 1: Stop alle containers

In **Synology Container Manager GUI**:
1. Ga naar **Project** tabblad
2. Zoek het Familiez project
3. Klik **Stop** knop
4. Wacht tot alle containers gestopt zijn (grijs)

### Stap 2: Verwijder oude database data

In **Nemo (SFTP naar NAS)**:
1. Navigeer naar `/volume1/docker/familiez/`
2. Verwijder de VOLLEDIGE folder: `mysql-data/`
   - Klik rechts → **Verplaats naar prullenbak** of **Delete**
3. **Belangrijk:** Dit verwijdert ALLE database data!
4. Maak nieuwe lege folder aan: `mysql-data/`
   - Klik rechts → **Create Folder** → Naam: `mysql-data`

**Resultaat:** Database data volledig gewist, klaar voor re-initialisatie

### Stap 3: Verificatie voor start

Controleer dat deze folders bestaan en correct zijn:
```
/volume1/docker/familiez/
├── mysql-init/          ← 66+ SQL bestanden (inclusief 00-remote-access.sql)
├── mysql-data/          ← LEEG (net aangemaakt)
├── MW-build/            ← Middleware code
├── FE-build/            ← Frontend build
├── media/               ← File uploads folder
└── .env.prod            ← Environment variables (MYSQL_ROOT_PASSWORD!)
```

### Stap 4: Start containers opnieuw

In **Synology Container Manager GUI**:
1. Ga naar **Project** tabblad
2. Klik op het Familiez project
3. Klik **Start** of **Up** knop
4. Container Manager gaat nu:
   - MySQL container starten
   - Alle init scripts uitvoeren in volgorde (00, 01, 02..., 05)
   - Database volledig opbouwen

### Stap 5: Monitor initialisatie

In **Container Manager**:
1. Klik op `familiez-mysql-prod` container
2. Klik **Logs** knop
3. Kijk naar de output:
   ```
   [Note] /usr/sbin/mysqld: ready for connections
   [Note] Executing init scripts in /docker-entrypoint-initdb.d/
   [Note] Executing 00-remote-access.sql
   [Note] Remote root access configured for 192.168.1.% network
   [Note] Executing 01-schema.sql
   [Note] Executing 02-000-getTranNo.sql
   ...
   [Note] Executing 05-file-management-version.sql
   [Note] Init scripts completed
   ```

**Verwachte tijd:** 30-60 seconden voor volledige initialisatie

---

## Verificatie: Test Remote Toegang

### Test 1: Verbinding maken vanaf dev machine

```bash
# Op je dev machine
mysql -h 192.168.1.10 -P 3307 -u root -p

# Root wachtwoord invoeren (uit .env.prod)
# Als het werkt, zie je:
# Welcome to the MySQL monitor...
# MariaDB [(none)]>
```

**Resultaat:** Als je de MySQL prompt ziet → Succes! ✅

### Test 2: Controleer tabellen

```sql
-- In de MySQL console
USE humans;

-- Controleer aantal tabellen (moet 14 zijn: 11 basis + 3 file tables)
SELECT COUNT(*) AS TableCount 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA='humans';

-- Lijst van alle tabellen
SHOW TABLES;
```

**Verwacht:**
- TableCount: 14
- Inclusief: `files`, `person_files`, `family_files`

### Test 3: Controleer file management tabellen

```sql
-- Controleer files tabel structuur
DESCRIBE files;

-- Controleer person_files
DESCRIBE person_files;

-- Controleer family_files
DESCRIBE family_files;

-- Controleer releases
SELECT * FROM be_releases ORDER BY ReleaseDate DESC LIMIT 5;
SELECT * FROM mw_releases ORDER BY ReleaseDate DESC LIMIT 5;
```

**Verwacht:**
- Alle file tabellen bestaan
- Laatste release is 0.9.0 (File Management)

---

## Troubleshooting

### Probleem: "ERROR 1130: Host not allowed to connect"

**Oorzaak:** 00-remote-access.sql werd niet uitgevoerd

**Oplossing:**
1. Check of `/volume1/docker/familiez/mysql-init/00-remote-access.sql` bestaat
2. Stop containers
3. Herhaal Stap 2 (verwijder mysql-data)
4. Start opnieuw

---

### Probleem: "Table 'files' doesn't exist"

**Oorzaak:** 04-file-tables.sql werd niet uitgevoerd

**Oplossing:**
1. Check of `/volume1/docker/familiez/mysql-init/04-file-tables.sql` bestaat
2. Als het bestand er is maar tabel niet:
   ```bash
   # Handmatig uitvoeren vanaf dev machine
   mysql -h 192.168.1.10 -P 3307 -u root -p humans < /home/frans/Documenten/Dev/Familiez/BE/init/04-file-tables.sql
   ```

---

### Probleem: "Init scripts not executing"

**Oorzaak:** mysql-data folder was niet leeg

**Oplossing:**
1. Stop alle containers
2. Verwijder `/volume1/docker/familiez/mysql-data/` VOLLEDIG
3. Maak nieuwe lege folder aan
4. Start containers opnieuw

**Belangrijk:** Init scripts worden ALLEEN uitgevoerd als mysql-data leeg is!

---

## Samenvatting: Welke bestanden kopiëren?

| Van (Dev Machine) | Naar (Synology NAS) | Actie |
|-------------------|---------------------|-------|
| `BE/init/` (hele folder) | `/volume1/docker/familiez/mysql-init/` | Kopieer alle 66+ bestanden |
| - | `/volume1/docker/familiez/mysql-data/` | Verwijder & nieuw aanmaken (leeg!) |

**Kritieke bestanden in init folder:**
- ✅ `00-remote-access.sql` - Remote toegang
- ✅ `01-schema.sql` - Basis schema
- ✅ `02-xxx.sql` (60+ files) - Stored procedures
- ✅ `03-releases-data.sql` - Release tracking
- ✅ `04-file-tables.sql` - File management schema
- ✅ `05-file-management-version.sql` - Versie registratie

---

## Na Succesvolle Initialisatie

Je kunt nu vanaf je dev machine:

```bash
# Database backups maken
mysqldump -h 192.168.1.10 -P 3307 -u root -p humans > backup_$(date +%Y%m%d).sql

# Schema wijzigingen toepassen
mysql -h 192.168.1.10 -P 3307 -u root -p humans < nieuwe_migratie.sql

# Data inspecteren
mysql -h 192.168.1.10 -P 3307 -u root -p humans

# Mysqladmin gebruiken
mysqladmin -h 192.168.1.10 -P 3307 -u root -p status
```

**Geen Container Manager terminal meer nodig!** 🎉
