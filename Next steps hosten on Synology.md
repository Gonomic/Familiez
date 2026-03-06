# Familiez op Synology NAS Hosten - Gedetailleerd Stappenplan

## 1. Voorbereiding & Vereisten

### 1.1 Zelf-voorziening
- **SSL/TLS Certificaten**: Je hebt al certificaten voor `dekknet.com`. Zorg ervoor dat deze ook wildcards of subdomains dekken voor je Familiez-app (bijv. `familiez.dekknet.com`).
- **Synology DSM versie**: Controleer of je DSM versie (bijv. DSM 7.x) Docker Container Manager ondersteunt.
- **Single Sign-On (SSO)**: Synology biedt LDAP/Active Directory via DSM. Dit zul je moeten configureren als backend voor authenticatie.

### 1.2 Domeinstructuur
Ik stel voor:
- **Frontend**: `familiez.dekknet.com`
- **Middleware**: `api.familiez.dekknet.com` (optioneel, kan ook intern)
- **Database**: Alleen intern bereikbaar (geen publieke route)

---

## 2. Productie-aanpassingen aan de Stack

### 2.1 Frontend (FE) - Productie Bouw

**Stap 1: Webpack/Vite produktiebuild**
- Zorg dat `vite.config.js` configured is voor production build
- Commando: `npm run build` (creëert `dist/` folder)
- Alle dev tools moet uit zijn

**Stap 2: Dockerfile voor FE Production**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY . .
RUN npm ci && npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

**Stap 3: nginx.conf voor reverse proxy & HTTPS**
```nginx
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name familiez.dekknet.com;

    ssl_certificate /etc/nginx/ssl/dekknet.com.crt;
    ssl_certificate_key /etc/nginx/ssl/dekknet.com.key;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://familiez-mw:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2.2 Middleware (MW) - Productie Bouw

**Stap 1: Python environment aanpassing**
- Zet `DEBUG = False` in `main.py`
- Voeg production logger toe (niet naar console, maar naar bestand)
- Verwijder dev routes (bijv. testendpoints)

**Stap 2: Dockerfile voor MW Production**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Stap 3: Environment variabelen (secure)**
- Zet DB_HOST, DB_USER, DB_PASS via docker secrets of env variables (niet hardcoded!)
- Voorbeeld: `docker-compose.yml` met `secrets:` of `environment:`

### 2.3 Database (BE) - Productie Setup

**Stap 1: MariaDB Hardening**
- Geen root password zonder wachtwoord
- Aparte users voor app (bijv. `HumansService` met beperkte privileges)
- Backups automatiseren (dagelijks naar NAS-storage)

**Stap 2: Dockerfile/docker-compose voor DB**
```yaml
services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: humans
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
      - ./init:/docker-entrypoint-initdb.d
    ports:
      - "3306"  # Niet naar buiten exposed!
    restart: always
```

---

## 3. Synology-specifieke Configuratie

### 3.1 Docker Container Manager op Synology configureren

**Stap 1: Voorbereiding**
- Ga naar Synology DSM → **Package Center** → Zoek **Docker Manager** → Installeer
- Zorg dat voldoende schijfruimte beschikbaar is

**Stap 2: Netwerksetup**
- Creëer een Docker-netwerk: `docker network create familiez-prod`
- Dit isoleer je containers van elkaar

**Stap 3: SSL Certificaten installeren**
- Plaats je `dekknet.com.crt` en `.key` in een directory op de NAS (bijv. `/volume1/docker/certs/`)
- Mount deze in de nginx container

### 3.2 Single Sign-On (SSO) Integratie

**Optie A: Synology LDAP**
- DSM biedt ingebouwde LDAP. Configureer in **Control Panel** → **Domain/LDAP**
- In FE: Voeg SAML/OIDC login toe die DSM's authenticatie gebruikt
- Middleware moet OIDC valideren of via reverse proxy header de gebruiker ontvangen

**Optie B: Reverse Proxy met SSO**
- Gebruik Synology's **Reverse Proxy** (in Control Panel) om inlog af te dwingen vóór routering naar containers
- Voorbeeld config:
  ```
  Source: https://familiez.dekknet.com
  Destination: http://localhost:<port> (je FE container)
  Enable SSO authentication
  ```

**Optie C: OAuth2 Proxy (aanbevolen voor meer controle)**
- Use OAuth2 Proxy container tussen FE en gebruiker
- Config: Koppel aan Synology's OIDC of LDAP backend
- Alle requests worden geverifieerd voordat ze FE bereiken

---

## 4. Docker Compose Setup voor Synology

**Cre eer `docker-compose.prod.yml`:**
```yaml
version: '3.8'

services:
  familiez-fe:
    build:
      context: ./FE
      dockerfile: Dockerfile.prod
    container_name: familiez-fe
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - /volume1/docker/certs:/etc/nginx/ssl:ro
      - /volume1/docker/logs/nginx:/var/log/nginx
    environment:
      - NODE_ENV=production
    networks:
      - familiez-prod
    restart: always
    depends_on:
      - familiez-mw

  familiez-mw:
    build:
      context: ./MW
      dockerfile: Dockerfile.prod
    container_name: familiez-mw
    environment:
      - DB_HOST=familiez-db
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - PYTHONUNBUFFERED=1
      - LOG_LEVEL=INFO
    networks:
      - familiez-prod
    restart: always
    depends_on:
      - familiez-db
    expose:
      - "8000"

  familiez-db:
    build:
      context: ./BE
      dockerfile: Dockerfile.prod
    container_name: familiez-db
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE=humans
    volumes:
      - /volume1/docker/mysql:/var/lib/mysql
      - ./BE/init:/docker-entrypoint-initdb.d:ro
    networks:
      - familiez-prod
    restart: always
    expose:
      - "3306"

networks:
  familiez-prod:
    driver: bridge

volumes:
  mysql_data:
    driver: local
```

**Create `.env.prod` (in root):**
```env
DB_ROOT_PASSWORD=<SterkWachtwoord>
DB_USER=HumansService
DB_PASSWORD=<AppWachtwoord>
NODE_ENV=production
FLASK_ENV=production
```

---

## 5. Gedetailleerd Deployment Stappenplan

### Stap 1: Voorbereiding (lokaal)
```bash
# Clone alle repos naar de NAS via SSH
cd /volume1/docker/Familiez
# FE, MW, BE klonen

# Bouw production images
docker build -t familiez-fe:prod ./FE -f FE/Dockerfile.prod
docker build -t familiez-mw:prod ./MW -f MW/Dockerfile.prod
docker build -t familiez-db:prod ./BE -f BE/Dockerfile.prod
```

### Stap 2: Secrets Management
- **Wachtwoorden nooit hardcoden!**
- Gebruik Synology's **Shared Folders** voor `.env.prod`
- Of: Docker Secrets (via swarm mode, als enabled)

### Stap 3: Deploy op Synology
```bash
# SSH naar Synology
ssh admin@<synology-ip>

# Navigeer naar docker directory
cd /volume1/docker/Familiez

# Zet .env in place
# Copy certificates
cp /volume1/certs/dekknet.com.crt ./certs/
cp /volume1/certs/dekknet.com.key ./certs/

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Controleer status
docker-compose ps
docker logs familiez-fe
docker logs familiez-mw
```

### Stap 4: SSL Certificaten Verlenging
- Synology's Certificaat Manager handelt dit automatisch af
- FE-container mount `/etc/nginx/ssl` read-only naar het Synology cert-store

### Stap 5: Backups configureren
```bash
# Cron job op Synology voor dagelijkse DB backup
# Bijv.: /volume1/docker/scripts/backup.sh

#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec familiez-db mysqldump -u root -p${DB_ROOT_PASSWORD} humans > /volume1/backups/humans_${DATE}.sql
gzip /volume1/backups/humans_${DATE}.sql
```

---

## 6. Security Best Practices

### 6.1 Netwerk
- Database niet naar buiten exposed (alleen intern tussen MW ↔ DB)
- FE alleen via HTTPS accessible
- Firewall: Inbound 80, 443 open; rest gesloten

### 6.2 Authenticatie
- SSO verplicht voor alle eindpunten
- Session timeout: 15-30 minuten inactiviteit
- Wachtwoorden: Minimaal 12 karakters, complex

### 6.3 Logging & Monitoring
- Alle requests loggen (nginx access logs)
- Errors centraal opslaan (syslog naar centraal systeem)
- Monitoring: Health checks per container

### 6.4 Updates
- Wekelijks base images updaten (Node, Python, MariaDB)
- Security patches onmiddellijk toepassen
- Test updates eerst op dev-omgeving

---

## 7. Performance Optimalisaties

### 7.1 Frontend
- Gzip compressie inschakelen in nginx
- Cache headers voor static assets (30 dagen)
- Minification van JS/CSS (al in Vite build)

### 7.2 Middleware
- Connection pooling voor DB (bijv. SQLAlchemy pool size)
- Rate limiting voor API endpoints
- Caching van frequent queried data

### 7.3 Database
- Indexes op veelgebruikte kolommen (PersonID, RelationName, etc.)
- Regular `OPTIMIZE TABLE` command
- Binlog voor replication (optioneel, voor redundancy)

---

## 8. Troubleshooting & Health Checks

### Health Check Endpoint
Voeg toe aan `main.py`:
```python
@app.get("/health")
def health_check():
    # Check DB connectivity
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}
    except:
        return {"status": "failed"}, 500
```

Docker compose:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Logging
- Alle container logs via `docker logs <container>`
- Zentraliseren via ELK Stack (Elasticsearch/Logstash/Kibana) optioneel

---

## 9. Voorbeeld DNS Setup voor dekknet.com

Zorg dat in je DNS records staan:
```
familiez.dekknet.com  A  <Synology IP of dyndns hostname>
api.familiez.dekknet.com  A  <Same as above>
```

Als je reverse proxy op Synology gebruikt, route je zelf de paths.

---

## 10. Finale Checklist voor Go-Live

- [ ] SSL certificaten geinstalleerd en geldig
- [ ] `.env.prod` veilig opgeslagen (geen git!)
- [ ] Database backups getest
- [ ] SSO login werkt end-to-end
- [ ] HTTPS enforced (geen plain HTTP)
- [ ] Security headers ingesteld (HSTS, X-Frame-Options, etc.)
- [ ] Logging gaat actief
- [ ] Health checks returnen 200
- [ ] Performance tests gedaan (load balancing indien nodig)
- [ ] Documentatie bijgewerkt (ops team)
- [ ] Monitoring & alerting staat aan

---

## Vragen/Aanpassingen?

Dit plan is comprehensive maar kan aangepast worden op basis van:
- Je Synology model & specs
- Aantal gebruikers en load
- Uptime requirements
- Budget (bijv. extra HDDs voor backups)

Laat weten welke stap je wilt uitdiepen!
