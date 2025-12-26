#!/bin/sh
set -e

DOMAIN="$(echo "$RENEWED_DOMAINS" | awk '{print $1}')"
LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
TARGET_DIR="/etc/letsencrypt"

echo "[certbot] Deploying certificate for ${DOMAIN} to Mailcow..."

# Copy real files (NO symlinks)
cp -L "${LIVE_DIR}/cert.pem"      "${TARGET_DIR}/cert.pem"
cp -L "${LIVE_DIR}/privkey.pem"   "${TARGET_DIR}/key.pem"
cp -L "${LIVE_DIR}/chain.pem"     "${TARGET_DIR}/chain.pem"
cp -L "${LIVE_DIR}/fullchain.pem" "${TARGET_DIR}/fullchain.pem"

# Permissions Mailcow expects
chmod 600 "${TARGET_DIR}/key.pem"
chmod 644 "${TARGET_DIR}/cert.pem" \
           "${TARGET_DIR}/chain.pem" \
           "${TARGET_DIR}/fullchain.pem"

echo "[certbot] Mailcow certificate deployment complete."
