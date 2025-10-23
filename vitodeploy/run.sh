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

# Setup persistent directories (matching docker-compose volumes)
PERSISTENT_DIR="/data"
echo "Setting up persistent directories..."
mkdir -p "${PERSISTENT_DIR}/storage"
mkdir -p "${PERSISTENT_DIR}/plugins"

# Load configuration
echo "Loading configuration..."
if [ "$BASHIO_AVAILABLE" = true ]; then
    NAME=$(bashio::config 'name')
    EMAIL=$(bashio::config 'email')
    PASSWORD=$(bashio::config 'password')
    APP_URL=$(bashio::config 'app_url')
    
    # Apply defaults if empty
    NAME=${NAME:-"vito"}
    EMAIL=${EMAIL:-"admin@example.com"}
    PASSWORD=${PASSWORD:-"password"}
    APP_URL=${APP_URL:-"http://homeassistant.local:8089"}
else
    # Fallback configuration
    NAME=${NAME:-"vito"}
    EMAIL=${EMAIL:-"admin@example.com"}
    PASSWORD=${PASSWORD:-"password"}
    APP_URL=${APP_URL:-"http://localhost:8089"}
fi

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

echo "Configuration:"
echo "  Admin Name: $NAME"
echo "  Admin Email: $EMAIL"
echo "  App URL: $APP_URL"

# Set up volume mounts (matching docker-compose pattern)
echo "Setting up persistent storage volumes..."

# Create symlinks for persistent storage (like docker-compose volumes)
if [ ! -L /var/www/html/storage ]; then
    if [ -d /var/www/html/storage ]; then
        echo "Backing up existing storage..."
        cp -r /var/www/html/storage/* "${PERSISTENT_DIR}/storage/" 2>/dev/null || true
        rm -rf /var/www/html/storage
    fi
    ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage
fi

if [ ! -L /var/www/html/app/Vito/Plugins ]; then
    mkdir -p /var/www/html/app/Vito
    if [ -d /var/www/html/app/Vito/Plugins ]; then
        echo "Backing up existing plugins..."
        cp -r /var/www/html/app/Vito/Plugins/* "${PERSISTENT_DIR}/plugins/" 2>/dev/null || true
        rm -rf /var/www/html/app/Vito/Plugins
    fi
    ln -sf "${PERSISTENT_DIR}/plugins" /var/www/html/app/Vito/Plugins
fi

# Set permissions
chown -R www-data:www-data "${PERSISTENT_DIR}" 2>/dev/null || chown -R apache:apache "${PERSISTENT_DIR}"

# Export environment variables exactly like docker-compose
export APP_KEY="$APP_KEY"
export NAME="$NAME"
export EMAIL="$EMAIL"
export PASSWORD="$PASSWORD"
export APP_URL="$APP_URL"

echo ""
echo "🎉 Starting Vito..."
echo "📧 Admin Email: $EMAIL"
echo "🔑 Admin Password: $PASSWORD"
echo "🌐 Access URL: $APP_URL"
echo ""

# Execute the original Vito container's default command
# The official image should handle starting the web server
exec docker-entrypoint.sh