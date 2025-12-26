# Mailcow Certbot Porkbun Integration

This repository provides a Mailcow Docker Compose override for automated **Let's Encrypt certificate issuance and renewal** using the Porkbun DNS API. Certificates are automatically deployed to Mailcow's required SSL paths (`cert.pem` and `key.pem`) and picked up by the Watchdog container.

---

## Features

- Automatic certificate issuance via **DNS-01 challenge** using Porkbun API
- Deployment to Mailcow’s `data/assets/ssl` folder with correct permissions
- Compatible with Watchdog for automatic service reloads
- Fully configurable via `mailcow.conf` variables
- Supports propagation adjustment for DNS updates

---

## Prerequisites

- Running [Mailcow Dockerized](https://mailcow.email/) instance
- `mailcow.conf` configured with:
  - `CERTBOT_EMAIL`
- Porkbun API credentials:
  - `PORKBUN_API_KEY`
  - `PORKBUN_SECRET_API_KEY`

---

## Files in this repository

| File | Description |
|------|-------------|
| `docker-compose.override.yml` | Overrides Mailcow Compose to add Certbot Porkbun service |
| `deploy.sh` | Copies renewed `cert.pem` and `key.pem` from Certbot container to Mailcow assets folder with correct permissions |

---

## Setup Instructions

1. **Place override and deploy script**

   Copy `docker-compose.override.yml` and `deploy.sh` into your Mailcow root directory (the same location as `docker-compose.yml` and `mailcow.conf`).

2. **Verify `mailcow.conf` contains required variables**

   ```ini
   CERTBOT_EMAIL=you@example.com
   PORKBUN_API_KEY=xxxxxxxxxxxxxxxx
   PORKBUN_SECRET_API_KEY=xxxxxxxxxxxxxxxx
