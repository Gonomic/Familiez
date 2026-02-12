#!/bin/bash
# Script om bestaande Familiez ontwikkelcontainers te starten
# Gebruik: ./start-dev.sh

echo "Starting Familiez development containers..."

# Start de bestaande containers
docker start familiez-mysql
docker start familiez-mw
docker start familiez-fe

# Wacht even zodat containers kunnen opstarten
sleep 2

# Toon status
echo ""
echo "Container status:"
docker ps | grep familiez

echo ""
echo "✅ Containers gestart!"
echo "Frontend:   http://localhost:5173"
echo "Middleware: http://localhost:8000"
echo "Database:   localhost:3306"
