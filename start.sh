#!/bin/bash

set -eu

echo "=> Starting Tandoor"

echo "=> Creating directories"
mkdir -p /run/tandoor /run/nginx \
        /app/data/data/staticfiles \
        /app/data/data/mediafiles

echo "=> Get secret key"
if [[ ! -f /app/data/.secret_key ]]; then
    openssl rand -base64 42 > /app/data/.secret_key
fi
export SECRET_KEY=$(</app/data/.secret_key)

# GUNICORN SERVER RELATED SETTINGS
# see https://docs.gunicorn.org/en/stable/design.html#how-many-workers for recommended settings
export GUNICORN_PORT=8080
export GUNICORN_WORKERS=3
export GUNICORN_THREADS=2


if [ ! -f /app/data/.env ]; then
    echo "==> Copying default environment variables"

    TIMEZONE=$(</etc/timezone)

cat > /app/data/.env << EOF
TIMEZONE=${TIMEZONE}

# prefix used for account related emails
ACCOUNT_EMAIL_SUBJECT_PREFIX="[Tandoor Recipes] "

# the default value for the user preference 'fractions' (enable/disable fraction support)
# default: disabled=0
FRACTION_PREF_DEFAULT=0

# the default value for the user preference 'comments' (enable/disable commenting system)
# default comments enabled=1
COMMENT_PREF_DEFAULT=1

# Users can set a amount of time after which the shopping list is refreshed when they are in viewing mode
# This is the minimum interval users can set. Setting this to low will allow users to refresh very frequently which
# might cause high load on the server. (Technically they can obviously refresh as often as they want with their own scripts)
SHOPPING_MIN_AUTOSYNC_INTERVAL=5

# Default for user setting sticky navbar
# STICKY_NAV_PREF_DEFAULT=1

# Default settings for spaces, apply per space and can be changed in the admin view
# SPACE_DEFAULT_MAX_RECIPES=0 # 0=unlimited recipes
# SPACE_DEFAULT_MAX_USERS=0 # 0=unlimited users per space
# SPACE_DEFAULT_MAX_FILES=0 # Maximum file storage for space in MB. 0 for unlimited, -1 to disable file upload.
# SPACE_DEFAULT_ALLOW_SHARING=1 # Allow users to share recipes with public links

# allow people to create accounts on your application instance (without an invite link)
# when unset: 0 (false)
# ENABLE_SIGNUP=0

# If signup is enabled you might want to add a captcha to it to prevent spam
# HCAPTCHA_SITEKEY=
# HCAPTCHA_SECRET=

# if signup is enabled you might want to provide urls to data protection policies or terms and conditions
# TERMS_URL=
# PRIVACY_URL=
# IMPRINT_URL=

# enable serving of prometheus metrics under the /metrics path
# ATTENTION: view is not secured (as per the prometheus default way) so make sure to secure it
# trough your web server (or leave it open of you dont care if the stats are exposed)
# ENABLE_METRICS=0

# by default SORT_TREE_BY_NAME is disabled this will store all Keywords and Food in the order they are created
# enabling this setting makes saving new keywords and foods very slow, which doesn't matter in most usecases.
# however, when doing large imports of recipes that will create new objects, can increase total run time by 10-15x
# Keywords and Food can be manually sorted by name in Admin
# This value can also be temporarily changed in Admin, it will revert the next time the application is started
# This will be fixed/changed in the future by changing the implementation or finding a better workaround for sorting
# SORT_TREE_BY_NAME=0

# Enables exporting PDF (see export docs)
# Disabled by default, uncomment to enable
# ENABLE_PDF_EXPORT=1

# Recipe exports are cached for a certain time by default, adjust time if needed
# EXPORT_FILE_CACHE_DURATION=600

EOF
fi

echo "=> Configuring Tandoor"
cat > /run/tandoor/.env << EOF
DEBUG=0
SQL_DEBUG=0
DEBUG_TOOLBAR=0

ALLOWED_HOSTS="${CLOUDRON_APP_DOMAIN}"

SECRET_KEY=${SECRET_KEY}

DB_ENGINE=django.db.backends.postgresql
POSTGRES_HOST=${CLOUDRON_POSTGRESQL_HOST}
POSTGRES_PORT=${CLOUDRON_POSTGRESQL_PORT}
POSTGRES_USER=${CLOUDRON_POSTGRESQL_USERNAME}
POSTGRES_PASSWORD=${CLOUDRON_POSTGRESQL_PASSWORD}
POSTGRES_DB=${CLOUDRON_POSTGRESQL_DATABASE}

# If base URL is something other than just / (you are serving a subfolder in your proxy for instance http://recipe_app/recipes/)
# Be sure to not have a trailing slash: e.g. '/recipes' instead of '/recipes/'
# SCRIPT_NAME=/recipes

# If staticfiles are stored at a different location uncomment and change accordingly, MUST END IN /
# this is not required if you are just using a subfolder
# This can either be a relative path from the applications base path or the url of an external host
STATIC_URL=/static/

# If mediafiles are stored at a different location uncomment and change accordingly, MUST END IN /
# this is not required if you are just using a subfolder
# This can either be a relative path from the applications base path or the url of an external host
MEDIA_URL=/media/

# Email Settings, see https://docs.djangoproject.com/en/3.2/ref/settings/#email-host
# Required for email confirmation and password reset (automatically activates if host is set)
EMAIL_HOST=${CLOUDRON_MAIL_SMTP_SERVER}
EMAIL_PORT=${CLOUDRON_MAIL_SMTPS_PORT}
EMAIL_HOST_USER=${CLOUDRON_MAIL_SMTP_USERNAME}
EMAIL_HOST_PASSWORD=${CLOUDRON_MAIL_SMTP_PASSWORD}
EMAIL_USE_TLS=0
EMAIL_USE_SSL=1
DEFAULT_FROM_EMAIL=${CLOUDRON_MAIL_FROM}

SOCIAL_PROVIDERS="allauth.socialaccount.providers.openid_connect"
SOCIALACCOUNT_PROVIDERS={"openid_connect": { "SERVERS": [{ "id": "cloudron", "name": "Cloudron", "server_url": "${CLOUDRON_OIDC_ISSUER}", "APP": { "client_id": "${CLOUDRON_OIDC_CLIENT_ID}", "secret": "${CLOUDRON_OIDC_CLIENT_SECRET}" } }] }}

GUNICORN_MEDIA=0

EOF

cat /app/data/.env >> /run/tandoor/.env

if [ ! -f /app/data/.initialized ]; then
    echo "==> Migrating database"

    # Activate virtual environment
    source ${VENV_PATH}/bin/activate

    # Initialize Database
    python /app/code/tandoor/manage.py migrate

    touch /app/data/.initialized
fi

if [ ! -d  /run/tandoor/static ]; then
    echo "==> Generating static files"
    cp -R /app/pkg/static  /run/tandoor/
    python /app/code/tandoor/manage.py collectstatic_js_reverse
    python /app/code/tandoor/manage.py collectstatic --noinput
fi

echo "=> Changing permissions"
chown -R cloudron:cloudron /app/data /run

echo "=> Starting supervisor"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Tandoor
