---
name: server-inspect
description: Inspect the remote mccormick.sh server for operational context. Use when checking remote configuration, running services, logs, disk usage, systemd status, or Docker status during infrastructure troubleshooting.
---

# Server Inspect

Use this skill when you need read-only operational context from the remote server for this repository.

## Helper Script

This skill uses the local helper script:

```bash
~/bin/server_inspect.sh
```

The script requires two arguments:

```bash
~/bin/server_inspect.sh <server> <command>
```

For this repo, the server is usually:

```bash
mccormick.sh
```

## Allowed Remote Commands

The helper script only permits commands matching this whitelist:

- `ls*`
- `cat*`
- `tail*`
- `head*`
- `df*`
- `du*`
- `free*`
- `uptime*`
- `ps*`
- `grep*`
- `journalctl*`
- `systemctl status*`
- `docker ps*`
- `docker logs*`

If another command is needed, do not bypass the helper. Ask the user first.

## Usage Examples

Check remote uptime:

```bash
~/bin/server_inspect.sh mccormick.sh "uptime"
```

Check disk usage:

```bash
~/bin/server_inspect.sh mccormick.sh "df -h"
```

Check systemd service status:

```bash
~/bin/server_inspect.sh mccormick.sh "systemctl status docker-apps.service"
~/bin/server_inspect.sh mccormick.sh "systemctl status docker-infrastructure.service"
```

List running containers:

```bash
~/bin/server_inspect.sh mccormick.sh "docker ps"
```

Inspect recent logs for a container:

```bash
~/bin/server_inspect.sh mccormick.sh "docker logs --tail 100 mail"
```

Inspect files deployed under `/opt/docker`:

```bash
~/bin/server_inspect.sh mccormick.sh "ls -la /opt/docker"
~/bin/server_inspect.sh mccormick.sh "ls -la /opt/docker/apps"
```

If logs are not in docker, they can be found at /opt/log.

## Safety Rules

- Treat this as read-only inspection.
- Do not run mutating commands through SSH for this skill.
- Do not print secrets from environment files or private key files.
- Prefer narrowly scoped commands, such as `docker logs --tail 100 <container>`, over broad log dumps.
- If inspecting logs, redact any secrets or tokens before summarizing results.
