# Familiez Production Deployment Guide

**Last Updated:** 6 maart 2026  
**Target:** Synology NAS (192.168.1.10) at `/volume1/docker/familiez/`

---

## Table of Contents

1. [Deployment Overview](#deployment-overview)
2. [First-Time Deployment (Empty Database)](#first-time-deployment-empty-database)
3. [Update Deployment (Existing Database)](#update-deployment-existing-database)
4. [Detailed Procedures](#detailed-procedures)
5. [Troubleshooting](#troubleshooting)

---

## Deployment Overview

### Architecture Stack

```
Familiez Production (Docker Compose)
├── MySQL Container (MariaDB 10.6)
│   ├── Port: 3306
│   ├── Database: humans
│   └── Data: ./mysql-data
├── Middleware Container (FastAPI)
│   ├── Port: 18000 → 8000
│   ├── Code: ./MW-build
│   └── Files: ./BESTANDEN
├── Frontend Container (nginx)
│   ├── Port: 18080 → 80
│   └── Static: ./FE-build
└── Portainer Container
    └── Port: 9000
```

### NAS Folder Structure

```
/volume1/docker/familiez/
├── docker-compose.yml          # Production compose file
├── .env                        # Production environment variables
├── FE-build/                   # Frontend static files (from npm build)
│   ├── assets/
│   ├── index.html
│   └── nginx.conf
├── MW-build/                   # Middleware source code
│   ├── main.py
│   ├── auth.py
│   ├── Dockerfile
│   └── requirements.txt
├── mysql-data/                 # Database persistent storage
├── mysql-init/                 # SQL initialization scripts (first-time only)
└── BESTANDEN/                  # User uploaded files
```

### Two Deployment Scenarios

| Scenario | Database State | Init Scripts | Time Required | Risk Level |
|----------|---------------|--------------|---------------|------------|
| **First-Time** | Empty/New | Required | 30-45 min | Low |
| **Update** | Existing | Not needed | 10-15 min | Medium |

---

## First-Time Deployment (Empty Database)

### Overview

Use this when:
- ✅ First installation on NAS
- ✅ Database container deleted/reset
- ✅ `mysql-data/` folder empty or missing

**Critical:** Init scripts run **only once** when MySQL finds empty data directory.

### Quick Steps

1. **Prepare locally** (10 min)
   - Build FE: `cd FE && npm run build`
   - Copy MW code ready
   - Copy SQL init scripts ready

2. **Prepare NAS folders** (5 min)
   ```
   /volume1/docker/familiez/
   ├── FE-build/          (create empty)
   ├── MW-build/          (create empty)
   ├── mysql-data/        (create empty - MUST be empty for init)
   ├── mysql-init/        (create empty)
   └── BESTANDEN/         (create empty)
   ```

3. **Transfer files** (10 min)
   - Local `FE/dist/*` → NAS `FE-build/`
   - Local `FE/nginx.conf` → NAS `FE-build/nginx.conf`
   - Local `MW/*` → NAS `MW-build/`
   - Local `BE/init/*` → NAS `mysql-init/` (numbered SQL files)
   - Local `docker-compose.prod.yml` → NAS `docker-compose.yml`
   - Local `.env` → NAS `.env`

4. **Deploy** (5 min)
   - Container Manager → Project → Create
   - Select `docker-compose.yml`
   - Build + Start

5. **Verify init completed** (5 min)
   - Check MySQL logs: "ready for connections"
   - Check tables exist: `docker exec familiez-mysql mysql -u root -p humans -e "SHOW TABLES;"`

### Detailed Procedure

See [Detailed Procedures → First-Time Setup](#first-time-setup-detailed)

---

## Update Deployment (Existing Database)

### Overview

Use this when:
- ✅ Containers already running on NAS
- ✅ Database has data (`mysql-data/` populated)
- ✅ Only code changes (FE/MW)

**Note:** Database schema changes require migration steps (see Troubleshooting).

### Quick Steps

1. **Prepare locally** (5 min)
   - Build FE: `cd FE && npm run build`
   - Verify MW changes committed

2. **Backup on NAS** (2 min)
   - Copy `FE-build` → `FE-build_backup_YYYYMMDD`
   - Copy `MW-build` → `MW-build_backup_YYYYMMDD`

3. **Transfer updated code** (5 min)
   - Clear `FE-build/*`
   - Copy local `FE/dist/*` → NAS `FE-build/`
   - Copy local `FE/nginx.conf` → NAS `FE-build/nginx.conf`
   - Clear `MW-build/*`
   - Copy local `MW/*` → NAS `MW-build/`
   - Update `docker-compose.yml` if changed
   - Update `.env` if changed

4. **Redeploy** (3 min)
   - Container Manager → Project → Stop
   - Container Manager → Project → Build + Start

5. **Verify** (2 min)
   - Check FE loads: `https://familiez.dekknet.com`
   - Check API: `https://api.dekknet.com/docs`
   - Check logs for errors

**Total Time:** ~15 minutes

### Detailed Procedure

See [Detailed Procedures → Update Deployment](#update-deployment-detailed)

---

## Detailed Procedures

### First-Time Setup (Detailed)

#### 1. Local Preparation

**1.1 Build Frontend**
```bash
cd /home/frans/Documenten/Dev/Familiez/FE
npm run build
```
✅ Creates `FE/dist/` with production bundles

**1.2 Verify Files Ready**
- [ ] `FE/dist/` folder exists with assets/
- [ ] `FE/nginx.conf` file exists
- [ ] `MW/` folder has main.py, Dockerfile, requirements.txt
- [ ] `BE/init/` has numbered SQL files (001_*, 002_*, etc.)
- [ ] `docker-compose.prod.yml` updated with latest changes
- [ ] `.env` has production credentials
- [ ] `.env` sets `ENVIRONMENT=production` (disables debug-only endpoint `/auth/session-info`)

#### 2. Connect to NAS

**2.1 Via Nemo File Manager**
1. Open Nemo → File → Connect to Server
2. Protocol: SSH (SFTP)
3. Server: 192.168.1.10, Port: 22
4. Username: admin (or your user)
5. Connect

**2.2 Navigate to Deployment Folder**
```
volume1 → docker → familiez
```

#### 3. Create NAS Folder Structure

**3.1 Create Base Folders** (if they don't exist)
Right-click in familiez folder → New Folder:
- `FE-build`
- `MW-build`
- `mysql-data` (MUST be empty for first init)
- `mysql-init`
- `BESTANDEN`

**3.2 Verify Permissions**
All folders should be writable by docker user (typically uid 1000 or admin).

#### 4. Transfer Files to NAS

**4.1 Frontend**
- Local: `FE/dist/*` (all contents)
- Target: NAS `/volume1/docker/familiez/FE-build/`
- Method: Select all in dist/, Ctrl+C, paste in FE-build/

**4.2 Frontend nginx config**
- Local: `FE/nginx.conf`
- Target: NAS `/volume1/docker/familiez/FE-build/nginx.conf`

**4.3 Middleware**
- Local: `MW/*` (all files including Dockerfile)
- Target: NAS `/volume1/docker/familiez/MW-build/`

**4.4 Database Init Scripts**
- Local: `BE/init/*` (all .sql files)
- Target: NAS `/volume1/docker/familiez/mysql-init/`
- ⚠️ Ensure numerical order (001, 002, 003, etc.)

**4.5 Docker Compose**
- Local: `docker-compose.prod.yml`
- Target: NAS `/volume1/docker/familiez/docker-compose.yml`
- ⚠️ Rename to `docker-compose.yml` on NAS

**4.6 Environment Variables**
- Local: `.env` (root folder with production values)
- Target: NAS `/volume1/docker/familiez/.env`

#### 5. Deploy via Container Manager

**5.1 Open Container Manager**
- DSM → Container Manager

**5.2 Create Project**
1. Project tab → Create
2. Project name: `familiez`
3. Path: `/volume1/docker/familiez`
4. Source: Existing compose file
5. Select: `docker-compose.yml`

**5.3 Build and Start**
1. Review services (mysql, mw, fe, portainer)
2. Click "Done" or "Start"
3. Container Manager will:
   - Pull base images (mariadb, nginx, python)
   - Build MW image from Dockerfile
   - Create volumes
   - Start containers in order (mysql → mw → fe)

**5.4 Monitor Logs**
- Click on `familiez-mysql` container
- View logs
- Wait for: `[Note] mysqld: ready for connections`
- Watch for init script execution: `Executing /docker-entrypoint-initdb.d/001_*.sql`

#### 6. Verify Deployment

**6.1 Check All Containers Running**
Container Manager → Container tab:
- ✅ familiez-mysql: running
- ✅ familiez-mw: running
- ✅ familiez-fe: running
- ✅ familiez-portainer: running

**6.2 Verify Database Initialized**
Terminal or Container Manager terminal on mysql container:
```bash
docker exec -it familiez-mysql mysql -u root -p
# Enter DB_ROOT_PASSWORD from .env
```
```sql
USE humans;
SHOW TABLES;
-- Should show: persons, families, relationships, etc.
```

**6.3 Test Frontend**
Browser: `http://192.168.1.10:18080`
- ✅ Page loads
- ✅ No console errors
- ✅ Login button visible

**6.4 Test API**
Browser: `http://192.168.1.10:18000/docs`
- ✅ FastAPI docs load
- ✅ Endpoints visible

**6.5 Test SSO Login** (if configured)
- Click login
- Redirects to Synology SSO
- After login, redirects back
- User authenticated

---

### Update Deployment (Detailed)

#### 1. Local Preparation

**1.1 Build Frontend**
```bash
cd /home/frans/Documenten/Dev/Familiez/FE
npm run build
```

**1.2 Verify Changes**
- [ ] FE changes reflected in dist/
- [ ] MW code changes committed locally
- [ ] No database schema changes (or plan migration)

#### 2. Backup Current NAS Version

**2.1 Via Nemo/SFTP**
Navigate to `/volume1/docker/familiez/`

**2.2 Create Backup Folders**
- Right-click `FE-build` → Copy
- Paste as → `FE-build_backup_20260306` (use today's date)
- Right-click `MW-build` → Copy  
- Paste as → `MW-build_backup_20260306`

**2.3 Optional: Backup Database**
```bash
docker exec familiez-mysql mysqldump -u root -p humans > backup_20260306.sql
```

#### 3. Stop Containers

**3.1 Via Container Manager**
- Project tab → familiez
- Click "Stop"
- Wait for all containers to stop

#### 4. Update Code on NAS

**4.1 Clear Old Frontend**
- Navigate to `FE-build/`
- Select all (Ctrl+A)
- Delete

**4.2 Copy New Frontend**
- Local: `FE/dist/*`
- Target: NAS `FE-build/`
- Copy nginx.conf too

**4.3 Clear Old Middleware**
- Navigate to `MW-build/`
- Select all (Ctrl+A)
- Delete

**4.4 Copy New Middleware**
- Local: `MW/*`
- Target: NAS `MW-build/`

**4.5 Update Config If Changed**
- Copy `docker-compose.prod.yml` → `docker-compose.yml` (if modified)
- Copy `.env` (if variables added/changed)

#### 5. Rebuild and Start

**5.1 Via Container Manager**
- Project tab → familiez
- Action menu → Build
- Wait for build to complete
- Click "Start"

**5.2 Monitor Startup**
- Watch container logs
- MW will rebuild (takes ~2 min)
- Services start in dependency order

#### 6. Verify Update

**6.1 Check Logs**
- familiez-mw: No errors, "Uvicorn running"
- familiez-fe: nginx started
- familiez-mysql: "ready for connections"

**6.2 Test Application**
- Frontend loads with new changes
- API functions correctly
- Database data intact
- SSO login works

---

## Troubleshooting

### Container Fails to Start

**Symptom:** Container exits immediately after start

**Check:**
```bash
docker logs familiez-mw
docker logs familiez-mysql
```

**Common Causes:**
- Missing .env variables → Check .env file exists and has all required vars
- Port already in use → Change port in docker-compose.yml
- Volume mount path wrong → Verify folders exist on NAS

### Database Init Scripts Not Running

**Symptom:** Tables don't exist after first deployment

**Cause:** `mysql-data/` not empty when container started

**Fix:**
1. Stop mysql container
2. Delete contents of `mysql-data/` folder  
3. Start container again (init scripts will run)

### MW Build Fails

**Symptom:** "Failed to build mw service"

**Check:**
- Dockerfile exists in MW-build/
- requirements.txt exists
- Python base image accessible

**Fix:**
- Verify MW-build/ has all MW source files
- Check Container Manager logs for specific error

### Port Conflicts

**Symptom:** "Bind for 0.0.0.0:XXXX failed: port already in use"

**Current Ports:**
- 3306: MySQL
- 18000: MW API
- 18080: FE nginx
- 9000: Portainer

**Fix:**
- Check what's using port: `sudo netstat -tlnp | grep :PORT`
- Stop conflicting service or change port in docker-compose.yml

### Volume Mount Errors

**Symptom:** "path does not exist" or "no such file or directory"

**Fix:**
- Verify exact folder names on NAS (case-sensitive)
- Create missing folders
- Check docker-compose.yml paths match NAS structure

### Database Schema Migrations

**When Needed:**
- Adding/removing columns
- Creating new tables
- Changing constraints

**Procedure:**
1. Backup database first
2. Create migration SQL files
3. Apply manually via mysql CLI or phpMyAdmin
4. Test thoroughly before proceeding

---

## Quick Reference

### Essential NAS Paths

| Component | NAS Path |
|-----------|----------|
| Compose file | `/volume1/docker/familiez/docker-compose.yml` |
| Environment | `/volume1/docker/familiez/.env` |
| Frontend | `/volume1/docker/familiez/FE-build/` |
| Middleware | `/volume1/docker/familiez/MW-build/` |
| Database data | `/volume1/docker/familiez/mysql-data/` |
| Init scripts | `/volume1/docker/familiez/mysql-init/` |
| User files | `/volume1/docker/familiez/BESTANDEN/` |

### Port Mapping

| Service | Host Port | Container Port | External URL |
|---------|-----------|----------------|--------------|
| Frontend | 18080 | 80 | https://familiez.dekknet.com |
| API | 18000 | 8000 | https://api.dekknet.com |
| MySQL | 3306 | 3306 | Internal only |
| Portainer | 9000 | 9000 | http://192.168.1.10:9000 |

### Key Commands

**View logs:**
```bash
docker logs familiez-mysql
docker logs familiez-mw
docker logs familiez-fe
```

**Restart service:**
```bash
docker restart familiez-mw
```

**Check database:**
```bash
docker exec -it familiez-mysql mysql -u root -p humans
```

**Rebuild MW:**
```bash
cd /volume1/docker/familiez
docker compose build mw
docker compose up -d
```

**Result:** New frontend build deployed

#### Step 3.3: Transfer MW Code to NAS
1. In Nemo Window A (Local Machine): Navigate to `MW/`
2. Select these folders/files: `app/`, `Dockerfile`, `requirements.txt`
3. **Copy** (Ctrl+C)
4. Switch to Nemo Window B (NAS): Navigate to `/volume1/docker/familiez/MW-build/`
5. **Paste** (Ctrl+V) - wait for copy to complete
6. Verify files appear on NAS

**Result:** New middleware build deployed

#### Step 3.4: Copy Docker Compose Config
1. In Nemo Window A (Local Machine): Right-click `docker-compose.prod.yml`
2. **Copy** (Ctrl+C)
3. Switch to Nemo Window B (NAS): Navigate to `/volume1/Docker/Familiez/`
   - **Note:** This is the Docker application folder (different from /docker/familiez)
   - If this folder doesn't exist, create it
4. **Paste** (Ctrl+V)
5. Rename file if needed to `docker-compose.yml`

**Result:** Container Manager will auto-detect this file

---

### Phase 4: Configure Docker Container Manager (GUI Only)

#### Step 4.1: Open Synology Web Interface
1. Open web browser
2. Navigate to: `https://[NAS_IP_ADDRESS]:5000` or `http://[NAS_IP_ADDRESS]:5000`
3. Login with NAS admin credentials

**Result:** You're in Synology DSM

#### Step 4.2: Access Container Manager
1. In Synology DSM left sidebar, find **Container Manager**
2. Or use the search at top to find "Container"
3. Click to open Container Manager

**Result:** Container Manager interface opens

#### Step 4.3: Container Manager Auto-Detects docker-compose.yml
1. Container Manager automatically scans `/volume1/Docker/Familiez/` folder
2. When it finds `docker-compose.yml`, it will:
   - Display the compose file in the interface
   - Parse all services (mysql, mw, fe, etc.)
   - Allow you to manage via GUI
3. You should see your services listed

**Result:** No terminal needed - GUI manages everything

#### Step 4.4: Verify Configuration in Container Manager
1. Open the compose file details in Container Manager
2. Verify these services are detected:
   - `mysql` - Database container
   - `mw` - Middleware container
   - `fe` - Frontend container (if included)
3. Check that volume paths reference:
   - `/volume1/docker/familiez/FE-build/` for frontend
   - `/volume1/docker/familiez/MW-build/` for middleware
   - `/volume1/docker/familiez/mysql-data/` for database persistence
   - `/volume1/docker/familiez/media/` for user file uploads

#### Step 4.5: Configure File Storage Environment Variables

**Critical:** The production environment uses a different folder name than development!

In Nemo (SFTP to NAS):
1. Navigate to `/volume1/docker/familiez/`
2. Open `.env.prod` file (or create it if missing)
3. Add/verify these storage configuration lines:
   ```bash
   # File Storage Configuration (Production)
   STORAGE_BASE_PATH=/app/storage
   STORAGE_HOST_PATH=/volume1/docker/familiez/media
   ```
4. Save the file

**Explanation:**
- `STORAGE_BASE_PATH` - Path inside the MW container (stays constant)
- `STORAGE_HOST_PATH` - Path on NAS host that mounts to container
- Dev uses `BESTANDEN/`, Prod uses `media/`
- The docker-compose.prod.yml file references these variables

**Result:** Storage paths configured for production

#### Step 4.6: Verify media Folder Exists on NAS
In Nemo (SFTP to NAS):
1. Navigate to `/volume1/docker/familiez/`
2. Check if `media/` folder exists
3. If not, create it: Right-click → **Create Folder** → Name it `media`
4. Verify folder permissions allow write access

**Important:** This folder stores all uploaded files (portraits, documents, etc.)

#### Step 4.7: Update Other Environment Variables (If Needed)
#### Step 4.7: Update Other Environment Variables (If Needed)
In Container Manager, click on the compose file:
1. Look for environment variables section
2. Verify/update database path variables if needed:
   - `MYSQL_DATA_PATH=/volume1/docker/familiez/mysql-data`
   - `MYSQL_INIT_PATH=/volume1/docker/familiez/mysql-init`
3. Ensure all credentials in `.env.prod` match actual values

**Result:** Environment fully configured for production deployment

---

### Phase 5: Deploy via Container Manager (NO Terminal Required)

#### Step 5.1: Start Containers from Compose File
In Synology Container Manager:
1. Navigate to the compose file section
2. Look for a **"Start"** or **"Up"** button (exact wording depends on version)
3. Click to deploy all services
4. Container Manager will:
   - Build any images that need building
   - Pull any images from registry
   - Create and start all containers
   - Set up networking between containers

**Result:** All containers start automatically

#### Step 5.2: Monitor Deployment Progress
In Container Manager:
1. Watch the **Containers** section
2. You should see containers transitioning to **Running** status:
   - `familiez-mysql-prod` - Starts first (healthcheck runs)
   - `familiez-mw-prod` - Starts after database is healthy
   - `familiez-fe-prod` - Starts with middleware
3. Each container shows status indicator (green = running)

**Tip:** If a container stays in "creating" or "restarting", click it to view logs for errors

#### Step 5.3: View Container Logs
In Container Manager:
1. Click on any running container
2. Look for **"Log"** or **"View Logs"** button
3. Check for startup messages:
   - Database: "ready for connections"
   - MW (FastAPI): "Uvicorn running on 0.0.0.0:8000"
   - FE: "Nginx started" (or similar)
4. Red/error messages indicate problems to fix

**Result:** Deployment complete when all containers show green/running

---

### Phase 5.5: Apply Database Schema Changes (If Needed)

**⚠️ Critical:** Only perform these steps if you have database schema changes (new tables, columns, stored procedures, etc.)

#### Step 5.5.1: Backup Production Database First
In Synology DSM:
1. Open **Container Manager**
2. Click on `familiez-mysql-prod` container
3. Click **Terminal** or **Execute** button
4. Run inside container:
   ```bash
   mysqldump -u root -p humans > /var/backups/humans_backup_$(date +%Y%m%d_%H%M%S).sql
   ```
5. Exit terminal
6. In Nemo (SFTP), navigate to the container mount for backups and copy to safe location

**Alternative via phpMyAdmin (if installed):**
1. Open phpMyAdmin in browser
2. Select `humans` database
3. Click **Export** tab
4. Choose **Quick export** → **SQL format**
5. Click **Go** to download backup

**Result:** Database backup created before making changes

#### Step 5.5.2: Identify Schema Changes to Apply
On local machine:
1. Navigate to `/home/frans/Documenten/Dev/Familiez/BE/`
2. Identify new schema files (e.g., `CreateFileTables.sql`)
3. Identify migration files (e.g., `UpdateVersion_2026_03_05_FileManagement.sql`)
4. Note: Schema files create new tables, migration files track releases

**Check what's already in production:**
- Look at existing `be_releases`, `mw_releases`, `fe_releases` tables
- Only apply migrations that haven't been run yet

#### Step 5.5.3: Copy SQL Files to NAS
Using Nemo (SFTP to NAS):
1. Navigate to `/volume1/docker/familiez/`
2. Create folder: `migrations/` (if doesn't exist)
3. Copy schema change files from local `BE/` folder:
   - `CreateFileTables.sql` (or similar new schema files)
   - `UpdateVersion_*.sql` (migration tracking files)
4. Verify files appear on NAS

**Result:** SQL files ready to execute on production database

#### Step 5.5.4: Apply Schema Changes via Container Manager
In Synology Container Manager:
1. Click on `familiez-mysql-prod` container
2. Click **Terminal** or **Execute** button to open container shell
3. Inside container, run:
   ```bash
   mysql -u root -p humans < /docker-entrypoint-initdb.d/CreateFileTables.sql
   ```
   (Enter root password when prompted)
4. Verify output shows "Query OK" messages, no errors

**Alternative: Execute SQL via phpMyAdmin:**
1. Open phpMyAdmin
2. Select `humans` database
3. Go to **SQL** tab
4. Copy contents of `CreateFileTables.sql`
5. Paste and click **Go**
6. Verify "Query executed successfully"

**Result:** New tables/columns created in production database

#### Step 5.5.5: Record Release Information
Still in MySQL container terminal (or phpMyAdmin):
1. Run the migration tracking script:
   ```bash
   mysql -u root -p humans < /docker-entrypoint-initdb.d/UpdateVersion_2026_03_05_FileManagement.sql
   ```
2. This inserts release records into `be_releases`, `mw_releases`, `fe_releases` tables
3. Verify with:
   ```bash
   mysql -u root -p humans -e "SELECT ReleaseNumber, ReleaseDate, Description FROM be_releases ORDER BY ReleaseID DESC LIMIT 3;"
   ```

**Result:** Release history tracked in database

#### Step 5.5.6: Verify Schema Changes
Check that tables exist:
```sql
SHOW TABLES LIKE 'files';
SHOW TABLES LIKE 'person_files';
SHOW TABLES LIKE 'family_files';
```

Check table structure:
```sql
DESCRIBE files;
DESCRIBE person_files;
```

Verify indexes:
```sql
SHOW INDEX FROM files;
```

**Result:** Database schema updated successfully, existing data preserved

#### Important Notes About Database Migrations:

✅ **Safe Operations (No Data Loss):**
- `CREATE TABLE IF NOT EXISTS` - Creates new tables
- `ALTER TABLE ADD COLUMN` - Adds new columns with defaults
- `CREATE INDEX` - Adds performance indexes
- `CREATE PROCEDURE` - Adds/updates stored procedures
- `INSERT INTO *_releases` - Tracks version history

⚠️ **Caution Required:**
- `DROP TABLE` - Deletes tables and all data
- `ALTER TABLE DROP COLUMN` - Removes columns and data
- `TRUNCATE TABLE` - Empties table
- `UPDATE` without WHERE - Modifies all rows

✅ **Best Practice:**
- Always backup before schema changes
- Test migrations on development database first
- Run schema changes before restarting application containers
- Keep migration files organized by date: `UpdateVersion_YYYY_MM_DD_feature.sql`
- Document all changes in release tables

---

### Phase 6: Test Deployment

#### Step 6.1: Test Frontend
1. Open browser
2. Navigate to: `http://[NAS_IP]:5173` (or your configured port)
3. Verify login page appears
4. Check browser console for JavaScript errors (F12)

#### Step 6.2: Test Middleware API
1. Open browser
2. Navigate to: `http://[NAS_IP]:18000/api/health` or `/api/status`
3. Should see API response (JSON)

#### Step 6.3: Test Authentication & File Operations
1. Try logging in with NAS user credentials
2. Verify Synology SSO integration works
3. **Test file upload:**
   - Navigate to a person in the family tree
   - Try uploading a test file (portrait or document)
   - Verify file appears in person's file list
   - Check that file was saved to `/volume1/docker/familiez/media/` on NAS
4. **Test file preview:**
   - Click on uploaded file thumbnail
   - Verify preview popup opens
   - Check that file downloads/displays correctly

---

## Rollback Procedure (If Deployment Fails)

### Quick Rollback (Last 30 minutes)
In Synology Container Manager:
1. Click **"Stop"** on the compose deployment
2. All containers will stop (volumes preserved)
3. In Nemo (SFTP), restore from backup:
   - Navigate to `/volume1/docker/familiez/FE-build/`
   - Delete all current files
   - Copy files from `FE-build_backup_20260306/`
   - Repeat for `MW-build/` folder
4. In Container Manager, click **"Start"** again
5. Containers restart with previous code

**Rollback time:** ~2-5 minutes

### Full Rollback (Keep Database & Files)
1. Stop all containers in Container Manager
2. Restore FE-build and MW-build from backups (as above)
3. Restart containers
4. Database remains untouched (mysql-data volume preserved)
5. User files untouched (`media/` folder preserved)

### Database Rollback (If Data Issue)
**Do NOT use unless absolutely necessary - you'll lose newer data:**
1. In Synology, open **Storage Manager**
2. Find volume `/volume1/docker/familiez/mysql-data`
3. Delete the entire volume
4. Container Manager will recreate from init scripts
5. All data will reset to initial state

**This is destructive - only use if database is corrupted**

---

## File Structure on NAS (After Deployment)

```
/volume1/docker/familiez/
├── FE-build/
│   └── (Frontend build files - dist output)
│       ├── index.html
│       ├── assets/
│       ├── js/
│       ├── css/
│       └── ... (minified production files)
├── MW-build/
│   ├── app/
│   │   ├── main.py
│   │   ├── auth.py
│   │   └── ... (API code)
│   ├── Dockerfile
│   └── requirements.txt
├── mysql-data/ (🔒 LIVE DATABASE - DO NOT TOUCH)
├── mysql-init/ (Schema setup - read-only after init)
├── migrations/ (SQL migration scripts for schema updates)
│   ├── CreateFileTables.sql
│   ├── UpdateVersion_2026_03_05_FileManagement.sql
│   └── ... (other migration files)
├── media/ (User uploaded files - equiv to BESTANDEN in dev)
├── .env.prod (🔒 Credentials - stays on NAS)
├── FE-build_backup_20260306/ (Previous version)
├── MW-build_backup_20260306/ (Previous version)
└── docker-compose.yml (Synology Container Manager reads this)

/volume1/Docker/Familiez/ (Docker app folder)
└── docker-compose.yml (Copied here for Container Manager)
```

---

## Security Notes

✅ **Credentials stay on NAS:**
- `.env.prod` never leaves the NAS
- Manually updated on NAS only
- Never checked into git

✅ **Local machine keeps full source:**
- FE/, MW/, BE/ folders stay on development machine
- No files deleted on local machine
- Ready for future development changes

✅ **Database persistence:**
- `mysql-data/` volume survives container restarts
- Regular backups recommended in DSM Storage Manager
- `media/` folder preserves user uploaded files

---

## Summary

✅ **What this deployment achieves:**
- Updates FE with latest built artifacts (dist/)
- Updates MW with latest source + Dockerfile
- **Applies database schema changes** (new tables, columns, stored procedures)
- **Preserves existing database data** during migrations
- Maintains user files (`media/` folder on NAS)
- Keeps credentials secure (.env.prod stays on NAS)
- NO terminal commands for deployment
- Container Manager GUI handles everything

✅ **Key Deployment Steps:**
1. **Build** FE locally (`npm run build`)
2. **Copy** FE_Build and MW_Build to NAS via Nemo (SFTP)
3. **Copy** docker-compose.yml to `/volume1/Docker/Familiez/`
4. **Backup** database before schema changes
5. **Apply** SQL migration scripts via Container Manager terminal or phpMyAdmin
6. **Deploy** containers via Container Manager GUI
7. **Test** frontend, API, and authentication
- Container Manager GUI handles everything

✅ **Key Changes from Previous Process:**
- Build code locally (FE/dist/ on dev machine)
- Copy to NAS build folders (FE_Build/, MW_Build/)
- Copy docker-compose.yml to /volume1/Docker/Familiez/
- **Backup database before applying schema changes**
- **Run SQL migrations manually for full control**
- Container Manager auto-detects and manages deployment
- No `docker compose` commands needed in terminal
- Rollback is just restoring from backup folders
- **Database content preserved during schema updates**

⚠️ **Important Reminders:**
- FE and MW folders on local dev machine are NEVER deleted
- Only backup/restore the -build folders on NAS
- Database volume (mysql-data) is never touched during deployment
- User files (media folder on NAS) are never touched during deployment
- Dev uses BESTANDEN/, Prod uses media/ - both work via environment variables

---

**For Support:**
- Check container logs in Synology DSM Container Manager
- Verify .env.prod has correct credentials on NAS
- Ensure firewall allows container ports
- Review docker-compose.yml paths match actual NAS structure (/volume1/Docker/Familiez/)

---

## Troubleshooting

#### Issue: Containers Won't Start
**Check Container Manager logs:**
1. In Container Manager, click on a non-running container
2. View the logs for error messages
3. Common causes:
   - Port already in use (another app using 18000 or 3306)
   - Insufficient disk space
   - Volume paths don't exist
   - Docker daemon not running

**Fix:** Stop conflicting containers and restart

#### Issue: Frontend Not Loading
**Check FE_Build folder:**
1. In Nemo, navigate to `/volume1/docker/familiez/FE_Build/`
2. Verify `index.html` exists
3. Verify `assets/`, `js/`, `css/` folders are there
4. If empty, re-copy from local FE/dist/

**Check via browser:**
1. Open browser dev tools (F12)
2. Check Network tab for 404 errors
3. Check Console tab for JavaScript errors

#### Issue: API Returns 500 Errors
**Check middleware logs:**
1. Container Manager → Click `familiez-mw-prod`
2. View logs for startup errors
3. Check for:
   - Database connection failures
   - Missing environment variables
   - Python syntax errors

**Check .env.prod:**
1. Verify database credentials match MW expectations
2. Verify paths in docker-compose.yml:
   - `MW-build/` path correct
   - Volume mounts correct

#### Issue: Database Connection Failed
**Check MySQL container:**
1. Container Manager → Click `familiez-mysql-prod`
2. View logs for MySQL startup messages
3. Verify healthcheck shows "healthy"

**Check credentials:**
1. Nemo: Open `.env.prod`
2. Verify `DB_ROOT_PASSWORD`, `DB_USER`, `DB_PASSWORD` values
3. Restart MySQL container if credentials changed

#### Issue: File Upload Fails
**Check media folder on NAS:**
1. In Nemo, navigate to `/volume1/docker/familiez/media/`
2. Verify folder exists and is writable
3. Check folder permissions (should allow container write access)

**Check MW volume mount:**
1. In Container Manager, inspect MW container details
2. Verify volume mount shows:
   - Host path: `/volume1/docker/familiez/media`
   - Container path: `/app/storage`
3. Restart MW container if paths are wrong

**Check environment variables:**
1. Open `.env.prod` file on NAS
2. Verify these lines exist:
   ```
   STORAGE_BASE_PATH=/app/storage
   STORAGE_HOST_PATH=/volume1/docker/familiez/media
   ```
3. Restart containers after editing .env.prod

#### Issue: Database Migration Failed
**If SQL script produced errors:**
1. Open Container Manager → MySQL container → View logs
2. Look for SQL error messages (syntax errors, missing columns, etc.)
3. Check if table already exists: `SHOW TABLES LIKE 'table_name';`
4. If migration partially ran, **restore from backup** before retrying

**Common migration errors:**
- **Table already exists:** Check if this migration was already run
  ```sql
  SELECT * FROM be_releases WHERE ReleaseNumber = '0.9.0';
  ```
- **Foreign key constraint fails:** Ensure parent tables exist first
- **Syntax error:** Check SQL file for typos or invalid SQL

**Fix:**
1. Restore database from backup (Phase 5.5.1)
2. Fix the SQL script locally
3. Re-copy corrected script to NAS
4. Run corrected script again

#### Issue: Lost Data After Migration
**Critical - Restore immediately:**
1. Stop MySQL container in Container Manager
2. Restore database backup from Phase 5.5.1
3. Investigate what went wrong before retrying
4. Never run `DROP TABLE` or `TRUNCATE` without backup!

---

**End of Deployment Guide**
