#!/usr/bin/env sh

# -------------------------------------------------------------------
# Safety Flags -> Keep init from silently succeeding on failure
#		-e : exit immediatly on any command returning non-zero
#		-u : error on unset varaiables
#		-x : trace every command
# -------------------------------------------------------------------
set -eux

# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------
APP_HOST="${APP_HOST:-wordpress}"
APP_PORT="${APP_PORT:-9000}"

echo "[nginx] Waiting for php-fpm @ ${APP_HOST}:${APP_PORT} ..."

# Wait unitll PHP-FPM is reachable
#		`nc -z host port`	Checks if the TCP port is open
i=0
until nc -z "$APP_HOST" "$APP_PORT"; do
  i=$((i+1))
  if [ "$i" -gt 100 ]; then echo "[nginx] php-fpm wait timed out" >&2; exit 1; fi
  sleep 1
done

echo "[nginx] php-fpm reachable."

# Run the scrip to generate a self-signed certificate
/usr/local/bin/gen_certs.sh

# Test nginx configuration
# Test only -> parses nginx.conf and included files, checks cert file paths, etc.
nginx -t

# Start NGINX in the foreground (no forking)
exec nginx -g 'daemon off;'
