#!/usr/bin/env bash
# Deploy / update Taskly API ke server.
#
# Dijalankan DARI laptop, bukan di server:
#   ./backend/deploy/deploy.sh
#
# Asumsi: host SSH bernama "taskly" sudah ada di ~/.ssh/config.

set -euo pipefail

HOST=${HOST:-taskly}
REMOTE_DIR=/opt/taskly-api
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> upload kode ke $HOST:$REMOTE_DIR"
# node_modules dan .env tidak ikut dikirim: yang pertama di-install di server,
# yang kedua berisi password dan hanya ada di server.
tar -C "$SRC_DIR" -czf - \
    --exclude=node_modules \
    --exclude=.env \
    package.json src db deploy \
  | ssh "$HOST" "sudo -n tar -C $REMOTE_DIR -xzf - && sudo -n chown -R taskly:taskly $REMOTE_DIR"

echo "==> npm install"
ssh "$HOST" "sudo -n -u taskly -H sh -c 'cd $REMOTE_DIR && npm install --omit=dev --no-audit --no-fund 2>&1 | tail -3'"

echo "==> terapkan schema (idempoten)"
# Dijalankan sebagai user postgres karena file di /opt hanya bisa dibaca taskly.
ssh "$HOST" 'set -e
  DBPASS=$(sudo -n grep -E "^DB_PASSWORD=" /opt/taskly-api/.env | cut -d= -f2-)
  sudo -n cp /opt/taskly-api/db/schema.sql /tmp/taskly-schema.sql
  sudo -n chmod 644 /tmp/taskly-schema.sql
  PGPASSWORD=$DBPASS psql -h 127.0.0.1 -U taskly -d taskly -v ON_ERROR_STOP=1 \
    -f /tmp/taskly-schema.sql >/dev/null
  echo "schema ok"'

echo "==> restart service"
ssh "$HOST" 'sudo -n systemctl restart taskly-api && sleep 2 && sudo -n systemctl is-active taskly-api'

echo "==> health check"
ssh "$HOST" 'curl -s -m 10 http://127.0.0.1:3000/api/health'

echo
echo "Selesai."
