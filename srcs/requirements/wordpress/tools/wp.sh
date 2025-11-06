#!/usr/bin/env sh
set -eu

DOCROOT="/var/www/html"

# --- Read env with fallbacks (supports both DB_* and WP_DB_*) ---
DB_HOST="${DB_HOST:-${WP_DB_HOST:-mariadb:3306}}"
DB_NAME="${DB_NAME:-${WP_DB_NAME:-wordpress}}"
DB_USER="${DB_USER:-${WP_DB_USER:-qbeukelm}}"
DB_PASS="${DB_PASS:-${WP_DB_PASSWORD:-wp-pass}}"

echo "[wp] Waiting for MariaDB @ $DB_HOST ..."
php -r '
  $h=getenv("DB_HOST"); $u=getenv("DB_USER"); $p=getenv("DB_PASS"); $d=getenv("DB_NAME");
  if (strpos($h, ":") === false) { $port = 3306; } else { [$h,$port] = explode(":", $h, 2); $port=(int)$port; }
  for ($i=0; $i<100; $i++) {
    $m=@new mysqli($h,$u,$p,$d,$port);
    if (!$m->connect_errno) { exit(0); }
    fwrite(STDERR, "[wp] DB not ready ($i) errno={$m->connect_errno} error={$m->connect_error}\n");
    sleep(1);
  }
  exit(1);
'

# One-time install if needed
if [ ! -f "${DOCROOT}/wp-config.php" ]; then
  echo ">> Installing WordPress..."
  [ -f "${DOCROOT}/index.php" ] || wp core download --path="${DOCROOT}" --allow-root
  wp config create \
    --path="${DOCROOT}" \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="${DB_HOST}" \
    --skip-check \
    --allow-root
  if ! wp core is-installed --path="${DOCROOT}" --allow-root; then
    wp core install \
      --url="${WP_URL:-http://localhost}" \
      --title="${WP_TITLE:-My Site}" \
      --admin_user="${WP_ADMIN_USER:-admin}" \
      --admin_password="${WP_ADMIN_PASS:-adminpass}" \
      --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
      --skip-email \
      --path="${DOCROOT}" \
      --allow-root
  fi
fi

echo "[wp] starting php-fpm..."
exec php-fpm8.2 -F
