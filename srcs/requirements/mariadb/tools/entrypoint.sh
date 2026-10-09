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

escape_sql() {
    printf '%s' "$1" | sed "s/'/''/g"
}

DB_ROOT_PASSWORD=$(escape_sql "$(read_secret /run/secrets/db_root_password)")
DB_PASSWORD=$(escape_sql "$(read_secret /run/secrets/db_password)")
DB_NAME=$(escape_sql "${MYSQL_DATABASE:?MYSQL_DATABASE is required}")
DB_USER=$(escape_sql "${MYSQL_USER:?MYSQL_USER is required}")

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null

    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    temp_pid=$!

    attempts=0
    until mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
            echo "Temporary MariaDB server did not start" >&2
            kill "$temp_pid" 2>/dev/null || true
            exit 1
        fi
        sleep 1
    done

    mariadb --socket=/run/mysqld/mysqld.sock <<-SQL
		CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
		CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
		ALTER USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
		GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
		FLUSH PRIVILEGES;
	SQL

    mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"$DB_ROOT_PASSWORD" shutdown
    wait "$temp_pid"
fi

exec "$@"

