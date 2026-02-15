# Familiez Project - Quick Start Guide

## Project Structure
The Familiez project consists of three repositories:
- **MW** - Middleware (Docker Compose orchestration)
- **BE** - Backend (Database schema, stored procedures, functions)
- **FE** - Frontend (React application)

## Setup Instructions

### 1. Clone Repositories (if not already done)
```bash
cd /home/frans/Documenten/dev/Familiez

# Backend
git clone https://github.com/Gonomic/Familiez-BE.git BE

# Frontend
git clone https://github.com/Gonomic/Familiez-FE.git FE

# Middleware (already exists)
cd MW
```

### 2. Initialize Database
```bash
# Generate database initialization files
cd /home/frans/Documenten/dev/Familiez/BE
./scripts/prepare-schema.sh
./scripts/prepare-init.sh

# Start MariaDB container
cd /home/frans/Documenten/dev/Familiez/MW
docker compose up -d

# Wait ~40 seconds for initialization to complete
sleep 40

# Verify database is ready
docker compose exec mysql mysql -uHumansService -pXHHxECL54EjvhhPSBLMU humans -e "
SELECT CONCAT('✓ ', COUNT(*), ' of 11 Tables') AS Status FROM information_schema.TABLES WHERE TABLE_SCHEMA='humans'
UNION ALL SELECT CONCAT('✓ ', COUNT(*), ' of 10 Functions') FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='humans' AND ROUTINE_TYPE='FUNCTION'
UNION ALL SELECT CONCAT('✓ ', COUNT(*), ' of 8 Procedures') FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='humans' AND ROUTINE_TYPE='PROCEDURE';
"
```

Expected output:
```
Status
✓ 11 of 11 Tables
✓ 10 of 10 Functions
✓ 8 of 8 Procedures
```

### 3. Start Frontend (optional)
```bash
cd /home/frans/Documenten/dev/Familiez/FE
npm install
npm run dev
```

## Common Commands

### Database Operations
```bash
cd /home/frans/Documenten/dev/Familiez/MW

# Start database
docker compose up -d

# Stop database
docker compose down

# Stop and delete all data (fresh start)
docker compose down -v

# View logs
docker compose logs -f mysql

# Connect to database (root)
docker compose exec mysql mysql -uroot -prootpassword humans

# Connect to database (application user)
docker compose exec mysql mysql -uHumansService -pXHHxECL54EjvhhPSBLMU humans
```

### Development Workflow

#### Making Database Changes
1. Edit source files in `BE/` (e.g., `humans_persons.sql`, `fGetFather.sql`)
2. Regenerate init files:
   ```bash
   cd /home/frans/Documenten/dev/Familiez/BE
   ./scripts/prepare-schema.sh
   ./scripts/prepare-init.sh
   ```
3. Commit changes:
   ```bash
   git add <changed-files>
   git commit -m "Description of changes"
   git push
   ```
4. Reinitialize database:
   ```bash
   cd /home/frans/Documenten/dev/Familiez/MW
   docker compose down -v
   docker compose up -d
   ```

#### Updating from GitHub
```bash
# Backend
cd /home/frans/Documenten/dev/Familiez/BE
git pull

# Frontend
cd /home/frans/Documenten/dev/Familiez/FE
git pull

# Middleware
cd /home/frans/Documenten/dev/Familiez/MW
git pull
```

## Project Components

### Database (MariaDB 10.6)
- 11 tables for person, relation, and address data
- 10 functions for data retrieval and validation
- 8 procedures for finding possible family relationships
- Automatic transaction logging

### Middleware (Python)
- REST API endpoints
- Database connection handling
- Business logic layer

### Frontend (React + Vite)
- Material-UI components
- Family tree visualization
- Person and relationship management

## Dockerfiles

- MW uses `MW/Dockerfile`.
- FE development uses `FE/dockerfile.dev`.

## Troubleshooting

### Database won't start
```bash
# Check if port 3306 is already in use
sudo lsof -i :3306

# Check container status
docker compose ps

# View detailed logs
docker compose logs mysql
```

### Functions/Procedures missing
```bash
# Check for errors during initialization
docker compose logs mysql | grep ERROR

# Verify init files exist
ls -lh /home/frans/Documenten/dev/Familiez/BE/init/

# Regenerate and restart
cd /home/frans/Documenten/dev/Familiez/BE
./scripts/prepare-schema.sh && ./scripts/prepare-init.sh
cd /home/frans/Documenten/dev/Familiez/MW
docker compose down -v && docker compose up -d
```

### Permission denied errors
```bash
# Make scripts executable
chmod +x /home/frans/Documenten/dev/Familiez/BE/scripts/*.sh
```

## Documentation
- [Database Initialization Guide](BE/README-Database-Init.md)
- [Backend README](BE/README.md)
- [Frontend README](FE/README.md)

## Support
For issues or questions:
1. Check the logs: `docker compose logs`
2. Verify all services are running: `docker compose ps`
3. Review the README files in each repository
