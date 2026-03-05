# Familiez Production Deployment Guide

**Last Updated:** 5 maart 2026  
**Current Versions:**
- FE: 0.9.2 (File preview popup with close button)
- MW: 0.9.1 (Token query parameter fallback)

---

## Overview

This guide provides step-by-step instructions for deploying Familiez changes to production on Synology NAS.

### Changes in This Release

#### FE 0.9.2 - File Preview Popup
- Authenticated blob-based file preview in popup window
- Popup toolbar with close button and filename
- Fixed popup blocking issue (synchronous window.open)
- MIME type detection and fallback
- Multi-format support (text, images, etc.)

#### MW 0.9.1 - Token Query Parameter Fallback
- Accept `?token=JWT` for `/api/files/*` GET requests
- Enable browser popup file access without Authorization header
- Both Bearer header and query param authentication supported

#### DB - Release Information
- Release tracking tables updated with new versions
- Change descriptions logged for audit trail

---

## Pre-Deployment Checklist

- [ ] Backup current production database
- [ ] Verify Synology SSH access and credentials
- [ ] Confirm NAS disk space available (at least 2GB free)
- [ ] Schedule maintenance window (if needed)
- [ ] Notify users of any planned downtime
- [ ] Have rollback plan ready (see Section 8)

---

## Step 1: Connect to Synology

```bash
ssh [synology_user]@[synology_ip]
# Enter password when prompted
```

**Expected:** SSH shell access to Synology

---

## Step 2: Backup Current Production Database

```bash
cd /volume1/docker/familiez
docker compose exec -T mysql mysqldump -u root -p[root_password] humans > /volume1/backups/humans_backup_$(date +%Y%m%d_%H%M%S).sql
```

**Expected:** SQL dump file created in `/volume1/backups/`

---

## Step 3: Pull Latest Code from GitHub

### Frontend (FE)

```bash
cd /volume1/docker/familiez/FE
git fetch origin
git checkout main
git pull origin main
```

**Expected:** FE code updated to commit 04d381f

### Middleware (MW)

```bash
cd /volume1/docker/familiez/MW
git fetch origin
git checkout main
git pull origin main
```

**Expected:** MW code updated to commit 5e89cbc

---

## Step 4: Update Database - Release Tables

Execute the following SQL on the production database:

```sql
-- Insert FE 0.9.2 Release
INSERT INTO fe_releases (ReleaseNumber, ReleaseDate, Description) 
VALUES ('0.9.2', NOW(), 'File preview popup with close button and authentication');

SET @fe_release_id = LAST_INSERT_ID();

INSERT INTO fe_release_changes (ReleaseID, ChangeDescription, ChangeType) VALUES
  (@fe_release_id, 'Implement authenticated blob-based file preview in popup window', 'Feature'),
  (@fe_release_id, 'Add toolbar with close button and filename display in preview popup', 'Feature'),
  (@fe_release_id, 'Fix popup blocking issue using synchronous window.open() in user action context', 'Bugfix'),
  (@fe_release_id, 'Add MIME type detection and fallback for files without extension', 'Enhancement'),
  (@fe_release_id, 'Proper blob URL revocation after 60 seconds to prevent memory leaks', 'Enhancement'),
  (@fe_release_id, 'Support for text, images, and multiple file types in preview', 'Feature');

-- Insert MW 0.9.1 Release
INSERT INTO mw_releases (ReleaseNumber, ReleaseDate, Description) 
VALUES ('0.9.1', NOW(), 'Token query parameter fallback for authenticated file endpoints');

SET @mw_release_id = LAST_INSERT_ID();

INSERT INTO mw_release_changes (ReleaseID, ChangeDescription, ChangeType) VALUES
  (@mw_release_id, 'Accept ?token=JWT as fallback for Authorization header on /api/files/* GET requests', 'Feature'),
  (@mw_release_id, 'Enable browser popup windows to access protected file endpoints', 'Feature'),
  (@mw_release_id, 'Support both Bearer token header and query parameter authentication', 'Enhancement'),
  (@mw_release_id, 'Improve browser compatibility for file preview functionality', 'Enhancement');

-- Verify insertion
SELECT ReleaseNumber, ReleaseDate FROM fe_releases ORDER BY ReleaseID DESC LIMIT 1;
SELECT ReleaseNumber, ReleaseDate FROM mw_releases ORDER BY ReleaseID DESC LIMIT 1;
```

**Execute via:**

```bash
cd /volume1/docker/familiez
docker compose exec -T mysql mysql -u root -p[root_password] humans << 'EOF'
[paste SQL above]
EOF
```

**Expected:** 2 new release entries in each table

---

## Step 5: Rebuild Docker Images

### Rebuild Middleware Container

```bash
cd /volume1/docker/familiez/MW
docker compose build mw
```

**Expected:** New image built with latest code

### Rebuild Frontend Container

```bash
cd /volume1/docker/familiez/FE
docker compose build fe
```

**Expected:** New image built with latest code

---

## Step 6: Stop and Remove Old Containers

```bash
cd /volume1/docker/familiez
docker compose down
```

**Expected:** All Familiez containers stopped and removed

---

## Step 7: Start Updated Containers

```bash
cd /volume1/docker/familiez
docker compose up -d
```

**Expected:** All containers running with new images

---

## Step 8: Verify Deployment

### Check Container Health

```bash
docker compose ps
```

**Expected:** All containers running (status: "Up")

### Verify Database

```bash
docker compose exec -T mysql mysql -u root -p[root_password] humans -e "SELECT ReleaseNumber FROM fe_releases ORDER BY ReleaseID DESC LIMIT 1;"
```

**Expected Output:** `0.9.2`

### Test API Endpoints

```bash
# Test MW is running
curl -s https://[synology_ip]/api/health | jq

# Test FE is accessible
curl -s https://[synology_ip]/ | head -20
```

**Expected:** API responds with health status, FE frontend loads

### Test File Preview Feature

1. Log into Familiez web app
2. Navigate to a person with files
3. Click on a text file → verify popup opens with preview
4. Click on an image file → verify image displays in popup
5. Click "Sluiten" button → verify popup closes

**Expected:** File preview works correctly for multiple file types

---

## Step 9: Update Nginx Configuration (if needed)

If you're using Nginx as reverse proxy on Synology:

```bash
# Edit nginx config if ALLOWED_ORIGINS needs updating
sudo nano /etc/nginx/conf.d/familiez.conf

# Reload nginx
sudo systemctl reload nginx
```

**Note:** Only needed if domain/IP access changed

---

## Step 10: Monitor Logs

Watch for any errors in the first hour:

```bash
docker compose logs -f mw
docker compose logs -f fe
docker compose logs -f mysql
```

**Expected:** No ERROR level messages (WARNINGs are OK)

---

## Rollback Procedure (If Issues Occur)

### Stop Current Deployment

```bash
cd /volume1/docker/familiez
docker compose down
```

### Restore Database Backup

```bash
docker compose up -d mysql
docker compose exec -T mysql mysql -u root -p[root_password] humans < /volume1/backups/humans_backup_[timestamp].sql
```

### Revert Git Commits

```bash
cd /volume1/docker/familiez/FE && git checkout [previous_commit]
cd /volume1/docker/familiez/MW && git checkout [previous_commit]
```

### Rebuild and Restart

```bash
cd /volume1/docker/familiez
docker compose build
docker compose up -d
```

---

## Post-Deployment Tasks

- [ ] Monitor application for 2-4 hours
- [ ] Check user feedback in first 24 hours
- [ ] Verify file uploads still work correctly
- [ ] Test auth with SSO/LDAP
- [ ] Confirm release notes visible in app settings
- [ ] Update change management system/wiki

---

## Support & Troubleshooting

### File Preview Not Working

**Issue:** Popup opens but is empty or shows error

**Solution:**
1. Check MW logs: `docker compose logs mw | grep -i error`
2. Verify `?token=` query param is being sent
3. Check ALLOWED_ORIGINS in MW environment variables
4. Restart MW: `docker compose restart mw`

### Database Connection Failed

**Issue:** MW can't connect to database

**Solution:**
1. Verify MySQL is healthy: `docker compose ps` (should show healthy)
2. Check credentials in `.env` match `docker-compose.yml`
3. Restart MySQL: `docker compose restart mysql`
4. Review DB logs: `docker compose logs mysql | tail -50`

### Frontend Not Loading

**Issue:** FE returns 404 or blank page

**Solution:**
1. Check FE build logs: `docker compose logs fe`
2. Verify Nginx/reverse proxy configuration
3. Clear browser cache (Ctrl+F5)
4. Rebuild FE: `docker compose build fe && docker compose up -d fe`

---

## Version History

| Version | Date | Features |
|---------|------|----------|
| 0.9.2 | 2026-03-05 | File preview popup, close button, MIME detection |
| 0.9.1 | 2026-03-05 | Token query param fallback for file endpoints |
| 0.9.0 | 2026-03-05 | Initial file management features |

---

## Next Release Planning

For **next deployment**, follow this same guide but update:
1. Step 4 with new release version and changes
2. Section "Version History" with new version
3. This deployment guide if new steps are needed

---

## Contact & Questions

- **FE Issues:** Check `docker compose logs fe`
- **MW Issues:** Check `docker compose logs mw`
- **DB Issues:** Check `docker compose logs mysql`
- **SSH Access:** Verify router port forwarding to Synology SSH port

---

**End of Deployment Guide**
