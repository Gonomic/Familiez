# Familiez Production Deployment Guide
## GUI-Based Deployment (No Terminal Required)

**Last Updated:** 6 maart 2026  
**Current Versions:**
- Frontend (FE): 0.0.1 (React/Vite)
- Middleware (MW): FastAPI (0.104.1)
- Mobile (MOB): 1.0.0 (Expo React Native)
- Backend: MariaDB (SQL scripts)

---

## Architecture Overview

The Familiez stack consists of:

```
Familiez (Docker Compose Stack)
├── MySQL Container (MariaDB 10.6) - Database: humans
├── Middleware Container (FastAPI) - Port 18000
├── Frontend Container (Vite) - Served via nginx
└── File Storage - User uploaded files
    ├── Dev: BESTANDEN/ folder
    └── Prod: media/ folder (on NAS)
```

**⚠️ Important Storage Difference:**
- **Local Development:** Uses `BESTANDEN/` folder
- **NAS Production:** Uses `media/` folder
- Both mount to `/app/storage` inside the MW container
- Environment variables handle the path difference

**Total Size:** ~1GB (FE 333MB, MW 182MB, BE 11MB, MOB excluded from prod)

---

## Current Local Status (Development Machine)

### ✅ What You Have:
- **FE (Frontend):** Complete React/Vite application with components
- **MW (Middleware):** FastAPI with authentication, file handling, LDAP/SSO integration
- **BE (Backend):** 300+ SQL initialization scripts and stored procedures
- **Configuration:** docker-compose.yml and docker-compose.prod.yml ready
- **Environment:** .env with credentials (stays local, not synced to git)

### ⚠️ Key Files to Know:
- `docker-compose.prod.yml` - Production deployment config
- `FE/.env.production` - Frontend production settings
- `.env` - Local credentials (NEVER push to git)
- `BE/init/` - SQL initialization scripts
- `BESTANDEN/` - User file storage on dev machine (excluded from version control)
- `media/` - User file storage on NAS production (must be created on NAS)

---

## Pre-Deployment Checklist

- [ ] Verify NAS is online and accessible
- [ ] Know NAS SSH password (for emergency rollback only)
- [ ] Backup current production database on NAS
- [ ] Confirm NAS has 2GB free space
- [ ] Have production .env credentials ready
- [ ] Schedule deployment during low-usage time

---

## Deployment Overview - Main Steps

This is a high-level overview of the deployment process. Detailed instructions follow in each phase.

### Step 1: Prepare Code
- Build frontend on local machine: `cd FE && npm run build`
- Result: FE/dist/ folder with production build

### Step 2: Connect to NAS
- Open Nemo file manager and connect via SFTP to NAS
- Navigate to `/volume1/docker/familiez/`

### Step 3: Backup Current Version
- Copy existing `FE-build/` → `FE-build_backup_YYYYMMDD/`
- Copy existing `MW-build/` → `MW-build_backup_YYYYMMDD/`

### Step 4: Transfer New Code
- Clear contents of `FE-build/` and `MW-build/` on NAS
- Copy local `FE/dist/*` → NAS `FE-build/`
- Copy local `MW/` files → NAS `MW-build/`
- Copy `docker-compose.prod.yml` → NAS `/volume1/Docker/Familiez/docker-compose.yml`

### Step 5: Configure Environment
- Edit `.env.prod` on NAS
- Add storage configuration variables
- Verify `media/` folder exists (create if needed)

### Step 6: Database Migration (If Schema Changes)
- Backup production database
- Copy SQL migration files to NAS `migrations/` folder
- Run schema changes via Container Manager terminal or phpMyAdmin
- Verify tables/columns created successfully

### Step 7: Deploy Containers
- Open Synology Container Manager (web GUI)
- Click "Start" or "Up" on compose file
- Container Manager builds and starts all containers automatically

### Step 8: Test Deployment
- Test frontend loads (browser)
- Test API responds
- Test login with SSO
- Test file upload and preview

### Step 9: Monitor & Verify
- Check container logs in Container Manager
- Verify no errors
- Confirm all services running

**Total Time:** ~15-30 minutes (depending on database migrations)

---

## DEPLOYMENT PROCESS: GUI + FILE MANAGER ONLY

### Phase 1: Prepare Updated Code on Local Machine (Nemo File Manager)

#### Step 1.1: Build Frontend for Production
Open a terminal ONLY for this build step (unavoidable):
```bash
cd /home/frans/Documenten/Dev/Familiez/FE
npm run build
```
This creates the `dist/` folder with optimized production files.

**Result:** FE/dist/ folder ready for deployment

#### Step 1.2: Open Nemo File Manager - TWO Windows
1. Open **Nemo** file manager (Files application) **TWICE**
2. Window A: Navigate to `/home/frans/Documenten/Dev/Familiez/`
3. Window B: Keep empty (for NAS connection in Phase 2)

#### Step 1.3: Select Code for Transfer
In Nemo Window A:
1. **Prepare for transfer:**
   - ✔ `MW/` - Middleware code folder (stays on local machine, will copy to NAS)
   - ✔ `FE/dist/` - Built frontend output (from Step 1.1)
   - ✔ `BE/init/` - Database initialization scripts
   - ✔ `docker-compose.prod.yml` - Production config file

2. **Do NOT transfer:**
   - ✘ `.env` or any environment files
   - ✘ `BESTANDEN/` folder - User files stay on NAS in `media/` folder
   - ✘ `MOB/` - Mobile app (separate deployment)
   - ✘ `.git/` and `.gitignore`

**Note:** The `BESTANDEN/` folder on dev machine corresponds to `media/` folder on NAS

**Important:** These folders remain on your local machine - you are COPYING them, not moving them

---

### Phase 2: Connect NAS via SFTP (Nemo File Manager)

#### Step 2.1: Open NAS Connection in Nemo
1. In Nemo, click **File** → **Connect to Server**
2. Select **SSH (SFTP)**
3. Enter NAS details:
   - **Server Address:** `[NAS_IP_ADDRESS]` (e.g., `192.168.1.10`)
   - **Username:** Your NAS SSH user (e.g., `admin`)
   - **Port:** `22` (default)
   - **Folder:** Leave blank (will go to home)
4. Click **Connect**
5. Enter password when prompted

**Result:** You're now browsing the NAS file system in Nemo (Window B)

#### Step 2.2: Navigate to Production Directory on NAS
In Nemo Window B:
1. Navigate to: `volume1` → `docker` → `familiez`
2. You should see:
   - `FE-build/` - Old frontend builds
   - `MW-build/` - Old middleware builds
   - `docker-compose.prod.yml` - Old config
   - `.env.prod` - Production credentials
   - `mysql-data/` - Live database
   - `media/` - User uploaded files (equivalent to BESTANDEN in dev)

**Important:** Leave `mysql-data/` and `media/` untouched!

#### Step 2.3: Backup Current Build Folders on NAS
In Nemo Window B:
1. Right-click on `FE-build/` → **Copy**
2. Right-click → **Paste as** → Name it `FE-build_backup_20260306/`
3. Right-click on `MW-build/` → **Copy**
4. Right-click → **Paste as** → Name it `MW-build_backup_20260306/`
5. Wait for backup operations to complete

**Result:** Backup folders created in /volume1/docker/familiez/

---

### Phase 3: Transfer Updated Code to NAS (Drag & Drop)

#### Step 3.1: Clear Old Build Folders on NAS
In Nemo Window B (NAS):
1. Navigate to `volume1/docker/familiez/FE-build/`
2. Select all files inside (Ctrl+A)
3. Press **Delete** (or drag to trash)
4. Navigate back to `volume1/docker/familiez/MW-build/`
5. Select all files inside (Ctrl+A)
6. Press **Delete**
7. Wait for deletions to complete

**Result:** Old builds removed, space ready for new code

#### Step 3.2: Transfer FE Build to NAS
1. In Nemo Window A (Local Machine): Navigate to `FE/dist/`
2. Select ALL files inside `dist/` (Ctrl+A)
3. **Copy** (Ctrl+C)
4. Switch to Nemo Window B (NAS): Navigate to `/volume1/docker/familiez/FE-build/`
5. **Paste** (Ctrl+V) - wait for copy to complete
6. Verify files appear on NAS

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
