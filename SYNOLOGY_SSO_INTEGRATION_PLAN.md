# Synology SSO Integration Plan - Numbered Steps
**Created: 21 February 2026**
**Status: ✅ PRODUCTION DEPLOYMENT COMPLETE (2 maart 2026, 23:30)**

---

## ✅ DEPLOYMENT COMPLETED (2 maart 2026, 23:30)

**Session work completed:**
- ✅ Hostname correction identified: `api.dekknet.com` (not `api.familiez.dekknet.com`)
- ✅ Env files updated locally (FE/.env.production, MW/.env.prod)
- ✅ Env files copied to NAS via Nemo
- ✅ Container Manager rebuild completed (FE + MW images rebuilt with correct env)
- ✅ MySQL data preserved during rebuild
- ✅ FastAPI docs accessible: `https://api.dekknet.com/docs` → 200 OK
- ✅ OIDC discovery endpoint: `https://api.dekknet.com/auth/discovery` → 200 OK
- ✅ FE loads successfully: `https://familiez.dekknet.com` → 200 OK
- ✅ SSO login flow working end-to-end
- ✅ OAuth callback successful
- ✅ Token exchange working (FE → MW /auth/callback)
- ✅ Access token stored in localStorage
- ✅ Authenticated API calls working (protected endpoints return data)

**All deployment steps completed:**
1. ✅ Env files copied to NAS (via Nemo)
2. ✅ Container rebuild via Container Manager GUI
3. ✅ API endpoint verification
4. ✅ Reverse proxy configured (familiez.dekknet.com + api.dekknet.com)
5. ✅ SSL certificates bound correctly
6. ✅ End-to-end SSO login flow tested and working

---

## PHASE 1: LOCAL DEVELOPMENT & TESTING

### Setup & Configuration

**1.1** Configure Synology SSO Application on your NAS
- **DSM 7.2.2 Correct Path:** Open **SSO Server** app → **Service** tab
- Available tabs: Service | Toepassing (Applications) | Logboek (Logs)
- In **Service** tab, enable OpenID Connect or OAuth 2.0 services
- Note the **"well known url"** field - this is your OpenID Discovery endpoint
  - Example: `https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`
  - **DO NOT CHANGE THIS** - it's correct as-is
- Then go to **Toepassing** tab to create new OAuth 2.0 Application
- Create OAuth 2.0 Application with Client ID `familiez-local-dev`
- Generate Client Secret (save securely)
- Add Redirect URI: `http://sso.dekknet.com:5173/auth/callback` (Synology rejects localhost; HTTP accepted)
- Save this Discovery URL endpoint for middleware use: `https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`
- **Status:** ✅ Finished

**1.2** Update MW requirements.txt with dependencies
- Add: `PyJWT`, `requests`, `python-dotenv`
- Troubleshooting: if VS Code shows missing imports, ensure the MW venv has `pip` and reinstall requirements
- **Status:** ✅ Finished

**1.3** Create authentication module in MW
- File: `MW/auth.py` - Token verification functions
- Implement `verify_sso_token()` function
- Implement `require_sso_auth()` decorator
- **Status:** ✅ Finished

**1.4** Modify MW/main.py
- Import auth module
- Add token verification to protected endpoints
- Add CORS configuration for frontend
- **Status:** ✅ Finished

**1.5** Create authentication service in FE
- File: `FE/src/services/authService.js`
- Functions: `initiateSSOLogin()`, `exchangeCodeForToken()`, `setAuthHeader()`
- **Status:** ✅ Finished

**1.6** Create AuthCallback page in FE
- File: `FE/src/pages/AuthCallback.jsx`
- Handle redirect from Synology SSO
- Exchange authorization code for token
- **Status:** ✅ Finished

**1.7** Update FE routing
- Add route: `/auth/callback` → AuthCallback component
- Add protected routes that require valid token
- Add login button to main page/navigation
- **Status:** ✅ Finished

**1.8** Create environment configuration files
- File: `FE/.env.local` with Synology Auth URL, Client ID, Redirect URI
- File: `MW/.env` with JWKS URL, Client ID, Client Secret
- **Status:** ✅ Finished

### Docker Setup

**1.9** Create docker-compose.yml for local testing
- Frontend service (port 5173)
- Middleware service (port 5000)
- Database service (PostgreSQL)
- Network: `familiez`
- **Status:** ✅ Finished

**1.10** Update Dockerfiles if needed
- FE: Ensure Vite server exposes port 5173
- MW: Ensure Flask app exposes port 5000
- Both: Use environment variables from .env files
- **Status:** ✅ Finished

### Testing

**1.11** Test SSO flow locally
- Start docker-compose
- Navigate to frontend
- Click login → redirected to Synology
- Authenticate with Synology user
- Callback received with token
- Token stored and used in API calls
- **Status:** ✅ Finished

**1.12** Test middleware validation
- Call protected API endpoint with valid token → Success (200)
- Call protected API endpoint without token → Fail (401)
- Call protected API endpoint with invalid token → Fail (401)
- **Status:** ✅ Finished

**1.13** Test multiple users
- Log out
- Log in as different Synology user
- Verify different user data/permissions
- **Status:** ✅ Finished

---

## PHASE 2: SYNOLOGY NAS DEPLOYMENT (DEKKNET.COM)

### Scope for this phase
- Target deployment: `FE` + `MW` + `MariaDB` on Synology Container Manager
- Identity: Synology SSO + Synology LDAP (already used in MW)
- Domain/DDNS: `familiez.dekknet.com` (FE) + `api.familiez.dekknet.com` (API)
- API runtime port (internal): `8000`
- DB engine: MariaDB 10.6 (not PostgreSQL)
- Critical requirement: database files must stay synchronized with a NAS folder using bind mounts

### Pre-Deployment Setup

**2.1** Create/update Synology SSO production app
- DSM → **SSO Server** → **Toepassing (Applications)**
- Create app `familiez-prod` (or update current app)
- Add redirect URI: `https://familiez.dekknet.com/auth/callback`
- Optional DDNS fallback: `https://<your-ddns-hostname>/auth/callback`
- Store client secret in NAS secrets file (not in git)
- Confirmed app id: `134a695b24e74328968844f7e4c1208d`
- Confirmed redirect URI: `https://familiez.dekknet.com/auth/callback`
- **Status:** ✅ Done

**2.2** Verify Synology prerequisites
- Container Manager installed and running
- DNS/DDNS for `dekknet.com` points to NAS public IP
- SSL certificate valid for `dekknet.com`
- NAS folders available under `/volume1/docker/familiez`
- **Status:** ✅ Done

**2.3** Create NAS folder structure (for persistent sync)
- Create folders:
  - `/volume1/docker/familiez/compose`
  - `/volume1/docker/familiez/env`
  - `/volume1/docker/familiez/mysql-data`
  - `/volume1/docker/familiez/mysql-backup`
  - `/volume1/docker/familiez/logs`
- MariaDB data must map to `/volume1/docker/familiez/mysql-data:/var/lib/mysql`
- **Status:** ✅ Done

**2.4** Create FE production environment
- File: `FE/.env.production`
- Required keys:
  - `VITE_SYNOLOGY_AUTH_URL=https://sso.dekknet.com`
  - `VITE_CLIENT_ID=134a695b24e74328968844f7e4c1208d`
  - `VITE_REDIRECT_URI=https://familiez.dekknet.com/auth/callback`
  - `VITE_SYNOLOGY_DISCOVERY_URL=https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`
  - `VITE_API_BASE=https://api.dekknet.com` ✅ (corrected from api.familiez.dekknet.com)
- **Status:** ✅ Done

**2.5** Create MW production environment
- File: `MW/.env.prod` (template in git), real secrets on NAS only
- Required keys:
  - `SYNOLOGY_OIDC_DISCOVERY_URL=https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`
  - `SYNOLOGY_CLIENT_ID=134a695b24e74328968844f7e4c1208d`
  - `SYNOLOGY_CLIENT_SECRET=UET32KPWSPOLtMOr8HXK2LcUaryXfd4i` ✅
  - `SYNOLOGY_REDIRECT_URI=https://familiez.dekknet.com/auth/callback`
  - `ALLOWED_ORIGINS=https://familiez.dekknet.com,https://www.familiez.dekknet.com,https://api.dekknet.com`
  - `SYNOLOGY_OIDC_VERIFY_SSL=true`
  - LDAP variables (`SYNOLOGY_LDAP_*`)
  - `DATABASE_URL=mysql+pymysql://HumansService:v_|ZOeI2~p:dfF%X~Dx@mysql:3306/humans`
- **Status:** ✅ Done

### Build & Package

**2.6** Build frontend production image
- From `FE`: `docker build -t familiez-fe:prod -f dockerfile .`
- Uses nginx static serving (already present)
- **Status:** ✅ Done

**2.7** Build middleware production image
- From `MW`: `docker build -t familiez-mw:prod .`
- Note: current `start.sh` runs `--reload` when `DEBUG!=1`; set `DEBUG=0` and update runtime if needed
- **Status:** ✅ Done

**2.8** Prepare database container with automatic initialization
- Use `mariadb:10.6`
- Bind mount `/volume1/docker/familiez/mysql-data:/var/lib/mysql` (persistent data)
- Bind mount `/volume1/docker/familiez/mysql-init:/docker-entrypoint-initdb.d:ro` (init scripts, read-only)
- SQL scripts in `BE/init/` folder (01-schema.sql, 02-*.sql procedures/functions, 03-releases-data.sql)
- MariaDB automatically executes scripts in alphabetical order on first start (only when data folder is empty)
- Copy `BE/init/` folder contents to `/volume1/docker/familiez/mysql-init` on NAS via File Station
- **Status:** ✅ Done

**2.8a** Copy database init scripts to NAS
- Use File Station or Nemo to copy all files from `BE/init/` to `/volume1/docker/familiez/mysql-init/`
- Verify read permissions (should be owned by root or user 0, readable by all)
- Total: 1 schema file + 60+ stored procedure/function files + 1 releases data file
- **Status:** ✅ Done

### Deployment on Synology

**2.9** Create production compose on NAS
- File: `/volume1/docker/familiez/docker-compose.yml` (project root - Container Manager vereist)
- Services: `fe`, `mw`, `mysql`
- Internal Docker network only
- MariaDB uses bind mount to NAS path (step 2.3)
- Option B: keep `build:` enabled and use NAS build contexts:
  - `/volume1/docker/familiez/MW-build`
  - `/volume1/docker/familiez/FE-build`
- **Status:** ✅ Done

**2.9a** Create clean build folders on NAS (Option B)
- Create folders:
  - `/volume1/docker/familiez/MW-build`
  - `/volume1/docker/familiez/FE-build`
- Copy only required production build files (avoid dev clutter like `.git`, `node_modules`, `.venv`, `__pycache__`)
- `MW-build` required files:
  - `Dockerfile`, `requirements.txt`, `start.sh`, `main.py`, `auth.py`
- `FE-build` required files:
  - `dockerfile`, `nginx.conf`, `package.json`, `package-lock.json`, `vite.config.js`, `index.html`, `.env.production`, `public/`, `src/`
- **Status:** ✅ Done

**2.10** Create production env file on NAS
- File: `/volume1/docker/familiez/.env` (project root - naast docker-compose.yml, Container Manager vereist)
- Original location also kept: `/volume1/docker/familiez/env/.env.prod` (backup)
- Restrict permissions: `chmod 600`
- Never commit this file
- **Status:** ✅ Done

**2.11** Deploy stack on NAS with updated env files (hostname migration)
- ✅ Env files copied to NAS:
  - `FE/.env.production` → `/volume1/docker/familiez/FE-build/.env.production`
  - `MW/.env.prod` → `/volume1/docker/familiez/.env`
- ✅ Rebuild completed via Container Manager GUI:
  - Project `familiez-prod` stopped and deleted (volumes preserved!)
  - Project recreated with `--build` enabled
  - FE + MW images rebuilt successfully with new env vars
  - MySQL data preserved (3 containers running)
  - Build duration: ~5 minutes
- ✅ Validation completed:
  - All 3 containers running: familiez-fe-prod, familiez-mw-prod, familiez-mysql-prod
  - `https://api.dekknet.com/docs` → FastAPI swagger docs loaded ✅
  - `https://api.dekknet.com/auth/discovery` → OIDC discovery JSON ✅
  - MW logs: "Application startup complete" visible, no errors
- **Status:** ✅ Done - DEPLOYMENT SUCCESSFUL

### Reverse Proxy & Routing

**2.12** Configure reverse proxy for FE
- Synology Control Panel → Login Portal / Reverse Proxy
- Source: `https://familiez.dekknet.com:443`
- Destination: `http://localhost:18080`
- **Status:** ✅ Done

**2.13** Configure reverse proxy for API
- Source: `https://api.dekknet.com:443`
- Destination: `http://localhost:18000`
- Use subdomain routing (DSM build without path-based source matching)
- **Status:** ✅ Done

### SSL & Validation

**2.14** Validate SSL/TLS and OIDC endpoints
- ✅ Cert chain verified for `familiez.dekknet.com` and `api.dekknet.com`
- ✅ OIDC discovery endpoint `https://sso.dekknet.com/webman/sso/.well-known/openid-configuration` verified
- ✅ SSL termination working (reverse proxy handling HTTPS)
- **Status:** ✅ Done

**2.15** End-to-end production test
- ✅ Login via Synology SSO from `https://familiez.dekknet.com` - **SUCCESS**
- ✅ FE redirects user to `https://sso.dekknet.com` for authentication
- ✅ User logs in with Synology credentials
- ✅ Callback to `https://familiez.dekknet.com/auth/callback` received - **SUCCESS**
- ✅ `FE -> MW /auth/callback` token exchange succeeds
- ✅ Access token stored in localStorage
- ✅ Protected API endpoints return 200 with bearer token via `https://api.dekknet.com`
- ✅ FE app loads personalized content after login
- **Status:** ✅ Done - FULL SSO FLOW WORKING

---

## PHASE 3: OPERATIONS & DATA SAFETY

**3.1** Container health monitoring
- Monitor `docker ps`, logs, restart counts
- **Status:** ☐ Not Started

**3.2** Credential rotation process
- Rotate `SYNOLOGY_CLIENT_SECRET` + DB credentials periodically
- Restart affected services after update
- **Status:** ☐ Not Started

**3.3** Database backup jobs to NAS folder
- Daily dump to `/volume1/docker/familiez/mysql-backup`
- Keep retention policy (e.g., 14/30 days)
- **Status:** ☐ Not Started

**3.4** Data sync verification (NAS folder ↔ container)
- Weekly check: DB writes reflected in `/volume1/docker/familiez/mysql-data`
- Verify permissions/ownership survive reboot/updates
- **Status:** ☐ Not Started

**3.5** Disaster recovery drill
- Restore latest dump to test DB container
- Validate app startup + login + key queries
- **Status:** ☐ Not Started

---

## PROGRESS TRACKING

### How to Use This File
1. When you complete a step, change `☐ Not Started` to `✅ Done`
2. When you start a step, change `☐ Not Started` to `⏳ In Progress`
3. When reporting issues, reference the step number (e.g., "Problem with 1.5")
4. When asking for help, reference the step number (e.g., "Help with 1.9")

### Example Update Format
```
Done with 1.2
Help with 1.3
Problem with 2.5 - getting error X
```

### Quick Stats
- Total Steps: 33
- Phase 1 (Local Development): 13 steps
- Phase 2 (NAS Deployment): 15 steps
- Phase 3 (Maintenance): 5 steps

---

## KEY SECRETS TO KEEP SECURE
⚠️ **NEVER COMMIT THESE TO GIT:**
- SYNOLOGY_CLIENT_SECRET
- Database passwords
- API keys
- `.env` files (except `.env.example`)

---

## IMPORTANT NOTES

### Synology Domain & DDNS
- Your domain: `DEKKNET.COM` (`dekknet.com`)
- DDNS is configured on your NAS
- SSL certificates should be valid for this domain
- If using self-signed certs, you may need `requests` with `verify=False`

### Database Persistence Requirement
- Use bind mount (not anonymous volume) for MariaDB data on Synology
- Required mapping: `/volume1/docker/familiez/mysql-data:/var/lib/mysql`
- Keep scheduled SQL dumps in `/volume1/docker/familiez/mysql-backup`

### Architecture Reminder
```
User → React UI (FE) → Synology SSO Login
       ↓ (with token)
       Middleware (MW) → Validates token → Calls Backend
```

### Local Development Tips
- Use `localhost:5173` for development (Vite default)
- Add `127.0.0.1 dekknet.com` to `/etc/hosts` for testing with actual domain
- Docker containers communicate via service names (e.g., `middleware:5000`)

### Production Considerations
- All traffic should be HTTPS
- Reverse proxy handles SSL termination
- Container IPs are internal; use docker service names
- Ensure proper network isolation

---

## FUTURE OPTIMIZATION TODO's

### Docker Image Optimization
- **TODO:** Remove `ldap-utils` package from MW/Dockerfile
  - Currently installed for troubleshooting purposes (`ldapsearch`, `ldapmodify`)
  - Not required for production: `ldap3` Python library is pure Python and doesn't need system LDAP tools
  - Remove line: `ldap-utils \` from apt-get install section
  - Benefit: Smaller image size, faster builds
  - Location: `MW/Dockerfile` line 7-8

### Central Registry Workflow (Later Option)
- **TODO (later):** Move to central Docker registry workflow (`build -> push -> pull on Synology`)
  - Use immutable version tags (for example date/commit tags) plus optional `:prod`
  - Keep Synology as runtime-only host (no source code required on NAS)
  - Benefits: simple rollback, reproducible releases, cleaner NAS
  - Tradeoffs: registry credentials/management and extra CI or release steps

---

**Last Updated:** 1 March 2026
**Next Review:** Start with step 2.1 and 2.2
