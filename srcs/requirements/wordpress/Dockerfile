FROM debian:12-slim

ARG WP_CLI_VERSION=2.12.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl default-mysql-client libfcgi-bin \
       php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
       php8.2-mbstring php8.2-xml php8.2-zip \
    && curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
       -o /usr/local/bin/wp \
    && chmod 755 /usr/local/bin/wp \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/php /var/www/html /usr/src/wordpress \
    && wp core download --allow-root --path=/usr/src/wordpress --version=6.8.3 --locale=en_US

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && chown -R www-data:www-data /var/www/html /usr/src/wordpress

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm8.2", "-F"]
