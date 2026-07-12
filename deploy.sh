#!/bin/sh
set -e

# Certbot automatically provides the $RENEWED_LINEAGE variable pointing to the correct /live/ path.
TARGET_DIR="/etc/letsencrypt"

echo "[certbot] Deploying Mailcow certificate from $RENEWED_LINEAGE..."

# -L dereferences the symlink, copying the actual file.
cp -Lf "$RENEWED_LINEAGE/fullchain.pem" "$TARGET_DIR/cert.pem"
cp -Lf "$RENEWED_LINEAGE/privkey.pem" "$TARGET_DIR/key.pem"

# Mailcow warning: If Nginx/Postfix fail to read the key, change 600 to 640 or 644.
chmod 644 "$TARGET_DIR/cert.pem"
chmod 600 "$TARGET_DIR/key.pem"

echo "[certbot] Certificate copied successfully to Mailcow assets."
