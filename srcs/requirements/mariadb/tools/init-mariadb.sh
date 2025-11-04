
#!/usr/bin.env bash

# Fail fast and do not hide errors
set -Eeuo pipefail

# Read env
: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD}"
: "${MYSQL_DATABASE:=wordpress}"
: "${MYSQL_USER:=wpuser}"
: "${MYSQL_PASSWORD:=wp-pass}"

