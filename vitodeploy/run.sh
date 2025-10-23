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

# Try to load configuration from Home Assistant, but don't let failures stop us
echo "Attempting to load configuration from Home Assistant..."

# Test a simple bashio call first
BASHIO_WORKING=false
if command -v bashio &> /dev/null; then
    # Try a simple call that should work if API is accessible
    if TEST_RESULT=$(timeout 5 bashio::supervisor.ping 2>/dev/null) && [ $? -eq 0 ]; then
        # Try to get one config value to test if API really works
        if TEST_NAME=$(timeout 5 bashio::config 'name' 2>/dev/null) && [ $? -eq 0 ]; then
            BASHIO_WORKING=true
            echo "Home Assistant API is working, loading configuration..."
        else
            echo "Home Assistant API calls are failing, using defaults..."
        fi
    else
        echo "Cannot connect to Home Assistant supervisor, using defaults..."
    fi
else
    echo "Bashio not available, using defaults..."
fi

# Load configuration
if [ "$BASHIO_WORKING" = true ]; then
    # Use bashio to get configuration (we know it works)
    NAME=$(bashio::config 'name' || echo "vito")
    EMAIL=$(bashio::config 'email' || echo "admin@example.com")  
    PASSWORD=$(bashio::config 'password' || echo "password")
    APP_URL=$(bashio::config 'app_url' || echo "http://homeassistant.local:8089")
    
    echo "Configuration loaded from Home Assistant"
else
    # Use safe defaults when API is not working
    NAME="vito"
    EMAIL="admin@example.com"
    PASSWORD="password"
    APP_URL="http://homeassistant.local:8089"
    
    echo "Using safe default configuration with direct port access"
fi

# Ensure APP_URL is never empty
if [ -z "$APP_URL" ] || [ "$APP_URL" = "" ]; then
    APP_URL="http://homeassistant.local:8089"
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
DB_DATABASE=database.sqlite

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
    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=database.sqlite|" "${ENV_FILE}"
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
        echo "Laravel should see it as: database.sqlite (relative to storage directory)"
        echo "Actual Laravel storage path: /var/www/html/storage/"
        ls -la /var/www/html/storage/database.sqlite 2>/dev/null || echo "Symlink check failed"
    else
        echo "ERROR: Database file not found at: $DB_PATH"
    fi
    
    # Migrate database
    php artisan migrate --force 2>/dev/null || true
    
    # Check if we need to create an admin user
    echo "Checking for admin user..."
    USER_COUNT=$(php artisan tinker --execute="echo App\Models\User::count();" 2>/dev/null || echo "0")
    if [ "$USER_COUNT" = "0" ]; then
        echo "Creating admin user..."
        php artisan tinker --execute="
            \$user = new App\Models\User();
            \$user->name = '$NAME';
            \$user->email = '$EMAIL';
            \$user->password = Hash::make('$PASSWORD');
            \$user->save();
            echo 'Admin user created: ' . \$user->email;
        " 2>/dev/null || echo "Could not create admin user"
    else
        echo "Admin user already exists (user count: $USER_COUNT)"
    fi
    
    # Cache configuration
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    php artisan route:clear
    
    # Generate application key if needed
    if ! grep -q "APP_KEY=base64:" /var/www/html/.env; then
        echo "Generating application key..."
        php artisan key:generate --force
    fi
    
    # Check if frontend assets need to be built
    if [ ! -d "/var/www/html/public/build" ] && [ -f "/var/www/html/package.json" ]; then
        echo "Frontend assets missing, checking if we can build them..."
        if command -v npm >/dev/null 2>&1; then
            echo "Building frontend assets with npm..."
            cd /var/www/html
            npm install --production 2>/dev/null || echo "npm install failed"
            npm run build 2>/dev/null || echo "npm run build failed" 
        else
            echo "npm not available, frontend assets will need to be pre-built"
        fi
    fi
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

# Debug Apache and Laravel setup
echo "=== Apache and Laravel Debug ==="
echo "Document root contents:"
ls -la /var/www/html/public/ | head -10
echo ""
echo "Checking key Laravel files:"
test -f /var/www/html/public/index.php && echo "✓ index.php exists" || echo "✗ index.php missing"
test -f /var/www/html/artisan && echo "✓ artisan exists" || echo "✗ artisan missing"  
test -f /var/www/html/vendor/autoload.php && echo "✓ vendor/autoload.php exists" || echo "✗ vendor/autoload.php missing"
test -f /var/www/html/.env && echo "✓ .env exists" || echo "✗ .env missing"
echo ""
echo "Checking frontend assets:"
ls -la /var/www/html/public/build/ 2>/dev/null | head -5 || echo "No build directory found"
ls -la /var/www/html/public/css/ 2>/dev/null | head -3 || echo "No css directory found"  
ls -la /var/www/html/public/js/ 2>/dev/null | head -3 || echo "No js directory found"
echo ""
echo "Laravel routes check:"
cd /var/www/html
php artisan route:list 2>/dev/null | head -5 || echo "Could not list routes"
echo ""
echo "Apache config test:"
httpd -t -f /etc/apache2/httpd.conf
echo ""
echo "Testing web server after startup (in background):"
{
    sleep 5  # Wait for Apache to start
    echo "Testing homepage..."
    curl -s -o /tmp/test_response.html -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "Could not connect to localhost"
    echo "Response size: $(wc -c < /tmp/test_response.html 2>/dev/null || echo '0') bytes"
    
    echo "Testing direct PHP file:"
    curl -s -w "HTTP Status: %{http_code}\n" http://localhost/index.php || echo "Could not connect to index.php"
    
    echo "Checking Apache error log:"
    tail -n 5 /var/log/apache2/error.log 2>/dev/null || echo "No error log found"
} &
echo "Background test started..."
echo "================================"

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf