#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T nginx-fake nginx -t
docker compose exec -T nginx-fake nginx -s reload
# Hysteria loads its certificate at startup; refresh it after renewal.
docker compose restart hysteria
