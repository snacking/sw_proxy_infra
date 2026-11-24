#!/usr/bin/env bash
# The release symlink bind mount must be recreated after every application update.
set -euo pipefail
cd "$(dirname "$0")/.."
test -x /opt/lisw-panel/current/panel
test -s /etc/lisw-panel/database.json
docker compose config -q
docker compose up -d --no-deps --force-recreate panel
