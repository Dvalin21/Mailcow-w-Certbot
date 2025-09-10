#!/bin/sh
# Reload nginx configuration after certificate renewal /data/conf/certbot/deploy.sh
docker exec mailcowdockerized-nginx-mailcow-1 nginx -s reload
