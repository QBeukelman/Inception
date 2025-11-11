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

CERT_DIR="/etc/nginx/certs"
CRT="$CERT_DIR/$DOMAIN.crt"
KEY="$CERT_DIR/$DOMAIN.key"

mkdir -p "$CERT_DIR"

# Check if either CRT or KEY file is missing
if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then

  echo "[nginx] generating self-signed cert for ${DOMAIN}..."

  # -x509		generates a seld signed cert
  # rsa:2048	generate a new 2048-bit RSA key
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$KEY" -out "$CRT" \
	-subj "/CN=${DOMAIN}"
  chmod 600 "$KEY"
  chmod 644 "$CRT"
else
  echo "[nginx] certs already present for ${DOMAIN}"
fi
