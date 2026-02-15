# Familiez Development Scripts

Handige scripts om de ontwikkelomgeving te beheren.

## 🤖 Afspraken met AI Assistant

Wanneer je aan de AI assistant vraagt:
- **"Start de ontwikkelcontainers"** → Gebruikt `./start-dev.sh` (bestaande containers, GEEN rebuild)
- **"Stop de containers"** → Gebruikt `./stop-dev.sh`
- **"Rebuild de containers"** of **"Build opnieuw"** → Gebruikt `./rebuild-dev.sh` (volledige rebuild)

Dit voorkomt onnodige rebuilds en bespaart tijd! ⚡

## 📦 Scripts

### `./start-dev.sh`
**Start bestaande containers (GEEN rebuild)**
- Gebruik dit voor dagelijks werk
- Start containers die al gebouwd zijn
- Snel (2-3 seconden)

```bash
./start-dev.sh
```

### `./stop-dev.sh`
**Stop alle ontwikkelcontainers**
- Gebruik aan het eind van een sessie
- Containers blijven bestaan, worden alleen gestopt

```bash
./stop-dev.sh
```

### `./rebuild-dev.sh`
**Rebuild en start containers (VOLLEDIGE rebuild)**
- Gebruik alleen wanneer:
  - MW/Dockerfile of FE/dockerfile.dev is gewijzigd
  - requirements.txt is gewijzigd
  - package.json dependencies zijn gewijzigd
  - Er problemen zijn met de containers
- Dit duurt langer (1-2 minuten)

```bash
./rebuild-dev.sh
```

## 🎯 Workflow

**Normale werkdag:**
```bash
# Start van de dag
./start-dev.sh

# Ontwikkel je code...
# Wijzigingen in .jsx, .py, .js worden automatisch herladen

# Einde van de dag
./stop-dev.sh
```

**Na dependency wijzigingen:**
```bash
# Stop eerst alles
./stop-dev.sh

# Rebuild containers
./rebuild-dev.sh
```

## 🌐 URLs

- **Frontend**: http://localhost:5173
- **Middleware**: http://localhost:8000
- **Database**: localhost:3306
- **Portainer**: http://localhost:9000

## 📝 Container Namen

- `familiez-fe` - Frontend (React + Vite)
- `familiez-mw` - Middleware (FastAPI)
- `familiez-mysql` - Backend Database (MariaDB 10.6)

## 🧭 Portainer (optioneel)

- Eerste keer openen: stel een admin-wachtwoord in en kies local Docker environment.
- Gebruik dit alleen lokaal; zet de poort niet open naar het internet.

## 💡 Tips

- Bij code wijzigingen in JS/JSX/PY bestanden: gewoon opslaan, auto-reload werkt
- Bij wijzigingen in Docker configuratie: gebruik `rebuild-dev.sh`
- Portainer (http://localhost:9000) laat alle containers zien
