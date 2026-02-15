#!/bin/bash
# Script om Familiez containers opnieuw te builden en te starten
# Gebruik alleen wanneer er code wijzigingen zijn in Dockerfile/requirements/dependencies
# Gebruik: ./rebuild-dev.sh (from anywhere)

# Change to script directory (Familiez root)
cd "$(dirname "$0")"

echo "Rebuilding Familiez development stack..."
echo "⚠️  Dit kan enkele minuten duren..."

# Stop en verwijder bestaande containers
echo "Stopping and removing existing containers..."
docker compose down

# Rebuild en start alle services
echo ""
echo "Building and starting services..."
docker compose up -d --build

# Wacht op containers
echo "Waiting for services to start..."
sleep 5

# Toon status
echo ""
echo "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|familiez"

echo ""
echo "✅ Familiez stack rebuilt en gestart!"
echo "Frontend:   http://localhost:5173"
echo "Middleware: http://localhost:8000"
echo "Database:   localhost:3306"
echo "Portainer:  http://localhost:9000"
