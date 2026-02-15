# Familiez — monorepo

This repository contains the Familiez application composed of multiple services:

- `MW/` — Middleware (FastAPI)
- `FE/` — Frontend application
- `BE/` — SQL scripts and DB initialization

Quick start (development):

1. Copy `.env.example` to `.env` and adjust credentials if needed.

2. Start services via docker compose:

```bash
cd /home/frans/Documenten/dev/Familiez
docker compose up -d --build
```

3. To enable remote debugging for the `MW` container, set the environment variable `DEBUG=1` for the `mw` service (or run container with `DEBUG=1`) and then attach the VS Code debugger to port `5678` using the "Attach to MW (Docker)" launch configuration.

Local development (without Docker):

- Use the VS Code task `Start MW (local)` to run `uvicorn` in your venv.
- Run tests with the `Debug Pytests` launch configuration or via `pytest` in the `MW` folder.

Notes:
- Put your frontend sources in `FE/` and database SQL in `BE/init/` so they are automatically loaded by the MariaDB container on first start.
- Dockerfiles: MW uses `MW/Dockerfile` and FE dev uses `FE/dockerfile.dev`.
- VS Code workspace file: `Familiez.code-workspace`.
