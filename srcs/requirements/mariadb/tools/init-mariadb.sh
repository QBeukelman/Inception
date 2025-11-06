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
: "${MARIADB_DATABASE:=wordpress}"
: "${MARIADB_USER:=qbeukelm}"
: "${MARIADB_PASSWORD:=1234}"

# Make runtime directories and permissions
mkdir -p /run/mysqld

# Change ownership of files
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# First time init

if [ ! -d /var/lib/mysql/mysql ]; then
  if command -v mariadb-install-db >/dev/null 2>&1; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null
  else
    mysql_install_db --user=mysql --ldata=/var/lib/mysql >/dev/null
  fi

  mysqld --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  for i in $(seq 1 30); do
    [ -S /run/mysqld/mysqld.sock ] && break
    sleep 1
  done

  echo "[mariadb] securing and creating DB/user..."

  mysql --protocol=socket -uroot -e \
    "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

  cat >/tmp/init.sql <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
  rm -f /tmp/init.sql

  echo "[mariadb] stopping temporary server..."
  mysqladmin --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
  wait "$pid"
fi

echo "[mariadb] launching server..."
exec gosu mysql "$@"
