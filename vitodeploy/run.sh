#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "🚀 Starting Vito Add-on (Ingress Mode)..."

# Auto-generate APP_KEY
APP_KEY=$(bashio::config 'app_key')
if [ -z "$APP_KEY" ]; then
  APP_KEY=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 32)
  echo "$APP_KEY" > /data/app_key.txt
  bashio::log.info "Generated new APP_KEY: ${APP_KEY}"
else
  bashio::log.info "Using provided APP_KEY"
fi

export APP_KEY="$APP_KEY"
export NAME=$(bashio::config 'name')
export EMAIL=$(bashio::config 'email')
export PASSWORD=$(bashio::config 'password')
export APP_URL=$(bashio::config 'app_url')

# Ensure persistent directories exist
mkdir -p /data/storage /data/plugins
mkdir -p /var/www/html/storage /var/www/html/app/Vito/Plugins

# Link persistent dirs
if [ ! -L /var/www/html/storage ]; then
  rm -rf /var/www/html/storage
  ln -s /data/storage /var/www/html/storage
fi

if [ ! -L /var/www/html/app/Vito/Plugins ]; then
  rm -rf /var/www/html/app/Vito/Plugins
  ln -s /data/plugins /var/www/html/app/Vito/Plugins
fi

bashio::log.info "✅ Persistent storage linked"

# Update Apache to listen on Ingress port
PORT="${INGRESS_PORT:-8000}"
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/httpd.conf || true

bashio::log.info "🌐 Starting Apache on port ${PORT}"
exec httpd -D FOREGROUND
