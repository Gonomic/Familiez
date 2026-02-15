#!/bin/bash
# Script om Familiez ontwikkelcontainers te stoppen
# Gebruik: ./stop-dev.sh (from anywhere)

# Change to script directory (Familiez root)
cd "$(dirname "$0")"

echo "Stopping Familiez development stack..."

# Stop alle services via docker compose
docker compose stop

echo ""
echo "✅ Familiez stack gestopt!"
echo "ℹ️  Containers blijven behouden. Gebruik ./start-dev.sh om opnieuw te starten."
echo "ℹ️  Gebruik 'docker compose down' om containers volledig te verwijderen."
