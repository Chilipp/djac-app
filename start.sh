#!/bin/bash

set -eu

echo "=> Starting bikeWeite"

echo "=> Creating directories"
mkdir -p /run/bikeWeite /run/nginx

echo "=> Get secret key"
if [[ ! -f /app/data/.secret_key ]]; then
    openssl rand -base64 42 > /app/data/.secret_key
fi
export DJANGO_SECRET_KEY=$(</app/data/.secret_key)

# GUNICORN SERVER RELATED SETTINGS
# see https://docs.gunicorn.org/en/stable/design.html#how-many-workers for recommended settings
export GUNICORN_PORT=8080
export GUNICORN_WORKERS=3
export GUNICORN_THREADS=2
export DJANGO_READ_DOT_ENV_FILE="true"


if [ ! -f /app/data/.env ]; then
    echo "==> Copying default environment variables"

    TIMEZONE=$(</etc/timezone)

cat > /app/data/.env << EOF
TIMEZONE=${TIMEZONE}

# prefix used for account related emails
EMAIL_SUBJECT_PREFIX="[bikeWeite] "
EOF
fi

echo "=> Configuring bikeWeite"
cat > /run/bikeWeite/.env << EOF
DEBUG=0

ALLOWED_HOSTS="${CLOUDRON_APP_DOMAIN}"

DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

DATABASE_URL=postgresql://${CLOUDRON_POSTGRESQL_USERNAME}:${CLOUDRON_POSTGRESQL_PASSWORD}@${CLOUDRON_POSTGRESQL_HOST}:${CLOUDRON_POSTGRESQL_PORT}/${CLOUDRON_POSTGRESQL_DATABASE}

CACHE_URL=redis://${CLOUDRON_REDIS_HOST}:${CLOUDRON_REDIS_PORT}/0?client_class=django_redis.client.DefaultClient

# Email Settings, see https://docs.djangoproject.com/en/3.2/ref/settings/#email-host
# Required for email confirmation and password reset (automatically activates if host is set)
EMAIL_URL=smtp+ssl://${CLOUDRON_MAIL_SMTP_USERNAME}:${CLOUDRON_MAIL_SMTP_PASSWORD}@${CLOUDRON_MAIL_SMTP_SERVER}:${CLOUDRON_MAIL_SMTPS_PORT}

SERVER_EMAIL=${CLOUDRON_MAIL_FROM}

SOCIAL_PROVIDERS="allauth.socialaccount.providers.openid_connect"
SOCIALACCOUNT_PROVIDERS={"openid_connect": { "SERVERS": [{ "id": "cloudron", "name": "Cloudron", "server_url": "${CLOUDRON_OIDC_ISSUER}", "APP": { "client_id": "${CLOUDRON_OIDC_CLIENT_ID}", "secret": "${CLOUDRON_OIDC_CLIENT_SECRET}" } }] }}

GUNICORN_MEDIA=0

EOF

cat /app/data/.env >> /run/bikeWeite/.env

echo "==> Migrating database"

# Activate virtual environment
source ${VENV_PATH}/bin/activate

# Initialize Database
python /app/code/bikeWeite/manage.py migrate

echo "=> Changing permissions"
chown -R cloudron:cloudron /app/data /run

echo "=> Starting supervisor"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i bikeWeite
