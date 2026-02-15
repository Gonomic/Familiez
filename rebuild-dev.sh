#!/bin/bash
# Script om Familiez containers opnieuw te builden en te starten
# Gebruik alleen wanneer er code wijzigingen zijn in Dockerfile/requirements/dependencies
# Gebruik: ./rebuild-dev.sh

echo "Rebuilding Familiez development containers..."
echo "⚠️  Dit kan enkele minuten duren..."

# Stop bestaande containers
echo "Stopping existing containers..."
docker stop familiez-fe familiez-mw familiez-mysql 2>/dev/null || true

# Start all services via root compose
echo ""
echo "Starting services via root docker-compose..."
docker-compose up -d --build

# Wacht op containers
sleep 5

# Toon status
echo ""
echo "Container status:"
docker ps | grep familiez

echo ""
echo "✅ Containers rebuilt en gestart!"
echo "Frontend:   http://localhost:5173"
echo "Middleware: http://localhost:8000"
echo "Database:   localhost:3306"
