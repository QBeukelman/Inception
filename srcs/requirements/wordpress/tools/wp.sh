#!/usr/bin/env sh
set -euo pipefail

DOCROOT="/var/www/html"

# Only run installation if wp-config.php does not exist
if [ ! -f "${DOCROOT}/wp-config.php" ]; then
  echo ">> Installing WordPress..."

  # If WordPress files are not found, download with WP-CLI
  if [ ! -f "${DOCROOT}/index.php" ]; then
    wp core download --path="${DOCROOT}" --allow-root
  fi

  # Create wp-config.php with env vars
  wp config create \
    --path="${DOCROOT}" \
    --dbname="${WORDPRESS_DB_NAME:-wordpress}" \
    --dbuser="${WORDPRESS_DB_USER:-wpuser}" \
    --dbpass="${WORDPRESS_DB_PASSWORD:-wppass}" \
    --dbhost="${WORDPRESS_DB_HOST:-mariadb}" \
    --skip-check \
    --allow-root

  # First-time install:
  # If database does not have WP site yet, perform wp install
  if ! wp core is-installed --path="${DOCROOT}" --allow-root; then
    wp core install \
      --url="${WP_URL:-http://localhost}" \
      --title="${WP_TITLE:-WordPress}" \
      --admin_user="${WP_ADMIN_USER:-admin}" \
      --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
      --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
      --path="${DOCROOT}" \
      --allow-root
  fi
fi

# Make sure PHP-FPM user can write
chown -R www-data:www-data "${DOCROOT}"

# Start PHP-FPM (FastCGI Process Manager) in foreground
echo ">> Starting php-fpm..."
exec php-fpm -F
