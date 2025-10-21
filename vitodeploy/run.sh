#!/usr/bin/env bash
set -e

echo "🔧 Setting up Vito environment..."

export APP_KEY=$(bashio::config 'app_key')
export NAME=$(bashio::config 'name')
export EMAIL=$(bashio::config 'email')
export PASSWORD=$(bashio::config 'password')
export APP_URL=$(bashio::config 'app_url')

# Ensure persistent data folders exist
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

echo "✅ Storage and plugin directories linked to /data"
echo "🚀 Starting Apache web server..."

exec apache2-foreground
