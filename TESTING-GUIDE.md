# Familiez SSO Testing Guide - 22 February 2026

## Pre-Startup Checklist

### ✅ Verify Prerequisites
1. **Synology SSO Configured** ✓
   - Client ID: `familiez-local-dev`
   - Redirect URI: `http://sso.dekknet.com:5173/auth/callback`
   - Discovery URL: `https://sso.dekknet.com/webman/sso/.well-known/openid-configuration`

2. **Environment Files Ready**
   - [Familiez/.env](Familiez/.env) ✓ (with DB credentials)
   - [MW/.env](MW/.env) ✓ (with SSO config)
   - [FE/.env.local](FE/.env.local) ✓ (with Synology URLs)

3. **Hosts File Configuration** (Optional but recommended)
   ```bash
   # Add to /etc/hosts:
   # 127.0.0.1 sso.dekknet.com
   ```
   - Then you can access: `http://sso.dekknet.com:5173` instead of `localhost:5173`

---

## Step 1.11: Test SSO Flow Locally

### 1️⃣ Start Docker Containers
```bash
cd /home/frans/Documenten/Dev/Familiez
docker-compose up -d
```

### 2️⃣ Verify Containers Are Running
```bash
docker-compose ps
```

Expected output:
```
NAME                COMMAND                  SERVICE    STATUS
familiez-mysql      "/entrypoint.sh mariad…"  mysql     Up (healthy)
familiez-mw         "/start.sh"              mw        Up
familiez-fe         "npm run dev"            fe        Up
```

### 3️⃣ Access Frontend
- **URL:** `http://localhost:5173` 
- **Or with hosts:** `http://sso.dekknet.com:5173`

### 4️⃣ Test the SSO Flow
1. **Click "Login"** button (should be in top navigation)
2. **Expected Redirect:** 
   - Browser redirects to: `https://sso.dekknet.com/webman/sso/...` (Synology SSO login)
3. **Authenticate:** 
   - Enter your Synology credentials
4. **Expected Callback:**
   - Browser redirects to: `http://sso.dekknet.com:5173/auth/callback`
   - AuthCallback component processes the OAuth code
5. **Token Exchange:**
   - MW `/auth/callback` endpoint exchanges code for JWT
   - Token stored in localStorage
6. **Redirect to App:**
   - Should redirect to `/familiez-bewerken` (main app)
   - Should see authenticated UI (e.g., "Logout" button instead of "Login")

### ✅ Success Criteria
- ✓ Login button visible
- ✓ Redirected to Synology SSO
- ✓ Successfully authenticated with Synology
- ✓ Callback page processed without errors
- ✓ Token stored in browser localStorage
- ✓ Redirected to protected app page
- ✓ Logout button visible, indicating authenticated state

### 🔍 Debugging Tips
**If redirect fails:**
```bash
# Check MW logs:
docker-compose logs mw

# Check FE logs:
docker-compose logs fe

# Check if MW can reach Synology:
docker-compose exec mw curl -k https://sso.dekknet.com/webman/sso/.well-known/openid-configuration
```

---

## Step 1.12: Test Middleware Validation

### 1️⃣ Get Your JWT Token
Open browser DevTools (F12) → Application → LocalStorage
- Look for key: `familiez_token`
- Copy the token value

### 2️⃣ Call Protected Endpoint WITH Valid Token
```bash
# Replace TOKEN with your actual token
TOKEN="your-jwt-token-here"

curl -X GET http://localhost:8000/GetPersonsLike?stringToSearchFor=Smith \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:** ✅ 200 OK with family data

### 3️⃣ Call Protected Endpoint WITHOUT Token
```bash
curl -X GET http://localhost:8000/GetPersonsLike?stringToSearchFor=Smith
```

**Expected Response:** ❌ 401 Unauthorized
```json
{"detail": "Authorization header missing or invalid"}
```

### 4️⃣ Call Protected Endpoint WITH Invalid Token
```bash
curl -X GET http://localhost:8000/GetPersonsLike?stringToSearchFor=Smith \
  -H "Authorization: Bearer invalid.token.here"
```

**Expected Response:** ❌ 401 Unauthorized
```json
{"detail": "Invalid token"}
```

### 5️⃣ Call Public Endpoint (No Token Needed)
```bash
curl -X GET http://localhost:8000/
```

**Expected Response:** ✅ 200 OK
```json
{"message": "Familiez API - Protected by SSO"}
```

### ✅ Success Criteria
- ✓ Valid token: 200 OK, data returned
- ✓ No token: 401 Unauthorized
- ✓ Invalid token: 401 Unauthorized
- ✓ Public endpoints: 200 OK (no token needed)

### 🔍 Debugging
```bash
# Check MW logs for auth errors:
docker-compose logs -f mw | grep -i "auth\|token\|error"
```

---

## Step 1.13: Test Multiple Users

### 1️⃣ First User - Already Logged In
- Note any user-specific data displayed
- Check if you're logged in as expected user (if username visible)

### 2️⃣ Test Logout
```javascript
// In browser console:
localStorage.removeItem('familiez_token');
location.reload();
```

Or click "Logout" button if implemented.

### 3️⃣ Test Second User Login
- Login with **different Synology credentials**
- Verify you get a new token for the new user
- Check browser console: 
  ```javascript
  localStorage.getItem('familiez_token')
  // Should be different from first user's token
  ```

### 4️⃣ Verify Different User Data
- If user-specific data is displayed, it should differ from first user
- (This depends on whether your API returns user-scoped data from the token)

### ✅ Success Criteria
- ✓ First user login works
- ✓ Logout removes token from storage
- ✓ Second user can login with different credentials
- ✓ Second user gets different JWT token
- ✓ (Optional) User-specific data differs per user

---

## Quick Command Reference

### View Logs
```bash
docker-compose logs -f mw         # Middleware logs
docker-compose logs -f fe         # Frontend logs
docker-compose logs -f mysql      # Database logs
docker-compose logs               # All services
```

### Stop Containers
```bash
docker-compose down               # Stop all
docker-compose down -v            # Stop + remove volumes
```

### Rebuild & Restart
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Access Database
```bash
docker-compose exec mysql mysql -uHumansService -pXHHxECL54EjvhhPSBLMU humans -e "SELECT * FROM humans.Person LIMIT 5;"
```

---

## Testing Summary

After completing all tests above, update the plan:

```
Step 1.11: ✅ Test SSO flow locally - [PASS/FAIL]
Step 1.12: ✅ Test middleware validation - [PASS/FAIL]
Step 1.13: ✅ Test multiple users - [PASS/FAIL]
```

---

**Last Updated:** 22 February 2026
**Status:** Ready for Testing
