#!/usr/bin/env sh
set -eux

APP_HOST="${APP_HOST:-wordpress}"
APP_PORT="${APP_PORT:-9000}"

echo "[nginx] Waiting for php-fpm @ ${APP_HOST}:${APP_PORT} ..."
i=0
until nc -z "$APP_HOST" "$APP_PORT"; do
  i=$((i+1))
  if [ "$i" -gt 100 ]; then echo "[nginx] php-fpm wait timed out" >&2; exit 1; fi
  sleep 1
done
echo "[nginx] php-fpm reachable."

/usr/local/bin/gen_certs.sh

# Test nginx configuration
nginx -t

exec nginx -g 'daemon off;'
