#!/usr/bin/env sh

set -eu

: "${DOMAIN:?DOMAIN must be set in environment}"

CERT_DIR="/etc/nginx/certs"
CRT="$CERT_DIR/$DOMAIN.crt"
KEY="$CERT_DIR/$DOMAIN.key"

mkdir -p "$CERT_DIR"

if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
  echo "[nginx] generating self-signed cert for $DOMAIN ..."
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/CN=$DOMAIN"
else
  echo "[nginx] certs already present for $DOMAIN"
fi
