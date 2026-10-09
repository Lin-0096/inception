# Inception Developer Guide

## Set up from scratch

Use a Linux VM with Docker Engine, the Compose plugin, Make, and OpenSSL. Clone the
repository, edit `srcs/.env`, and set `LOGIN` and `DOMAIN_NAME` to the 42 login. The
Makefile creates `/home/<login>/data/{mariadb,wordpress}` and four random secret files.
If the host user cannot create `/home/<login>/data`, create and chown it once with sudo.

Do not commit `secrets/*.txt`. To provide values manually, create each file listed in
`srcs/docker-compose.yml` with mode 600 and no trailing requirement beyond a non-empty
value.

## Build and launch

```sh
make check
make
make ps
```

`make` runs setup, builds the three local images, and starts Compose in detached mode.
The image repositories and services share the names `nginx`, `wordpress`, and
`mariadb`; the images use the explicit `inception` tag instead of the prohibited
implicit `latest` tag.

## Manage the stack

```sh
make logs
make restart
make down
make clean
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec wordpress sh
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec mariadb mariadb -uroot -p
```

No entrypoint uses an artificial infinite loop. Each script ends with `exec` so NGINX,
PHP-FPM, or MariaDB becomes PID 1 and receives Docker signals directly. Compose uses a
dedicated bridge network; service names provide internal DNS resolution.

## Persistence

The Compose named volumes use the local driver with bind-backed host paths:

- `inception_mariadb_data` -> `/home/<login>/data/mariadb`
- `inception_wordpress_data` -> `/home/<login>/data/wordpress`

`make down` and `make clean` preserve both directories. Removing persistent data is a
deliberate administrative operation and is therefore not automated by the Makefile.
Back up both directories together for a consistent site backup.

## Initialization flow

On an empty database volume, MariaDB initializes its system tables, creates the
WordPress database and application user, sets the root password, stops the temporary
bootstrap server, and finally execs the production server. On an empty site volume,
WordPress downloads the pinned core version, creates `wp-config.php`, installs the site,
and creates a non-administrator user. Later starts skip destructive initialization.
