# Tailscale + Docker improvements (plan)

Assumes `mccormick.sh` = tailnet node `mail` (100.68.5.103). Confirm before starting.

## 1. Replace WireGuard container with Tailscale
- [ ] Confirm `router` peer in `env/vpn.prd.env` isn't a site-to-site link still needed (`PEERS=iphone,ipad,router,macMini`).
- [ ] Install Tailscale on iPhone/iPad (macMini if not cave).
- [ ] On `mail`: `sudo tailscale set --advertise-routes=172.19.1.20/32` and approve in console (exposes Pi-hole to tailnet).
- [ ] Console → DNS: add nameserver 172.19.1.20, enable "Override local DNS".
- [ ] Verify ad-blocking from phone over Tailscale.
- [ ] Remove `vpn` service from `docker/apps/compose.yml`; close UDP 51820 in firewall; `docker compose config`.

## 2. Move admin UIs off the public internet
- [ ] Split DNS: console → DNS → `mccormick.sh` → Pi-hole; Pi-hole local records `postfix.mccormick.sh` (+ pihole UI) → 100.68.5.103.
- [ ] `docker/infrastructure/proxy/vhost.d/postfix.mccormick.sh`: `allow 100.64.0.0/10; allow fd7a:115c:a1e0::/48; deny all;`
- [ ] Same for Vaultwarden `/admin` (`vhost.d/vault.mccormick.sh_location`-style rule), keep the vault itself public.
- [ ] Verify from tailnet (works) and from cellular w/o Tailscale (403). Certs still renew (ACME uses /.well-known on port 80, unaffected).

## 3. SSH via tailnet only
- [x] Inspect sshd config. Found: sshd listens on **port 133** (not 22) — that's why 22 is refused over tailnet.
- [x] Found: `sshd_config.d/50-cloud-init.conf` (included first, first value wins) re-enables password auth; server offers `publickey,password`. Also `PermitEmptyPasswords yes`.
- [x] Repo: `host/sshd_config` → `PermitEmptyPasswords no`.
- [ ] Server (needs sudo password):
  `ssh -t mccormick.sh 'sudo rm /etc/ssh/sshd_config.d/50-cloud-init.conf && sudo sed -i "s/^PermitEmptyPasswords yes/PermitEmptyPasswords no/" /etc/ssh/sshd_config && sudo sshd -t && sudo systemctl reload ssh'`
- [ ] Verify: `ssh -o BatchMode=yes -o PubkeyAuthentication=no -p 133 nobody@212.56.36.26 true` → `Permission denied (publickey)` only.
- [ ] Fix `.pi/skills/server-inspect/SKILL.md`: it lists `grep*` but `~/bin/server_inspect.sh` doesn't allow it.
- [ ] Inspect remaining: `cat /etc/fail2ban/jail.local` (sshd jail on 133?), `ls /etc/nftables.conf /etc/ufw` then `cat` existing firewall rules.
- [ ] Test `ssh -p 133 mail` from cave (tailnet). Optionally `sudo tailscale set --ssh` on `mail` and `hermes`.
- [ ] Only after tailnet SSH works: block public 133 (keep provider console as break-glass).

## 4. Tighten tailnet policy (console, affects all nodes)
- [ ] Tag servers `tag:server`; disable key expiry on them (keys expire ~6 months otherwise).
- [ ] ACL: members → anything; `tag:server` → no access to cave/raspberrypi.
