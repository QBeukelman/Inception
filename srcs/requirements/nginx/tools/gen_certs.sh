#!/usr/bin/env sh

# -------------------------------------------------------------------
# Safety Flags -> Keep init from silently succeeding on failure
#		-e : exit immediatly on any command returning non-zero
#		-u : error on unset varaiables
#		-x : trace every command
# -------------------------------------------------------------------
set -eux

# -------------------------------------------------------------------
# Read environment variables
# -------------------------------------------------------------------
: "${DOMAIN:?DOMAIN must be set in environment}"

SECRETS_DIR="/etc/nginx/certs"
SECRET_CRT="$SECRETS_DIR/$DOMAIN.crt"
SECRET_KEY="$SECRETS_DIR/$DOMAIN.key"

# Check if either SECRET_CRT or SECRET_KEY file is missing
if [ ! -f "$SECRET_CRT" ] || [ ! -f "$SECRET_KEY" ]; then

  echo "[nginx] generating self-signed cert for ${DOMAIN}..."

  # -x509		generates a seld signed cert
  # rsa:2048	generate a new 2048-bit RSA key
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$SECRET_KEY" -out "$SECRET_CRT" \
	-subj "/CN=${DOMAIN}"
  chmod 600 "$SECRET_KEY"
  chmod 644 "$SECRET_CRT"
else
  echo "[nginx] certs already present for ${DOMAIN}"
fi
