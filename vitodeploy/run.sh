#!/bin/bash

# Source bashio library if available
if [ -f /usr/lib/bashio/bashio.sh ]; then
    source /usr/lib/bashio/bashio.sh
fi

# Check if running with ingress
if command -v bashio &> /dev/null; then
    # Get ingress interface if available
    INGRESS_ENABLED=false
    if bashio::addon.ingress_entry 2>/dev/null; then
        INGRESS_ENTRY=$(bashio::addon.ingress_entry)
        INGRESS_ENABLED=true
        bashio::log.info "Ingress enabled with entry: ${INGRESS_ENTRY}"
    fi
    
    # Generate .env from add-on options
    APP_KEY=$(bashio::config 'app_key')
    NAME=$(bashio::config 'name')
    EMAIL=$(bashio::config 'email')
    PASSWORD=$(bashio::config 'password')
    APP_URL=$(bashio::config 'app_url')
    
    # If ingress is enabled, use the ingress URL
    if [ "$INGRESS_ENABLED" = true ]; then
        # For ingress, we need to set the proper base URL
        ADDON_SLUG=$(bashio::addon.slug)
        APP_URL="/api/hassio_ingress/${ADDON_SLUG}"
        bashio::log.info "Setting APP_URL for ingress: ${APP_URL}"
    fi
    
    cat <<EOF >/var/www/html/.env
APP_NAME=Vito
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=${APP_URL}

LOG_CHANNEL=stack
LOG_LEVEL=info

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

NAME=${NAME}
EMAIL=${EMAIL}
PASSWORD=${PASSWORD}
EOF
    
    bashio::log.info "Configuration loaded from Home Assistant"
else
    # Fallback for local testing
    cat <<EOF >/var/www/html/.env
APP_NAME=Vito
APP_ENV=production
APP_KEY=${APP_KEY:-base64:YOUR-32-CHARACTER-KEY-HERE}
APP_DEBUG=false
APP_URL=${APP_URL:-http://localhost}

LOG_CHANNEL=stack
LOG_LEVEL=info

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

NAME=${NAME:-vito}
EMAIL=${EMAIL:-admin@example.com}
PASSWORD=${PASSWORD:-password}
EOF
    
    echo "Running in standalone mode (no bashio detected)"
fi

# Configure Apache for PHP and Ingress
cat <<EOF >/etc/apache2/conf.d/vito.conf
ServerName localhost
DocumentRoot "/var/www/html/public"

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory "/var/www/html/public">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    
    # Laravel rewrite rules
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</Directory>

# PHP configuration
LoadModule php_module /usr/lib/apache2/mod_php83.so
AddType application/x-httpd-php .php
DirectoryIndex index.php index.html

# Ingress proxy headers
<IfModule mod_headers.c>
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
</IfModule>
EOF

# Enable Apache modules (mod_rewrite is built-in to Alpine's Apache)
echo "LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so" >> /etc/apache2/httpd.conf 2>/dev/null || true
echo "LoadModule headers_module /usr/lib/apache2/mod_headers.so" >> /etc/apache2/httpd.conf 2>/dev/null || true

# Create a basic .htaccess for Laravel if it doesn't exist
if [ ! -f /var/www/html/public/.htaccess ]; then
    cat <<'EOF' >/var/www/html/public/.htaccess
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF
fi

# Check if Vito needs initial setup
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "First run - setting up Vito..."
    cd /var/www/html
    
    # Install dependencies
    if command -v composer &> /dev/null; then
        composer install --no-dev --optimize-autoloader --no-interaction || true
    fi
    
    # Generate application key if not provided
    if [ -f /var/www/html/artisan ]; then
        php artisan key:generate --force || true
        php artisan config:cache || true
        php artisan route:cache || true
        php artisan view:cache || true
    fi
fi

# Create database if it doesn't exist
if [ ! -f /var/www/html/database/database.sqlite ]; then
    mkdir -p /var/www/html/database
    touch /var/www/html/database/database.sqlite
    chmod 666 /var/www/html/database/database.sqlite
    
    # Run migrations if artisan is available
    if [ -f /var/www/html/artisan ]; then
        cd /var/www/html
        php artisan migrate --force || true
        php artisan db:seed --force || true
    fi
fi

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache 2>/dev/null || true
chmod 777 /var/www/html/database 2>/dev/null || true
chmod 666 /var/www/html/database/database.sqlite 2>/dev/null || true

if command -v bashio &> /dev/null; then
    bashio::log.info "Starting Vito web server..."
else
    echo "Starting Vito web server..."
fi

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf