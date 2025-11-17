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

DATADIR="/data"
SOCKET_DIR="/run/mysqld"
SOCKET="${SOCKET_DIR}/mysqld.sock"

# Make runtime directories and ownership
mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}"

mkdir -p "${DATADIR}"
chown -R mysql:mysql "${DATADIR}"

# -------------------------------------------------------------------
# First time init
# -------------------------------------------------------------------
# If the internal MariaDB system table directory does NOT exist,
# then the data directory has not been initalized yet.
first_boot=0
if [ ! -d "$DATADIR/mysql" ]; then
  
  first_boot=1
  echo "[mariadb] First boot: initializing datadir at $DATADIR"

  # Check if the `mariadb-install-db` program exists in PATH
  # 	`command -v` prints its path id found
  if command -v mariadb-install-db >/dev/null 2>&1; then
    # Initalize the MariaDB data directory with:
	# 		--user=mysql	runs mysql user.
	#		--datadir=...	where to place the files.
	#		--skip-test-db	don't create a test database.
    mariadb-install-db --datadir="$DATADIR" --user=mysql --auth-root-authentication-method=normal >/dev/null
  else
	# Fallback environment using MySQL tool
    mysql_install_db --user=mysql --ldata="$DATADIR" >/dev/null
  fi
fi

# Start a TEMP server to run SQL
# Why temp? We want to initialize the DB before we expose it.
# Only once complete, can we start the real server in the foreground with networking.
# 		`gosu mysql`	drop root privileges and run as mysql user.
#		`mysql`d``		run as daemon / in background.
echo "[mariadb] Starting temporary server"
gosu mysql mysqld \
  --datadir="$DATADIR" \
  --skip-networking \
  --socket="$SOCKET" &
pid="$!"

# Wait for socket
# 		`-S` 	checks "is this a socket?"
for i in $(seq 1 30); do
  [ -S "$SOCKET" ] && break
  sleep 1
done

# Ensure root password
if [ "$first_boot" -eq 1 ]; then
  mysql --protocol=socket -u root -e \
	"ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
fi

# Create DB
#		open a `here-doc` << SQL
cat >/tmp/init.sql <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
ALTER USER '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.*
 TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

# Run the MariaDB client, and login as root
# 		Redirect the SQL file to the clients stdin, executing its rules
mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
rm -f /tmp/init.sql

# Stop temp SQL server and launch real one
mysqladmin --protocol=socket --socket="$SOCKET" -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"

echo "[mariadb] launching server..."

# Execute servier
#		`gosu`	like sudo
#		`$@`	forward and expand all script arguments to docker
#		expands to `exec gosu mysql mysqld --datadir /data --skip-networking...`
exec gosu mysql mysqld \
  --datadir="$DATADIR" \
  --bind-address=0.0.0.0
