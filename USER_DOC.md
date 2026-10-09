# Inception User Guide

## Services

The stack provides a WordPress website over HTTPS. NGINX receives browser traffic on
port 443, forwards PHP requests to WordPress/PHP-FPM, and serves static files. MariaDB
stores the site database. Only NGINX is accessible from outside the Docker network.

## Start and stop

From the repository root:

```sh
make          # first setup, build, and start
make stop     # temporarily stop containers
make start    # restart existing containers
make down     # remove containers and network, preserving data
```

## Access

Add the domain from `srcs/.env` to the machine's `/etc/hosts`, pointing it to the VM
IP. Browse to `https://<login>.42.fr`. The certificate is self-signed, so a browser
warning is expected. The administration panel is at
`https://<login>.42.fr/wp-admin/`.

## Credentials

Usernames and emails are configured in `srcs/.env`. Passwords are generated on the
first `make` invocation and stored in ignored files:

- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`
- `secrets/db_password.txt`
- `secrets/db_root_password.txt`

Keep these files private and restrict their permissions. To rotate a WordPress password,
update the secret and run WP-CLI in the container, or change it from the WordPress
profile. Merely replacing a secret does not rewrite an already initialized database.

## Health checks and troubleshooting

```sh
make ps
make logs
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs nginx
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs wordpress mariadb
curl -kI https://<login>.42.fr
```

All three services should be running; MariaDB and WordPress should report healthy. If
a service fails, inspect its logs first. Confirm that port 443 is free, the data
directories exist, secrets are non-empty, and the domain resolves to the VM.

