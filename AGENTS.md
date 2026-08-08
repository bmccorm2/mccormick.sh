# McCormick.sh Infrastructure Guide

Operations repo for the `mccormick.sh` host: Docker Compose stacks, service config, host setup, and utility scripts.

## Layout

- `deploy.sh` / `deployExclude.txt` — rsync `docker/` to `/opt/docker` on the remote host. Excludes `docker/scripts/`, `deploy.sh`, `db.sqlite3`. Check the exclude file before touching deploy behavior.
- `docker/infrastructure/` — shared base stack (`compose.yml`): proxy, ACME companion, Postgres, Redis, mail cert helper, cron.
- `docker/apps/` — app stack (`compose.yml`): mail (Postfix/Dovecot 2.4), PostfixAdmin, SnappyMail, Rspamd, Vaultwarden, Pi-hole, WireGuard, Nextcloud, and their Nginx frontends.
- `docker/scripts/` — Python utilities (not deployed).
- `host/` — systemd units (`systemctl/`), fail2ban, logrotate, SSH, resolver, unbound configs, `dbScripts.txt`.

Service config lives in each service's subdirectory. Persistent runtime data lives under `/opt/...` on the server and is never committed. Mail storage is `/opt/vmail` → `/var/mail` in the `mail`/`rspamd` containers.

## Operations

```bash
./deploy.sh                              # sync docker/ to host

cd docker/apps && ENV=prd docker compose up -d
cd docker/infrastructure && docker compose up -d
```

Systemd units on the host: `docker-apps.service`, `docker-infrastructure.service`.

No test suite. Verify with:

```bash
docker compose config                    # validate after edits
docker compose logs -f <service>
docker inspect --format='{{json .State.Health}}' <container>
```

## Nextcloud Upgrades

`docker/apps/nextcloud/config.php` is bind-mounted into the container and also lives in this repo. `occ upgrade` rewrites `'version'` (and other keys) inside that file **on the server**, but `deploy.sh` will blindly overwrite the server's file with whatever is committed locally.

Upgrade procedure, in order:

1. In local `docker/apps/nextcloud/config.php`, set `'config_is_read_only' => false`, then `./deploy.sh`.
2. `cd docker/apps && docker compose up -d nextcloud`
3. `docker compose exec -u www-data nextcloud php occ upgrade`
4. Pull the server's updated `config.php` back into the repo **before doing anything else**. The container's entrypoint `chown`s the file to `82:82`, so `bryan` can't read it directly on the server — copy it to a readable location first:
   ```bash
   ssh mccormick.sh 'sudo cp /opt/docker/apps/nextcloud/config.php ~/config.php && sudo chown bryan ~/config.php'
   scp mccormick.sh:~/config.php docker/apps/nextcloud/config.php
   ssh mccormick.sh 'rm ~/config.php'
   ```
5. In that freshly-pulled file, set `'config_is_read_only' => true` again, then `./deploy.sh`.

Skipping step 4 and just flipping the flag back locally will redeploy the stale pre-upgrade `version`, causing Nextcloud to report "you need to upgrade" again even though the upgrade already succeeded.

## Conventions

- Shell: `#!/bin/bash`, `set -e`, 2-space indent, quote expansions, `shellcheck` if available.
- Python: PEP 8, 4-space indent, `snake_case`.
- Compose/YAML: 2-space indent, kebab-case service names, Alpine images preferred, `env_file` for secrets, persistent data under `/opt/<service>`.
- Never commit passwords, tokens, API keys, or DKIM private keys. DKIM keys must not be root-owned on the server.
- Read existing files before editing; make minimal edits; don't add generated files, caches, or runtime data.
