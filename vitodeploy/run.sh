#!/usr/bin/env bash
set -e

echo "Starting Vito with Home Assistant options..."

export APP_KEY=$(bashio::config 'app_key')
export NAME=$(bashio::config 'name')
export EMAIL=$(bashio::config 'email')
export PASSWORD=$(bashio::config 'password')
export APP_URL=$(bashio::config 'app_url')

# Ensure storage directories exist
mkdir -p /var/www/html/storage /var/www/html/app/Vito/Plugins

exec apache2-foreground
