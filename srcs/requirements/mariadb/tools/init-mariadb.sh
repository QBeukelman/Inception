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

# -------------------------------------------------------------------
# First time init
# -------------------------------------------------------------------
# If the internal MariaDB system table directory does NOT exist,
# then the data directory has not been initalized yet.
first_boot=0
if [ ! -d /var/lib/mysql/mysql ]; then
  first_boot=0

  # Check if the `mariadb-install-db` program exists in PATH
  # 	`command -v` prints its path id found
  if command -v mariadb-install-db >/dev/null 2>&1; then
    # Initalize the MariaDB data directory with:
	# 		--user=mysql	runs mysql user.
	#		--datadir=...	where to place the files.
	#		--skip-test-db	don't create a test database.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null
  else
	# Fallback environment using MySQL tool
    mysql_install_db --user=mysql --ldata=/var/lib/mysql >/dev/null
  fi
fi

# Start a TEMP server to run SQL
# Why temp? We want to initialize the DB before we expose it.
# Only once complete, can we start the real server in the foreground with networking.
# 		`gosu mysql`	drop root privileges and run as mysql user.
#		`mysql`d``		run as daemon / in background.
gosu mysql mysqld --skip-networking --socket=/run/mysqld/mysqld.sock &
pid="$!"

# Wait for socket
# 		`-S` 	checks "is this a socket?"
for i in $(seq 1 30); do
  [ -S /run/mysqld/mysqld.sock ] && break
  sleep 1
done

# Ensure root password
if [ "$first_boot" -eq 1 ]; then
  mysql --protocal=socket \			# Connect via local socket
  		--unroot \					# Login as `root` user
		-e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; \
			FLUSH PRIVILEGES;"		# Set password and reload privileges table
fi

# Create DB
#		open a `here-doc` << SQL
cat >/tmp/init.sql <<SQL

CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`   # Create the app database if it doesn't exist yet
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;     # Use full Unicode (utf8mb4) with a sensible collation

CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%'         # Ensure an app user exists, allowed from any host ('%')
  IDENTIFIED BY '${MARIADB_PASSWORD}';                  # Set its password

ALTER USER '${MARIADB_USER}'@'%'                        # If user already exists, reapply the password
  IDENTIFIED BY '${MARIADB_PASSWORD}';

-- Make sure user exists in host and has correct password
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.*       # Grant full privileges on the app DB only
  TO '${MARIADB_USER}'@'%';                             # to MariaDB User user

FLUSH PRIVILEGES;                                       # Reload grant tables immediately
SQL                                                     # End of here-doc

# Run the MariaDB client, and login as root
# 		Redirect the SQL file to the clients stdin, executing its rules
mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
rm -f /tmp/init.sql

# Stop temp SQL server and launch real one
mysqladmin --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"

echo "[mariadb] launching server..."

# Execute servier
#		`gosu`	like sudo
#		`$@`	forward and expand all script arguments to docker
#		expands to `exec gosu mysql mysqld --datadir /data --skip-networking...`
exec gosu mysql "$@"
