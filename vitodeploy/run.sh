#!/usr/bin/env bashio
set -e

bashio::log.info "🚀 Starting Vito Add-on setup..."

# Read or generate app key
APP_KEY=$(bashio::config 'app_key')
if [ -z "$APP_KEY" ]; then
  APP_KEY=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 32)
  bashio::log.info "Generated new APP_KEY: ${APP_KEY}"
  echo "$APP_KEY" > /data/app_key.txt
else
  bashio::log.info "Using provided APP_KEY"
fi

export APP_KEY="$APP_KEY"
export NAME=$(bashio::config 'name')
export EMAIL=$(bashio::config 'email')
export PASSWORD=$(bashio::config 'password')
export APP_URL=$(bashio::config 'app_url')

# Persistent data directories
mkdir -p /data/storage /data/plugins
mkdir -p /var/www/html/storage /var/www/html/app/Vito/Plugins

# Link persistent directories
if [ ! -L /var/www/html/storage ]; then
  rm -rf /var/www/html/storage
  ln -s /data/storage /var/www/html/storage
fi

if [ ! -L /var/www/html/app/Vito/Plugins ]; then
  rm -rf /var/www/html/app/Vito/Plugins
  ln -s /data/plugins /var/www/html/app/Vito/Plugins
fi

bashio::log.info "✅ Persistent directories mounted"
bashio::log.info "🌐 Starting Apache web server on port 8000"

# Start the main process
exec apache2-foreground
