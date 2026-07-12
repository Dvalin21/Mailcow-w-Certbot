---

# Mailcow + Certbot Deployment Script

This repository provides a **Certbot deploy hook script** (`deploy.sh`) designed to copy renewed Let's Encrypt certificates into a Mailcow installation in the format Mailcow expects.

Mailcow requires **real certificate files (not symlinks)** placed in a specific location. This script ensures certificates are copied correctly after renewal.

---

# Purpose

When Certbot renews a certificate, it normally updates files inside:

```
/etc/letsencrypt/live/<domain>/
```

However, Mailcow expects:

* `cert.pem`
* `key.pem`

as **actual files (not symlinks)** located in:

```
/etc/letsencrypt/
```

This script:

* Detects the renewed domain
* Copies:

  * `fullchain.pem` → `cert.pem`
  * `privkey.pem` → `key.pem`
* Forces correct file permissions:

  * `key.pem` → `600`
  * `cert.pem` → `644`

---

# Directory Structure (IMPORTANT)

The script **must be placed inside Mailcow’s Certbot configuration directory**:

```
/data/conf/certbot/
```

If the directory does not exist, create it:

```bash
mkdir -p /data/conf/certbot
```

Then place the script as:

```
/data/conf/certbot/deploy.sh
```

Make it executable:

```bash
chmod +x /data/conf/certbot/deploy.sh
```

---

# How the Script Works

When Certbot renews a certificate, it provides environment variables including:

```
$RENEWED_DOMAINS
```

The script:

1. Extracts the primary domain:

   ```sh
   DOMAIN="$(echo "$RENEWED_DOMAINS" | awk '{print $1}')"
   ```

2. Defines:

   ```sh
   LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
   TARGET_DIR="/etc/letsencrypt"
   ```

3. Copies real files (no symlinks):

   ```sh
   cp -L "${LIVE_DIR}/fullchain.pem" "${TARGET_DIR}/cert.pem"
   cp -L "${LIVE_DIR}/privkey.pem" "${TARGET_DIR}/key.pem"
   ```

4. Applies required permissions:

   ```sh
   chmod 600 "${TARGET_DIR}/key.pem"
   chmod 644 "${TARGET_DIR}/cert.pem"
   ```
5. Place the following in your mailcow.conf
   ```
   # Porkbun API Challenge Keys
   DOMAIN=*.example.com     #replace with your domain
   PORKBUN_API_KEY=your key
   PORKBUN_SECRET_API_KEY=your key
   CERTBOT_EMAIL=email address
   ```
---

# Integration with Mailcow

Mailcow automatically looks for:

```
/etc/letsencrypt/cert.pem
/etc/letsencrypt/key.pem
```

This script ensures those files are always updated after renewal.

No symbolic links are used.

---

# How to Use With Certbot

You must configure Certbot to use this script as a **deploy hook**.

Example:

```bash
certbot certonly \
  --deploy-hook "/data/conf/certbot/deploy.sh"
```

Or if using renewal configuration, ensure:

```
deploy_hook = /data/conf/certbot/deploy.sh
```

After a renewal event, Certbot will automatically execute the script.

---

# Permissions & Requirements

* Certbot must be installed and functional.
* The script must run with permission to:

  * Read `/etc/letsencrypt/live/<domain>/`
  * Write to `/etc/letsencrypt/`
* Mailcow must be configured to use certificates from `/etc/letsencrypt/`.

---

# What This Script Does NOT Do

* It does not restart Mailcow containers.
* It does not validate DNS or ACME challenges.
* It does not manage multiple certificate targets.
* It does not handle error logging beyond shell `set -e`.

If Mailcow requires container reloads after certificate changes, that logic must be added separately.

---

# Security Notes

* `key.pem` is restricted to `600` to protect private key material.
* Real files are copied using `cp -L` to avoid symlink exposure issues.
* Script exits immediately on error (`set -e`).

---
