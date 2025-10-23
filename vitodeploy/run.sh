#!/bin/bash

# Set environment variables for Composer
export HOME=/root
export COMPOSER_HOME=/root/.composer

# Source bashio library if available
if [ -f /usr/lib/bashio/bashio.sh ]; then
    source /usr/lib/bashio/bashio.sh
fi

# Check if running with ingress
if command -v bashio &> /dev/null; then
    # Try to get configuration, but don't fail if API is not accessible
    APP_KEY=$(bashio::config 'app_key' 2>/dev/null || echo "base64:YOUR-32-CHARACTER-KEY-HERE")
    NAME=$(bashio::config 'name' 2>/dev/null || echo "vito")
    EMAIL=$(bashio::config 'email' 2>/dev/null || echo "admin@example.com")
    PASSWORD=$(bashio::config 'password' 2>/dev/null || echo "password")
    APP_URL=$(bashio::config 'app_url' 2>/dev/null || echo "http://homeassistant.local:8123")
    
    # Check for ingress
    INGRESS_ENABLED=false
    if bashio::addon.ingress_entry 2>/dev/null; then
        INGRESS_ENTRY=$(bashio::addon.ingress_entry 2>/dev/null)
        INGRESS_ENABLED=true
        echo "Ingress enabled with entry: ${INGRESS_ENTRY}"
    fi
    
    # If ingress is enabled, use the ingress URL
    if [ "$INGRESS_ENABLED" = true ]; then
        ADDON_SLUG=$(bashio::addon.slug 2>/dev/null || echo "vito")
        APP_URL="/api/hassio_ingress/${ADDON_SLUG}"
        echo "Setting APP_URL for ingress: ${APP_URL}"
    fi
    
    echo "Configuration loaded (or using defaults)"
else
    # Fallback for local testing
    APP_KEY=${APP_KEY:-base64:YOUR-32-CHARACTER-KEY-HERE}
    NAME=${NAME:-vito}
    EMAIL=${EMAIL:-admin@example.com}
    PASSWORD=${PASSWORD:-password}
    APP_URL=${APP_URL:-http://localhost}
    
    echo "Running in standalone mode (no bashio detected)"
fi

# Generate .env file
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

ADMIN_NAME=${NAME}
ADMIN_EMAIL=${EMAIL}
ADMIN_PASSWORD=${PASSWORD}
EOF

# Configure Apache for PHP and Ingress
cat <<EOF >/etc/apache2/conf.d/vito.conf
ServerName localhost
DocumentRoot "/var/www/html/public"

<Directory "/var/www/html">
    Options FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory "/var/www/html/public">
    Options FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# PHP configuration
LoadModule php_module /usr/lib/apache2/mod_php83.so
AddType application/x-httpd-php .php
DirectoryIndex index.php index.html
EOF

# Enable Apache modules (check if not already enabled)
if ! grep -q "^LoadModule rewrite_module" /etc/apache2/httpd.conf; then
    echo "LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so" >> /etc/apache2/httpd.conf
fi
if ! grep -q "^LoadModule headers_module" /etc/apache2/httpd.conf; then
    echo "LoadModule headers_module /usr/lib/apache2/mod_headers.so" >> /etc/apache2/httpd.conf
fi

# Create .htaccess for Laravel
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

    # Handle Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF

# Install Vito dependencies if not already installed
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "Installing Vito dependencies..."
    cd /var/www/html
    
    # Install Composer dependencies
    if command -v composer &> /dev/null; then
        composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
    fi
fi

# Setup Laravel application
if [ -f /var/www/html/artisan ] && [ -f /var/www/html/vendor/autoload.php ]; then
    cd /var/www/html
    
    # Generate key if needed
    if grep -q "YOUR-32-CHARACTER-KEY-HERE" /var/www/html/.env; then
        php artisan key:generate --force
    fi
    
    # Create and migrate database
    mkdir -p /var/www/html/database
    touch /var/www/html/database/database.sqlite
    php artisan migrate --force 2>/dev/null || true
    
    # Cache configuration
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    php artisan route:clear
fi

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
chmod -R 777 /var/www/html/storage 2>/dev/null || true
chmod -R 777 /var/www/html/bootstrap/cache 2>/dev/null || true
chmod 777 /var/www/html/database 2>/dev/null || true
chmod 666 /var/www/html/database/database.sqlite 2>/dev/null || true

echo "Starting Vito web server on port 80..."

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf