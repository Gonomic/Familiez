# Synology SSO Integration - Action Items

**Status:** Token exchange failing with 400 Client Error  
**Last Updated:** 24 februari 2026  
**Current Blocker:** `/webman/sso/SSOAccessToken.cgi` returning 400 error

---

## ✅ Completed Tasks
- [x] OAuth flow frontend implementation with PKCE
- [x] Middleware auth.py with token exchange function
- [x] Environment variables synchronized across FE, MW, and docker-compose.yml
- [x] CORS headers configured in middleware
- [x] Redirect URI updated from `sso.dekknet.com` to `192.168.1.89`
- [x] API_BASE updated from `localhost` to `192.168.1.89`
- [x] Debug logging added to middleware token exchange function
- [x] js-sha256 library added for PKCE (crypto.subtle not available over HTTP)

---

## 🔍 Debug Findings
- **Login page:** Works fine - can click Login button
- **OAuth authorization:** Redirects correctly to Synology SSO
- **Synology authentication:** Works - can login with 2FA
- **Callback redirect:** Works - Synology redirects back to `http://192.168.1.89:5173/auth/callback`
- **Token exchange:** FAILS with `400 Client Error` from `https://sso.dekknet.com/webman/sso/SSOAccessToken.cgi`

---

## 📋 TODO for Tomorrow

### 1. **CRITICAL: Check middleware logs after login attempt**
   - Run: `docker compose logs mw --tail=100` after clicking Login
   - Look for:
     - `Token exchange request to` - shows the full token endpoint URL
     - `Request body:` - shows what parameters are being sent (code, code_verifier, client_id, etc.)
     - `Token response status:` and `Token response body:` - shows Synology's 400 error response
   - Document what parameters are being sent vs what Synology expects

### 2. **Verify Synology SSO Application Configuration**
   - In DSM → SSO Server → Applications → Familiez
   - Double-check:
     - Application ID: `20314352477ee9eed91c10e2431b9cf6`
     - Redirect URI: `http://192.168.1.89:5173/auth/callback`
     - Is OIDC/OAuth enabled?
     - Are there any Grant Type restrictions?
     - Application Secret value

### 3. **Possible Solutions to Test**
   - Synology may require different token endpoint URL format
   - The `code_verifier` format might be incorrect for Synology
   - Client authentication method might need to be adjusted (Basic auth vs body params)
   - Synology might have strict parameter ordering requirements
   - May need to verify PKCE format is correct for Synology

### 4. **Alternative Debugging**
   - Test token exchange with curl command directly:
     ```bash
     curl -X POST https://sso.dekknet.com/webman/sso/SSOAccessToken.cgi \
       -H "Content-Type: application/json" \
       -d '{"grant_type":"authorization_code","code":"<code>","client_id":"20314352477ee9eed91c10e2431b9cf6","redirect_uri":"http://192.168.1.89:5173/auth/callback","code_verifier":"<verifier>","client_secret":"<secret>"}'
     ```
   - This will show exact Synology error without app layer

### 5. **Files to Check/Modify**
   - `/home/frans/Documenten/Dev/Familiez/MW/auth.py` - Token exchange function with debug logging
   - `/home/frans/Documenten/Dev/Familiez/FE/src/services/authService.js` - OAuth request construction
   - `/home/frans/Documenten/Dev/Familiez/docker-compose.yml` - Environment variables

---

## 💾 Current Configuration

**Frontend (.env.local / docker-compose):**
- VITE_SYNOLOGY_AUTH_URL: `https://sso.dekknet.com`
- VITE_CLIENT_ID: `20314352477ee9eed91c10e2431b9cf6`
- VITE_REDIRECT_URI: `http://192.168.1.89:5173/auth/callback`
- VITE_API_BASE: `http://192.168.1.89:8000`

**Middleware (.env / docker-compose):**
- SYNOLOGY_CLIENT_ID: `20314352477ee9eed91c10e2431b9cf6`
- SYNOLOGY_CLIENT_SECRET: `8CFADATNj3tVHQRNk5be1zk8a0afFaSz`
- SYNOLOGY_REDIRECT_URI: `http://192.168.1.89:5173/auth/callback`
- SYNOLOGY_OIDC_DISCOVERY_URL: `https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`
- SYNOLOGY_OIDC_VERIFY_SSL: `false`
- ALLOWED_ORIGINS: `http://localhost:5173,http://127.0.0.1:5173,http://192.168.1.89:5173`

---

## 🎯 End Goal
Get token exchange working → frontend receives `access_token` → user authenticated and logged into app

---

**Next Session:** Start by running login flow and checking middleware logs
