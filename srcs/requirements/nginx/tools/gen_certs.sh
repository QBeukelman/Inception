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
	-subj "/CN=qbeukelm.42.fr" \
	-keyout /etc/nginx/certs/qbeukelm.42.fr.key \
	-out    /etc/nginx/certs/qbeukelm.42.fr.crt
else
  echo "[nginx] certs already present for $DOMAIN"
fi
