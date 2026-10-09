#!/bin/sh
set -eu

read_secret() {
    value=$(cat "$1")
    if [ -z "$value" ]; then
        echo "Secret $1 is empty" >&2
        exit 1
    fi
    printf '%s' "$value"
}

DB_PASSWORD=$(read_secret /run/secrets/db_password)
ADMIN_PASSWORD=$(read_secret /run/secrets/wp_admin_password)
USER_PASSWORD=$(read_secret /run/secrets/wp_user_password)

if printf '%s' "$WP_ADMIN_USER" | grep -Eqi 'admin(istrator)?'; then
    echo "WP_ADMIN_USER must not contain admin or administrator" >&2
    exit 1
fi

if [ ! -f wp-load.php ]; then
    cp -a /usr/src/wordpress/. /var/www/html/
fi

if [ ! -f wp-config.php ]; then
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306 \
        --dbcharset=utf8mb4 \
        --skip-check
fi

attempts=0
until wp db check --allow-root --quiet; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 30 ]; then
        echo "MariaDB did not become ready" >&2
        exit 1
    fi
    sleep 2
done

if ! wp core is-installed --allow-root; then
    wp core install --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
fi

if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --role=author --user_pass="$USER_PASSWORD"
fi

wp option update home "https://$DOMAIN_NAME" --allow-root
wp option update siteurl "https://$DOMAIN_NAME" --allow-root
chown -R www-data:www-data /var/www/html

exec "$@"
