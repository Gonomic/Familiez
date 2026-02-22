# Synology SSO Integration Plan - Numbered Steps
**Created: 21 February 2026**
**Status: Planning Phase**

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

## PHASE 2: SYNOLOGY NAS DEPLOYMENT

### Pre-Deployment Setup

**2.1** Update Synology SSO Application for production
- Go to Control Panel → Domain/LDAP → SSO Server
- Create new OAuth 2.0 Application: `familiez-prod` OR update existing
- Add Redirect URI: `https://dekknet.com/auth/callback`
- Update Client Secret in secure location
- **Status:** ☐ Not Started

**2.2** Verify Synology prerequisites
- Docker is installed on NAS
- Sufficient storage available (`/volume1/` has space)
- Domain (dekknet.com) resolves correctly via DDNS
- SSL certificate is valid (or self-signed works)
- **Status:** ☐ Not Started

**2.3** Update FE environment for production
- File: `FE/.env.production`
- Set VITE_SYNOLOGY_AUTH_URL to production Synology domain
- Set VITE_CLIENT_ID to `familiez-prod`
- Set VITE_REDIRECT_URI to `https://dekknet.com/auth/callback`
- Set VITE_API_BASE to `https://dekknet.com/api`
- **Status:** ☐ Not Started

**2.4** Update MW environment for production
- File: `MW/.env.prod`
- Set SYNOLOGY_JWKS_URL to production value
- Set SYNOLOGY_CLIENT_ID to `familiez-prod`
- Set SYNOLOGY_CLIENT_SECRET to production secret
- Set DATABASE_URL for your NAS database
- **Status:** ☐ Not Started

### Building Docker Images

**2.5** Build frontend Docker image for production
- From FE folder: `docker build -t familiez-frontend:prod -f dockerfile .`
- Tag appropriately for NAS registry if using
- **Status:** ☐ Not Started

**2.6** Build middleware Docker image for production
- From MW folder: `docker build -t familiez-middleware:prod .`
- Include all dependencies from requirements.txt
- **Status:** ☐ Not Started

**2.7** (Optional) Build database image or prepare database
- Use PostgreSQL image OR prepare existing database credentials
- Ensure database is accessible from Docker containers
- **Status:** ☐ Not Started

### Deployment on Synology

**2.8** SSH into Synology NAS
- `ssh admin@dekknet.com`
- Navigate to docker directory: `cd /volume1/docker/familiez` (create if needed)
- **Status:** ☐ Not Started

**2.9** Create production docker-compose file on NAS
- File: `/volume1/docker/familiez/docker-compose.prod.yml`
- Configure all three services (frontend, middleware, database)
- Set environment variables via .env file or inline
- **Status:** ☐ Not Started

**2.10** Create environment file on NAS
- File: `/volume1/docker/familiez/.env`
- Set all production secrets and configurations
- Ensure proper file permissions (not world-readable)
- **Status:** ☐ Not Started

**2.11** Start Docker containers on NAS
- `docker-compose -f docker-compose.prod.yml up -d`
- Verify containers are running: `docker ps`
- Check logs: `docker-compose logs -f`
- **Status:** ☐ Not Started

### Reverse Proxy Configuration

**2.12** Configure Synology Reverse Proxy for Frontend
- Control Panel → Application Portal → Reverse Proxy
- Create new rule:
  - Source: `https://dekknet.com` port 443
  - Destination: `http://localhost:3000` (or container name)
  - Protocol: HTTPS
- **Status:** ☐ Not Started

**2.13** Configure Synology Reverse Proxy for API
- Create new rule:
  - Source: `https://dekknet.com/api` port 443
  - Destination: `http://middleware:5000` (or container IP)
  - Protocol: HTTP
- **Status:** ☐ Not Started

**2.14** Enable WebSocket support (if needed)
- Check reverse proxy settings for WebSocket support
- Configure timeouts appropriately
- **Status:** ☐ Not Started

### SSL & Security

**2.15** Configure SSL certificates on Synology
- Use Synology's built-in certificate (auto-renewable)
- OR use Let's Encrypt via Synology UI
- Verify certificate is valid for dekknet.com
- **Status:** ☐ Not Started

**2.16** Test HTTPS access
- Navigate to `https://dekknet.com`
- Verify SSL certificate is valid (no warnings)
- Test full SSO flow over HTTPS
- **Status:** ☐ Not Started

---

## PHASE 3: ONGOING MAINTENANCE

**3.1** Monitor Docker containers on NAS
- Regularly check: `docker ps`, `docker logs`
- Set up log rotation to prevent disk filling
- **Status:** ☐ Not Started

**3.2** Update credentials securely
- Rotate SYNOLOGY_CLIENT_SECRET periodically
- Update .env file without committing to git
- Restart containers: `docker-compose restart`
- **Status:** ☐ Not Started

**3.3** Backup database
- Set up automated PostgreSQL backups on NAS
- Store backups in separate volume
- **Status:** ☐ Not Started

**3.4** Handle SSL certificate renewal
- Synology auto-renews if using Synology certificate
- Monitor Let's Encrypt expiration if using external CA
- **Status:** ☐ Not Started

**3.5** Test disaster recovery
- Verify can restore from backup
- Document full reconstruction process
- Test on separate NAS if available
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
- Total Steps: 36
- Phase 1 (Local Development): 13 steps
- Phase 2 (NAS Deployment): 13 steps
- Phase 3 (Maintenance): 10 steps

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
- Your domain: `dekknet.com`
- DDNS is configured on your NAS
- SSL certificates should be valid for this domain
- If using self-signed certs, you may need `requests` with `verify=False`

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

**Last Updated:** 21 February 2026
**Next Review:** When starting Phase 1 implementation
