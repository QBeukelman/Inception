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
: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD}"
: "${MARIADB_DATABASE:?Set MARIADB_DATABASE in .env}"
: "${MARIADB_USER:?Set MARIADB_USER in .env}"
: "${MARIADB_PASSWORD:?Set MARIADB_PASSWORD in .env}"

# Make runtime directories and ownership
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# First time init
first_boot=0
if [ ! -d /var/lib/mysql/mysql ]; then
  first_boot=0
  if command -v mariadb-install-db >/dev/null 2>&1; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null
  else
    mysql_install_db --user=mysql --ldata=/var/lib/mysql >/dev/null
  fi
fi

# Start a temp server to run SQL
gosu mysql mysqld --skip-networking --socket=/run/mysqld/mysqld.sock &
pid="$!"

# Wait for socket
for i in $(seq 1 30); do
  [ -S /run/mysqld/mysqld.sock ] && break
  sleep 1
done

# Ensure root password
if [ "$first_boot" -eq 1 ]; then
  mysql --protocal=socket -unroot -e \
	"ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
fi

# Create DB
cat >/tmp/init.sql <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
ALTER USER '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';

-- Make sure user exists in host and has correct password
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.*
 TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
rm -f /tmp/init.sql

# Stop temp SQL server and launch real one
mysqladmin --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"

echo "[mariadb] launching server..."
exec gosu mysql "$@"
