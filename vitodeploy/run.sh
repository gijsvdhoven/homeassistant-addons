#!/bin/bash

# Set environment variables for Composer
export HOME=/root
export COMPOSER_HOME=/root/.composer

# Source bashio library if available
if [ -f /usr/lib/bashio/bashio.sh ]; then
    source /usr/lib/bashio/bashio.sh
fi

# Setup persistent directories
PERSISTENT_DIR="/data"
echo "Setting up persistent directories at: ${PERSISTENT_DIR}"
mkdir -p "${PERSISTENT_DIR}/storage"
mkdir -p "${PERSISTENT_DIR}/bootstrap/cache"
mkdir -p "${PERSISTENT_DIR}/config"

# Debug: Check if persistent directory is accessible
echo "Persistent directory contents:"
ls -la "${PERSISTENT_DIR}" || echo "Could not list ${PERSISTENT_DIR}"
df -h "${PERSISTENT_DIR}" || echo "Could not check disk space for ${PERSISTENT_DIR}"

# Test bashio API access first
BASHIO_AVAILABLE=false
if command -v bashio &> /dev/null; then
    # Test if bashio can access supervisor API without errors
    if bashio::supervisor.ping 2>/dev/null >/dev/null; then
        BASHIO_AVAILABLE=true
        echo "Bashio API available, loading configuration..."
    else
        echo "Bashio API not accessible, using standalone mode with defaults..."
    fi
fi

# Load configuration based on API availability
if [ "$BASHIO_AVAILABLE" = true ]; then
    # Use bashio to get configuration
    NAME=$(bashio::config 'name' || echo "vito")
    EMAIL=$(bashio::config 'email' || echo "admin@example.com")
    PASSWORD=$(bashio::config 'password' || echo "password")
    APP_URL=$(bashio::config 'app_url' || echo "http://homeassistant.local:8123")
    
    # Check for ingress
    INGRESS_ENABLED=false
    if bashio::addon.ingress_entry >/dev/null 2>&1; then
        INGRESS_ENTRY=$(bashio::addon.ingress_entry)
        INGRESS_ENABLED=true
        echo "Ingress enabled with entry: ${INGRESS_ENTRY}"
        
        # Use ingress URL
        ADDON_SLUG=$(bashio::addon.slug || echo "vito")
        APP_URL="/api/hassio_ingress/${ADDON_SLUG}"
        echo "Setting APP_URL for ingress: ${APP_URL}"
    fi
    
    echo "Configuration loaded from Home Assistant"
else
    # Fallback configuration (bashio not available or API not accessible)
    NAME=${NAME:-vito}
    EMAIL=${EMAIL:-admin@example.com}
    PASSWORD=${PASSWORD:-password}
    APP_URL=${APP_URL:-http://localhost}
    
    echo "Using default configuration (standalone mode)"
fi

# Ensure APP_URL is never empty
if [ -z "$APP_URL" ] || [ "$APP_URL" = "" ]; then
    APP_URL="http://localhost"
    echo "APP_URL was empty, setting to: $APP_URL"
fi

echo "Final configuration:"
echo "  NAME: $NAME"
echo "  EMAIL: $EMAIL"
echo "  APP_URL: $APP_URL"

# Generate or retrieve app key
APP_KEY_FILE="${PERSISTENT_DIR}/app_key"
if [ ! -f "${APP_KEY_FILE}" ]; then
    echo "Generating new app key..."
    # Try OpenSSL first, fallback to PHP if not available
    if command -v openssl &> /dev/null; then
        APP_KEY="base64:$(openssl rand -base64 32)"
    else
        echo "OpenSSL not available, using PHP for key generation..."
        APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    fi
    echo "${APP_KEY}" > "${APP_KEY_FILE}"
    echo "App key saved to persistent storage"
else
    APP_KEY=$(cat "${APP_KEY_FILE}")
    echo "Using existing app key from persistent storage"
fi

# Generate or use persistent .env file
ENV_FILE="${PERSISTENT_DIR}/config/.env"
if [ ! -f "${ENV_FILE}" ]; then
    echo "Generating new .env file..."
    # Generate .env file
    cat <<EOF >"${ENV_FILE}"
APP_NAME=Vito
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=${APP_URL}
APP_TIMEZONE=UTC

LOG_CHANNEL=stack
LOG_LEVEL=info

DB_CONNECTION=sqlite
DB_DATABASE=${PERSISTENT_DIR}/storage/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=log
MAIL_HOST=localhost
MAIL_PORT=587
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@vito.dev"
MAIL_FROM_NAME="Vito"

ADMIN_NAME=${NAME}
ADMIN_EMAIL=${EMAIL}
ADMIN_PASSWORD=${PASSWORD}
EOF
    echo ".env file created and saved to persistent storage"
else
    echo "Using existing .env file from persistent storage"
    # Update dynamic values in existing .env
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" "${ENV_FILE}"
    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${PERSISTENT_DIR}/storage/database.sqlite|" "${ENV_FILE}"
    sed -i "s|^ADMIN_NAME=.*|ADMIN_NAME=${NAME}|" "${ENV_FILE}"
    sed -i "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=${EMAIL}|" "${ENV_FILE}"
    sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${PASSWORD}|" "${ENV_FILE}"
    
    # Ensure required variables exist (add if missing)
    grep -q "^APP_TIMEZONE=" "${ENV_FILE}" || echo "APP_TIMEZONE=UTC" >> "${ENV_FILE}"
    grep -q "^MAIL_MAILER=" "${ENV_FILE}" || echo "MAIL_MAILER=log" >> "${ENV_FILE}"
    grep -q "^MAIL_FROM_ADDRESS=" "${ENV_FILE}" || echo 'MAIL_FROM_ADDRESS="noreply@vito.dev"' >> "${ENV_FILE}"
fi

# Link .env file to Laravel directory
ln -sf "${ENV_FILE}" /var/www/html/.env

# Debug: Show .env file contents and database path
echo "=== .env file contents ==="
cat /var/www/html/.env | grep -E "(DB_DATABASE|APP_KEY|APP_URL)" || echo "Could not read .env file"
echo "=========================="

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
    
    # Link persistent storage to Laravel storage directory
    if [ ! -L /var/www/html/storage ]; then
        rm -rf /var/www/html/storage
        ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage
    fi
    
    # Link persistent bootstrap cache
    if [ ! -L /var/www/html/bootstrap/cache ]; then
        rm -rf /var/www/html/bootstrap/cache
        ln -sf "${PERSISTENT_DIR}/bootstrap/cache" /var/www/html/bootstrap/cache
    fi
    
    # Ensure storage structure exists
    mkdir -p "${PERSISTENT_DIR}/storage"/{app,framework,logs}
    mkdir -p "${PERSISTENT_DIR}/storage/framework"/{cache,sessions,views,testing}
    
    # Create database file in storage directory
    touch "${PERSISTENT_DIR}/storage/database.sqlite"
    
    # Test database connection before migration
    echo "Testing database connection..."
    DB_PATH="${PERSISTENT_DIR}/storage/database.sqlite"
    if [ -f "$DB_PATH" ]; then
        echo "Database file exists at: $DB_PATH"
        ls -la "$DB_PATH"
        echo "Laravel should see it at: /var/www/html/storage/database.sqlite"
    else
        echo "ERROR: Database file not found at: $DB_PATH"
    fi
    
    # Migrate database
    php artisan migrate --force 2>/dev/null || true
    
    # Cache configuration
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    php artisan route:clear
fi

# Set proper permissions
chown -R apache:apache /var/www/html
chown -R apache:apache "${PERSISTENT_DIR}"
chmod -R 755 /var/www/html
chmod -R 777 "${PERSISTENT_DIR}/storage" 2>/dev/null || true
chmod -R 777 "${PERSISTENT_DIR}/bootstrap/cache" 2>/dev/null || true
chmod -R 755 "${PERSISTENT_DIR}/config" 2>/dev/null || true
chmod 666 "${PERSISTENT_DIR}/storage/database.sqlite" 2>/dev/null || true

echo "Starting Vito web server on port 80..."

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf