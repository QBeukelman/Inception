#!/usr/bin/env sh
set -eu
: "${DOMAIN:?DOMAIN must be set}"

envsubst '$DOMAIN' \
  </etc/nginx/templates/default.conf.template \
  >/etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
