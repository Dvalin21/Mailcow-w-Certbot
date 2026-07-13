# Mailcow + Certbot (Porkbun DNS-01) — Wildcard TLS

This repository issues a **wildcard Let's Encrypt certificate** for a Mailcow
installation using the Porkbun DNS-01 challenge, and drops it into Mailcow's
expected location (`data/assets/ssl/cert.pem` + `key.pem`) as **real files**
(no symlinks).

It contains two files:

- `docker-compose.override.yml` — a `certbot-porkbun` service that requests the
  wildcard cert and mounts Mailcow's `data/assets/ssl` directory as the
  certbot `/etc/letsencrypt` directory.
- `deploy.sh` — the Certbot `--deploy-hook` that copies the renewed
  `fullchain.pem` → `cert.pem` and `privkey.pem` → `key.pem` after each
  issuance/renewal.

---

# Prerequisites

- A working `mailcow-dockerized` installation.
- In `mailcow.conf`, set:

  ```
  SKIP_LETS_ENCRYPT=y
  ```

  This is **required**. Mailcow must not run its own ACME client, or it will
  overwrite the certificate this repo manages.
- Your router forwards ports **80/443 to your reverse proxy**, not to Mailcow.
  (This matters for the autoconfig/autodiscover note below.)

---

# Configuration (`mailcow.conf`)

Mailcow reads its configuration from `mailcow.conf`, and **`mailcow.conf` is
also the file Docker Compose uses for variable substitution** — mailcow sets up
a `.env` symlink (or redirect) that points at `mailcow.conf`. That is why the
override's `${DOMAIN}`, `${PORKBUN_API_KEY}`, etc. resolve: Compose reads them
from `mailcow.conf`.

Add the following to `mailcow.conf` (do **not** create a separate `.env` file —
a real `.env` would shadow the `mailcow.conf` symlink and the stack would lose
all of mailcow's own variables):

```
# Porkbun API Challenge Keys
DOMAIN=*.example.com     #replace with your domain
PORKBUN_API_KEY=your key
PORKBUN_SECRET_API_KEY=your key
CERTBOT_EMAIL=email address
```

`TZ` is already present in `mailcow.conf` (set by `generate_config.sh`); make
sure it is set. `SKIP_LETS_ENCRYPT=y` (see Prerequisites) also lives in
`mailcow.conf`.

---

# How to deploy (what to do with these files)

1. **Place the deploy hook.** Copy `deploy.sh` into Mailcow's certbot config
   directory and make it executable:

   ```bash
   mkdir -p /opt/mailcow-dockerized/data/conf/certbot
   cp deploy.sh /opt/mailcow-dockerized/data/conf/certbot/deploy.sh
   chmod +x /opt/mailcow-dockerized/data/conf/certbot/deploy.sh
   ```

   (Adjust `/opt/mailcow-dockerized` to your Mailcow install path.)

2. **Add the override.** Drop `docker-compose.override.yml` into the Mailcow
   directory (next to `docker-compose.yml`). Mailcow auto-merges overrides, so
   the `certbot-porkbun` service comes up with the stack.

3. **Confirm Mailcow is inert on certs.** Ensure `SKIP_LETS_ENCRYPT=y` is set
   in `mailcow.conf` (see Prerequisites).

4. **Bring up the stack.** From the Mailcow directory:

   ```bash
   docker compose up -d
   ```

   The `certbot-porkbun` container requests `*.example.com`, and the deploy hook
   writes `data/assets/ssl/cert.pem` and `data/assets/ssl/key.pem`.

5. **Load the cert into Mailcow (first run).** Mailcow caches certs in memory,
   so restart the consumers once:

   ```bash
   docker compose restart nginx-mailcow dovecot-mailcow postfix-mailcow
   ```

---

# Why the cert lands in Mailcow's ssl directory

The override mounts Mailcow's certificate directory into the certbot
container:

```yaml
volumes:
  - ./data/assets/ssl:/etc/letsencrypt:rw,z
  - ./data/conf/certbot:/etc/letsencrypt-renewal-hooks:ro,z
```

So inside the container, `/etc/letsencrypt` **is** Mailcow's
`data/assets/ssl`. The deploy hook writes `cert.pem` / `key.pem` there, which
is exactly where Mailcow's nginx, Dovecot, and Postfix read them. No symlinks
are used (`cp -Lf` dereferences the live/ symlink to a real file).

Mailcow serves `cert.pem` for **every** vhost — the web UI, autoconfig, and
autodiscover — plus IMAP/POP/SMTP TLS.

---

# IMPORTANT — autoconfig / autodiscover behind a reverse proxy

Mailcow serves `autoconfig.<domain>` and `autodiscover.<domain>` from its own
`nginx-mailcow` container, and those names are covered by the wildcard cert
**for any request that actually reaches Mailcow's port 443**.

But because your router sends 80/443 to the **reverse proxy** (Nginx Proxy
Manager, Traefik, Caddy, etc.), external clients never hit Mailcow's 443
directly. They hit the proxy, which terminates TLS. If the proxy has no entry
for those two hostnames, the client gets the wrong cert (or a 404 / default
cert), and autoconfig/autodiscover fail.

**You must add both hostnames as proxy hosts in whatever reverse proxy you
use**, each pointing at the Mailcow server and serving the wildcard cert:

| Proxy host              | Forward to            | Scheme  | Port | TLS cert        |
| ----------------------- | --------------------- | ------- | ---- | --------------- |
| `autoconfig.example.com`| `<mail-server-LAN-IP>`| `HTTPS` | `443`| your wildcard   |
| `autodiscover.example.com`| `<mail-server-LAN-IP>`| `HTTPS`| `443`| your wildcard   |

Concrete Nginx Proxy Manager steps:

1. Add a Proxy Host for `autoconfig.example.com`:
   - Scheme: **HTTPS**
   - Forward Hostname / IP: the LAN IP of the Mailcow server
   - Forward Port: **443**
   - SSL: select the wildcard certificate
   - Enable **Force SSL** and **HTTP/2**
2. Repeat for `autodiscover.example.com`.
3. (Optional) Repeat for `mail.example.com` if you expose the Mailcow web UI
   externally.

Use **HTTPS** to the backend, not HTTP. Mailcow's nginx redirects plaintext
(80) to HTTPS (443); pointing the proxy at plaintext with "Force SSL" on
causes a redirect loop. Pointing at `443` over HTTPS avoids it, and the proxy
presents its own valid wildcard to clients while talking to Mailcow internally.

If the reverse proxy is on a **different subnet** than Mailcow, also set in
`mailcow.conf`:

```
TRUSTED_PROXIES=<proxy-LAN-IP>
```

so Mailcow honors `X-Forwarded-For` / `X-Real-IP` (matters for fail2ban and
correct client IP logging).

---

# Renewal caveat

`deploy.sh` copies the new files but does **not** restart Mailcow containers.
After an automatic renewal, Mailcow keeps serving the previous cert from memory
until reloaded. Automate a reload on cert change, e.g. a systemd `path` unit
watching `data/assets/ssl/cert.pem`, or a cron job that restarts
`nginx-mailcow dovecot-mailcow postfix-mailcow` shortly after renewal.

---

# Verify

Check the cert Mailcow is serving (SANs must include `*.example.com`):

```bash
openssl x509 -in /opt/mailcow-dockerized/data/assets/ssl/cert.pem \
  -noout -ext subjectAltName
```

Check what an external client receives (through the reverse proxy):

```bash
openssl s_client -connect autoconfig.example.com:443 \
  -servername autoconfig.example.com 2>/dev/null \
  | openssl x509 -noout -issuer -subject -ext subjectAltName
```

---

# Security notes

- `key.pem` is written with `600` to protect private key material.
- Real files are copied with `cp -Lf` to avoid symlink issues inside Docker.
- The deploy hook exits on first error (`set -e`).
