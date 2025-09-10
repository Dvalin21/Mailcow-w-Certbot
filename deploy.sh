#!/bin/sh
# Reload nginx configuration after certificate renewal
docker exec mailcowdockerized-nginx-mailcow-1 nginx -s reload
