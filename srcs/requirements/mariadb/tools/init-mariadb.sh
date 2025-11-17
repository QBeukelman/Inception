#!/usr/bin/env sh
set -eux

: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD}"
: "${MARIADB_DATABASE:?Missing MARIADB_DATABASE}"
: "${MARIADB_USER:?Missing MARIADB_USER}"
: "${MARIADB_PASSWORD:?Missing MARIADB_PASSWORD}"

DATADIR="/data"
SOCKET_DIR="/run/mysqld"
SOCKET="$SOCKET_DIR/mysqld.sock"

mkdir -p "$SOCKET_DIR" "$DATADIR"
chown -R mysql:mysql "$SOCKET_DIR" "$DATADIR"

first_boot=0
if [ ! -d "$DATADIR/mysql" ]; then
    first_boot=1
    echo "[mariadb] First boot, initializing datadir..."
    mariadb-install-db \
        --datadir="$DATADIR" \
        --user=mysql \
        --skip-test-db \
        --auth-root-authentication-method=normal
fi

echo "[mariadb] Starting temporary server..."
gosu mysql mysqld \
    --datadir="$DATADIR" \
    --skip-networking \
    --socket="$SOCKET" &
pid="$!"

# Wait for mysqld startup
echo "[mariadb] Waiting for socket..."
for i in $(seq 1 30); do
    if [ -S "$SOCKET" ]; then
        echo "[mariadb] Socket OK"
        break
    fi

    # FAIL FAST if mysqld died
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "[mariadb] ERROR: Temporary server crashed!"
        tail -n 50 /var/log/mysql/error.log || true
        exit 1
    fi

    sleep 1
done

if [ ! -S "$SOCKET" ]; then
    echo "[mariadb] ERROR: mysqld did not create socket!"
    exit 1
fi

if [ "$first_boot" -eq 1 ]; then
    echo "[mariadb] Setting root password..."
    mysql --protocol=socket -u root -e \
      "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
fi

echo "[mariadb] Creating user/database..."
cat >/tmp/init.sql <<EOF
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

mysql --protocol=socket -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
rm -f /tmp/init.sql

mysqladmin --protocol=socket --socket="$SOCKET" -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"

echo "[mariadb] Starting main server..."
exec gosu mysql mysqld --datadir="$DATADIR" --bind-address=0.0.0.0
