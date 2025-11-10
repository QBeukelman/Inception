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
: "${DB_HOST:?Set DB_HOST in .env}"
: "${DB_NAME:?Set DB_NAME in .env}"
: "${DB_USER:?Set DB_USER in .env}"
: "${DB_PASS:?Set DB_PASS in .env}"
: "${WP_URL:?Set WP_URL in .env}"
: "${WP_TITLE:?Set WP_TITLE in .env}"
: "${WP_ADMIN_USER:?Set WP_ADMIN_USER in .env}"
: "${WP_ADMIN_PASS:?Set WP_ADMIN_PASS in .env}"
: "${WP_ADMIN_EMAIL:?Set WP_ADMIN_EMAIL in .env}"
: "${WP_USER:?Set WP_USER in .env}"
: "${WP_USER_PASS:?Set WP_USER_PASS in .env}"
: "${WP_USER_EMAIL:?Set WP_USER_EMAIL in .env}"

WP_USER_ROLE="${WP_USER_ROLE:-author}"
DOCROOT="/var/www/html"

echo "[wp] Waiting for MariaDB @ $DB_HOST ..."

php -r '
  // Parse DB_Host "host:port"
  // If there is a `:` split into port and host
  [$host,$port] =
  	strpos(getenv("DB_HOST"),":") !==false
	  ? explode(":", getenv("DB_HOST"), 2)
	  : [getenv("DB_HOST"), 3306];

  // Read credentials and database name from environemnt
  $u=getenv("DB_USER");
  $p=getenv("DB_PASS");
  $d=getenv("DB_NAME");

  // Try to connect to MariaDB
  for ($i=0; $i < 100; $i++) {
	
	// Suppress PHP warnings with @
  	$m = @new mysqli($host, $u, $p, $d, (int)$port);
    
	// If no connection error -> DB exists -> exit with success (0)
	if(!$m->connect_errno) exit(0);

	// Print progress message and wait
    fwrite(STDERR,"[wp] DB not ready ($i) ".$m->connect_error.PHP_EOL);
	sleep(1);
  }
  
  // Exit if we have tried 100 times
  exit(1);
'

# If wp-config.php does not exist -> WP is not configured yet
if [ ! -f "${DOCROOT}/wp-config.php" ]; then

  echo ">> Installing WordPress..."

  # If index.php is missing
  # Download it as root to DOCROOT
  [ -f "${DOCROOT}/index.php" ] ||
  	wp core download --path="${DOCROOT}" --allow-root

  # Generate wp-config.php with DB settings from env
  wp config create \
    --path="${DOCROOT}" \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="${DB_HOST}" \
    --skip-check \
    --allow-root

  # If the DB does not contain a WP site -> Install the WP site
  if ! wp core is-installed --path="${DOCROOT}" --allow-root; then
    wp core install \
      --url="${WP_URL}" \
      --title="${WP_TITLE}" \
      --admin_user="${WP_ADMIN_USER}" \
      --admin_password="${WP_ADMIN_PASS}" \
      --admin_email="${WP_ADMIN_EMAIL}" \
      --skip-email \
      --path="${DOCROOT}" \
      --allow-root
  fi
fi

# Add a non-admin user
if wp core is-installed --path="${DOCROOT}" --allow-root; then
  if ! wp user get "$WP_USER" --path="${DOCROOT}" --allow-root >/dev/null 2>&1; then

    echo ">> Creating secondary WP user: ${WP_USER} (${WP_USER_ROLE})"
  
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
      --user_pass="$WP_USER_PASS" \
      --role="$WP_USER_ROLE" \
      --path="${DOCROOT}" --allow-root
  fi
fi

echo "[wp] starting php-fpm..."

exec php-fpm8.2 -F
