#!/bin/bash

echo "=== Vito Home Assistant Add-on (Official Docker Image) ==="

# Test bashio availability first
BASHIO_AVAILABLE=false
if [ -f /usr/lib/bashio/bashio.sh ]; then
    source /usr/lib/bashio/bashio.sh
    if command -v bashio &> /dev/null; then
        if bashio::supervisor.ping 2>/dev/null >/dev/null; then
            BASHIO_AVAILABLE=true
            echo "Bashio API available"
        else
            echo "Bashio API not available - using fallback configuration"
        fi
    fi
else
    echo "Bashio library not found - using fallback configuration"
fi

# Setup persistent directories
PERSISTENT_DIR="/data"
echo "Setting up persistent directories..."
mkdir -p "${PERSISTENT_DIR}/storage"
mkdir -p "${PERSISTENT_DIR}/plugins"

# Load configuration with proper fallbacks and debugging
echo "Loading configuration..."
if [ "$BASHIO_AVAILABLE" = true ]; then
    NAME=$(bashio::config 'name')
    EMAIL=$(bashio::config 'email')
    PASSWORD=$(bashio::config 'password')
    
    # Debug: Show what we got from bashio
    echo "Debug - Raw config values:"
    echo "  name: '$NAME'"
    echo "  email: '$EMAIL'"
    echo "  password: '$PASSWORD'"
    
    # Apply defaults if empty
    NAME=${NAME:-"Vito Admin"}
    EMAIL=${EMAIL:-"admin@example.com"}
    PASSWORD=${PASSWORD:-"password"}
    
    # Handle ingress vs direct access
    if bashio::addon.ingress_entry 2>/dev/null; then
        ADDON_SLUG=$(bashio::addon.slug 2>/dev/null || echo "vito")
        APP_URL="/api/hassio_ingress/${ADDON_SLUG}"
        echo "Running in Home Assistant ingress mode"
    else
        APP_URL="http://homeassistant.local:80"
        echo "Running in direct access mode"
    fi
else
    # Fallback configuration when bashio is not available
    NAME=${NAME:-"Vito Admin"}
    EMAIL=${EMAIL:-"admin@example.com"}
    PASSWORD=${PASSWORD:-"password"}
    APP_URL=${APP_URL:-"http://localhost:80"}
    echo "Using environment variables or defaults"
fi

echo "Configuration:"
echo "  Admin Name: $NAME"
echo "  Admin Email: $EMAIL"
echo "  App URL: $APP_URL"

# Generate app key if not exists
APP_KEY_FILE="${PERSISTENT_DIR}/app_key"
if [ ! -f "$APP_KEY_FILE" ]; then
    echo "Generating new app key..."
    APP_KEY="base64:$(openssl rand -base64 32)"
    echo "$APP_KEY" > "$APP_KEY_FILE"
    echo "App key saved to persistent storage"
else
    APP_KEY=$(cat "$APP_KEY_FILE")
    echo "Using existing app key from persistent storage"
fi

# Set up persistent storage volumes
echo "Setting up persistent storage..."
if [ ! -L /var/www/html/storage ]; then
    # Move existing storage to persistent location if it exists
    if [ -d /var/www/html/storage ] && [ ! -L /var/www/html/storage ]; then
        echo "Moving existing storage to persistent location..."
        cp -r /var/www/html/storage/* "${PERSISTENT_DIR}/storage/" 2>/dev/null || true
        rm -rf /var/www/html/storage
    fi
    ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage
fi

if [ ! -L /var/www/html/app/Vito/Plugins ]; then
    # Move existing plugins if they exist
    if [ -d /var/www/html/app/Vito/Plugins ] && [ ! -L /var/www/html/app/Vito/Plugins ]; then
        echo "Moving existing plugins to persistent location..."
        mkdir -p "${PERSISTENT_DIR}/plugins"
        cp -r /var/www/html/app/Vito/Plugins/* "${PERSISTENT_DIR}/plugins/" 2>/dev/null || true
        rm -rf /var/www/html/app/Vito/Plugins
    fi
    mkdir -p /var/www/html/app/Vito
    ln -sf "${PERSISTENT_DIR}/plugins" /var/www/html/app/Vito/Plugins
fi

# Set proper permissions
chown -R www-data:www-data "${PERSISTENT_DIR}" 2>/dev/null || chown -R apache:apache "${PERSISTENT_DIR}"
chown -R www-data:www-data /var/www/html 2>/dev/null || chown -R apache:apache /var/www/html

# Export environment variables for Vito
export APP_KEY="$APP_KEY"
export NAME="$NAME"
export EMAIL="$EMAIL"
export PASSWORD="$PASSWORD" 
export APP_URL="$APP_URL"

echo ""
echo "🎉 Starting Vito with official Docker image..."
echo "📧 Admin Email: $EMAIL"
echo "🔑 Admin Password: $PASSWORD"
echo "🌐 Access URL: $APP_URL"
echo ""

# Debug: Check what's currently running
echo "=== DEBUG: Current processes ==="
ps aux
echo ""

# Debug: Check what ports are listening
echo "=== DEBUG: Listening ports ==="
netstat -tlnp 2>/dev/null || ss -tlnp 2>/dev/null || echo "No netstat/ss available"
echo ""

# Debug: Check web server status
echo "=== DEBUG: Web server check ==="
if command -v nginx >/dev/null 2>&1; then
    echo "Nginx available: $(nginx -v 2>&1)"
    systemctl status nginx 2>/dev/null || service nginx status 2>/dev/null || echo "Nginx service status unknown"
fi

if command -v apache2ctl >/dev/null 2>&1; then
    echo "Apache available: $(apache2ctl -v 2>&1 | head -1)"
    systemctl status apache2 2>/dev/null || service apache2 status 2>/dev/null || echo "Apache service status unknown"
fi

if command -v php-fpm >/dev/null 2>&1; then
    echo "PHP-FPM available: $(php-fpm --version 2>&1 | head -1)"
fi

echo ""

# Debug: Check if something is already listening on port 80
echo "=== DEBUG: Port 80 status ==="
curl -I http://localhost:80 2>/dev/null || echo "Nothing responding on port 80 yet"
echo ""

# Instead of starting our own web server, let's see if we can use the original CMD
echo "=== DEBUG: Original image info ==="
echo "Checking what the original image was supposed to run..."

# Let's try to start the original processes in the background first
echo "Starting background processes..."

# Start any services that might be needed
service nginx start 2>/dev/null &
service apache2 start 2>/dev/null &
service php8.3-fpm start 2>/dev/null || service php-fpm start 2>/dev/null &

# Wait a moment for services to start
sleep 5

# Check again what's running
echo "=== DEBUG: Processes after service start ==="
ps aux
echo ""

echo "=== DEBUG: Port 80 status after service start ==="
curl -I http://localhost:80 2>/dev/null || echo "Still nothing on port 80"
echo ""

# If nothing is working, let's keep the container alive and see what happens
echo "Keeping container alive for debugging..."
tail -f /dev/null