#!/bin/bash
# Script om Familiez ontwikkelcontainers te stoppen
# Gebruik: ./stop-dev.sh

echo "Stopping Familiez development containers..."

# Stop de containers
docker stop familiez-fe familiez-mw familiez-mysql

echo ""
echo "✅ Containers gestopt!"
