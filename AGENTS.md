# McCormick.sh Infrastructure Guide for Agents

This repository manages the server infrastructure and Docker-based applications for the `mccormick.sh` host. It is primarily an operations repo: Docker Compose definitions, service configuration, host setup files, and a small set of utility scripts.

## Codebase Overview

- `deploy.sh` — deploys the Docker configuration to the remote host with `rsync`.
- `deployExclude.txt` — files/directories excluded from deployment. Always check this before changing deployment behavior.
- `docker/infrastructure/` — base infrastructure stack shared by the apps.
  - `compose.yml` defines reverse proxy, ACME companion, Postgres, Redis, mail certificate helper, and cron jobs.
  - `env/` contains environment files used by infrastructure services.
  - `proxy/`, `cron/`, `mail.fl_cert/`, and `unbound/` contain service-specific configuration/build files.
- `docker/apps/` — application stack.
  - `compose.yml` defines mail, PostfixAdmin, SnappyMail, Rspamd, Vaultwarden, Pi-hole, WireGuard, Nextcloud, and app Nginx frontends.
  - `env/` contains application environment files.
  - `mail/`, `pfa-web/`, `nc-web/`, and `rspamd/` contain service-specific config/build files.
- `docker/scripts/` — Python utility scripts and Dockerfile for running those scripts. This directory is excluded from normal deploy sync.
- `host/` — host-level setup and configuration files.
  - `systemctl/` contains systemd units for managing the Docker stacks.
  - `fail2ban/`, `logrotate/`, SSH, resolver, and unbound configs support host hardening/ops.
  - `dbScripts.txt` contains common Postgres setup/maintenance commands.

## Deployment Model

Deployment is handled by syncing the local `docker/` directory to `/opt/docker` on the remote host:

```bash
./deploy.sh
```

The script uses:

```bash
rsync -rhPuL --exclude-from=deployExclude.txt --delete docker mccormick.sh:/opt
```

Important deployment notes:

- `docker/scripts/`, `deploy.sh`, and `db.sqlite3` are currently excluded by `deployExclude.txt`.
- Do not assume a local file is deployed; verify it is not excluded.
- Before modifying deployment behavior, read both `docker/apps/compose.yml` and `deployExclude.txt`.
- Runtime persistent data lives under `/opt/...` on the server and should not be committed to this repo.

## Docker Operations

Application stack:

```bash
cd docker/apps
export ENV=prd   # or dev, when a dev env file exists
Docker Compose up -d
```

Infrastructure stack:

```bash
cd docker/infrastructure
Docker Compose up -d
```

This repo may use either `docker compose` or legacy `docker-compose` depending on the host. Preserve the style already used in nearby docs/scripts unless changing intentionally.

## Major Services

Infrastructure stack:

- `proxy` — nginx-proxy frontend on ports 80/443.
- `ssl` — nginxproxy/acme-companion for Let's Encrypt certificates.
- `db` — Postgres database.
- `redis` — Redis service.
- `mail.fl_cert` — helper for mail certificate handling.
- `cron` — cron container for operational jobs such as Rspamd reject reports.

Application stack:

- `mail` — custom Postfix/Dovecot mail container.
- `postfixadmin` and `pfa-web` — PostfixAdmin FPM app and Nginx frontend.
- `snappymail` — webmail.
- `rspamd` — spam filtering/DKIM.
- `vault` — Vaultwarden.
- `pihole` — internal DNS, fixed address `172.19.1.20` on `docker-net`.
- `vpn` — WireGuard.
- `nextcloud` and `nc-web` — Nextcloud FPM app and Nginx frontend.

## Systemd Services

Host systemd units are in `host/systemctl/`:

- `docker-infrastructure.service` — manages the infrastructure stack.
- `docker-apps.service` — manages the application stack.

Use these on the remote host when checking startup/lifecycle behavior.

## Manual Verification

There is no automated test suite. Use targeted checks:

- Validate Compose syntax after edits:
  ```bash
  cd docker/apps && docker compose config
  cd docker/infrastructure && docker compose config
  ```
- Check service logs:
  ```bash
  docker compose logs -f <service>
  ```
- Check container health:
  ```bash
  docker inspect --format='{{json .State.Health}}' <container_name>
  ```
- Mail health check lives at `docker/apps/mail/healthcheck.sh` and should be run inside the mail container when needed.

## Style Guidelines

Shell scripts:

- Use `#!/bin/bash` or `#!/bin/sh`.
- Prefer `set -e` for scripts that should stop on errors.
- Use 2-space indentation.
- Double-quote variable expansions, e.g. `"${VAR}"`.
- Run `shellcheck` if available after changing shell scripts.

Python scripts:

- Use 4-space indentation and PEP 8 naming.
- Prefer `snake_case` for functions and variables.
- Use triple single-quoted docstrings.
- Group imports: standard library, third-party, local.
- If available, use `pylint`, `autopep8`, and `isort`.

Docker/Compose:

- Keep YAML indentation at 2 spaces.
- Service names should be lowercase/kebab-case where possible.
- Prefer Alpine-based images when adding new services.
- Use `restart: always`, `restart: unless-stopped`, or `restart: on-failure` consistently for long-running services.
- Use `env_file` for configuration and secrets; do not hardcode credentials in Compose files.
- Persistent data should map to `/opt/<service>` on the host.

Configuration files:

- Keep service-specific config in the relevant service directory.
- Use descriptive filenames such as `nginx.conf`, `uploadsize.conf`, or `auth-sql.local.ext`.

## Security Notes

- Do not commit plaintext passwords, tokens, API keys, DKIM private keys, or production-only secrets.
- Environment files in this repo may contain boilerplate, but treat them carefully and avoid adding real secrets.
- DKIM private keys should be owned appropriately on the server; the README notes that DKIM keys must not be root-owned.
- Be careful with `/opt` volume ownership, especially mail storage under `/opt/vmail`.
- Review exposed ports before adding services. Current public-facing ports include mail ports and the reverse proxy.

## Agent Rules

- Prefer reading existing files before editing; do not infer service behavior solely from names.
- Before changing deployment logic, always inspect `docker/apps/compose.yml`, `docker/infrastructure/compose.yml`, and `deployExclude.txt`.
- Use precise, minimal edits and preserve existing formatting.
- Do not add generated files, local caches, databases, or runtime data to the repo.
- If a change affects production services, include manual verification steps in the final response.
