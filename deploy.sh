#!/bin/sh
set -e

DOMAIN="$(echo "$RENEWED_DOMAINS" | awk '{print $1}')"
LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
TARGET_DIR="/etc/letsencrypt"

echo "[certbot] Deploying certificate for ${DOMAIN} to Mailcow..."

# Mailcow requires:
# - cert.pem  -> fullchain.pem
# - key.pem   -> privkey.pem
# NO symlinks, real files only

cp -L "${LIVE_DIR}/fullchain.pem" "${TARGET_DIR}/cert.pem"
cp -L "${LIVE_DIR}/privkey.pem"   "${TARGET_DIR}/key.pem"

# Permissions Mailcow expects
chmod 600 "${TARGET_DIR}/key.pem"
chmod 644 "${TARGET_DIR}/cert.pem"

echo "[certbot] Mailcow certificate deployment complete."
