# McCormick.sh Infrastructure Guide for Agents

This repository manages the server infrastructure and Docker-based applications for the `mccormick.sh` project. It includes mail services (Postfix, Dovecot), storage (Nextcloud), security (Vaultwarden, Pi-hole, WireGuard), and web management (PostfixAdmin).

## Project Structure
- `/docker/apps/`: Main Docker Compose services.
- `/docker/apps/env/`: Environment-specific configurations (`.prd.env`, `.dev.env`).
- `/host/`: Server setup scripts and host-level configurations (systemctl, fail2ban).
- `deploy.sh`: Primary deployment script.

## Commands

### Deployment
Deployment is handled by `rsync` to the remote server.
- **Deploy everything:** `./deploy.sh`
- **Verify deployment:** The script syncs the `docker` directory to `/opt` on the target host.
- **Important:** `docker/scripts/` and `deploy.sh` are excluded from the `rsync` sync (see `deployExclude.txt`).

### Docker Operations
Services are defined in `/docker/apps/compose.yml`.
- **Set environment:** `export ENV=dev` or `export ENV=prd`
- **Build services:** `docker-compose build` (run from `/docker/apps/`)
- **Start services:** `docker-compose up -d`
- **Stop services:** `docker-compose down`
- **Check health:** `docker inspect --format='{{json .State.Health}}' <container_name>`

### Systemd Services (on host)
Systemd services in `host/systemctl/` manage the lifecycle of docker services on the remote server.
- `docker-infrastructure.service`: Base infrastructure (networks, etc.)
- `docker-apps.service`: The applications defined in `/opt/docker/apps/compose.yml`.

### Python Scripts
Located in `/docker/scripts/`.
- **Build image:** `docker build -t mccormick-scripts .` (run from `/docker/scripts/`)
- **Run script:** `docker run --env-file .env.production mccormick-scripts python <script_name>.py`

### Testing & Verification
There are no automated test suites. Use manual verification:
- **Mail Health:** Run `docker/apps/mail/healthcheck.sh` inside the mail container.
- **Logs:** `docker-compose logs -f <service>`
- **Database Scripts:** Refer to `host/dbScripts.txt` for common SQL operations.

### Common Database Operations
- **Access Postgres:** `psql -U root`
- **PostfixAdmin:** Setup involves creating the `postfixadmin` database and user `postfixadm`.
- **Nextcloud:** Setup involves creating the `nextcloud` database and user `ncuser`.
- **Note:** All credentials should be stored in Vaultwarden (BW).

---

## Code Style Guidelines

### Shell Scripts (`.sh`)
- **Interpreter:** Always use `#!/bin/bash` or `#!/bin/sh`.
- **Error Handling:** Use `set -e` to exit on error.
- **Formatting:** 2-space indentation.
- **Variables:** Double-quote all variable expansions (e.g., `"${VAR}"`) to prevent word splitting.
- **Linting:** Agents should run `shellcheck` if available before committing changes.

### Python Scripts (`.py`)
- **Indentation:** 4 spaces (PEP 8).
- **Naming:** `snake_case` for functions and variables.
- **Docstrings:** Use triple single quotes `'''docstring'''` for function and module documentation.
- **Imports:** Group imports: standard library, third-party, and local modules.
- **Linting:** Use `pylint`, `autopep8`, and `isort`.

### Docker & Compose
- **Images:** Prefer `alpine` based images for minimal footprint.
- **Indentation:** 2-space indentation for `compose.yml`.
- **Naming:** Service names in `compose.yml` should be lowercase kebab-case (e.g., `pfa-web`, `snappymail`).
- **Persistence:** Use host volumes mapped to `/opt/<service>` for persistent data.
- **Environment:** Never hardcode secrets. Use `env_file` referencing files in `env/`.

### Configuration (Nginx, Postfix, etc.)
- **Naming:** Use descriptive names for configuration files (e.g., `nginx.conf`, `sender_login_maps.local.cf`).
- **Structure:** Service-specific configs should reside in subdirectories named after the service (e.g., `docker/apps/pfa-web/`).

### Common Service Details
- **Mail:** Postfix and Dovecot are used. DKIM keys should be owned by `opendkim:vmail`.
- **PostfixAdmin:** Used for managing virtual mailboxes.
- **Sieve Filters:** Used for mail filtering/auto-replies.
- **Pi-hole:** Acts as the internal DNS server for the `docker-net` network.
- **Nextcloud:** PHP-FPM based, requires a separate Nginx frontend (`nc-web`).

### Error Handling
- **Container Restarts:** Use `restart: always` or `restart: on-failure` in `compose.yml`.
- **Health Checks:** Implement health checks in `Dockerfile` or `compose.yml` for critical services.

---

## Security
- **Secrets:** Do not commit plain-text passwords or API keys. Ensure they are added to `.env` files which should be excluded from git if they contain sensitive data (though this repo currently tracks some `.env` files for boilerplate).
- **Permissions:** Root-owned files in Docker volumes should be minimized; use `vmail` (UID 5000) for mail storage.

## Rules
- **Cursor/Copilot Rules:** None found in the current project root.
- **Agent Protocol:** Always analyze `compose.yml` and `deployExclude.txt` before modifying deployment logic.
