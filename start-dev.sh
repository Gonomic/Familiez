#!/bin/bash
# Script om bestaande Familiez ontwikkelcontainers te starten
# Gebruik: ./start-dev.sh (from anywhere)

# Change to script directory (Familiez root)
cd "$(dirname "$0")"

echo "Starting Familiez development stack..."

# Start alle services via docker compose
docker compose up -d

# Wacht even zodat containers kunnen opstarten
sleep 2

# Toon status
echo ""
echo "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|familiez"

echo ""
echo "✅ Familiez stack gestart!"
echo "Frontend:   http://localhost:5173"
echo "Middleware: http://localhost:8000"
echo "Database:   localhost:3306"
echo "Portainer:  http://localhost:9000"
