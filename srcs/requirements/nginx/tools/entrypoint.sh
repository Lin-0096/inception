#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

sed "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" \
    /etc/nginx/templates/default.conf.template \
    > /etc/nginx/conf.d/default.conf

if [ ! -s /etc/nginx/ssl/inception.crt ] || [ ! -s /etc/nginx/ssl/inception.key ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=42/OU=Inception/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME"
fi

nginx -t
exec "$@"

