#!/usr/bin/env bash
set -e

echo "Starting Vito add-on..."

export APP_KEY=$(bashio::config 'app_key')
export NAME=$(bashio::config 'name')
export EMAIL=$(bashio::config 'email')
export PASSWORD=$(bashio::config 'password')
export APP_URL=$(bashio::config 'app_url')

# Ensure volumes exist
mkdir -p /data/storage /data/plugins

# Link to expected paths
ln -sf /data/storage /var/www/html/storage
ln -sf /data/plugins /var/www/html/app/Vito/Plugins

# start the docker image
docker run -d -p 8089:80 \
  -e APP_KEY="$APP_KEY" \
  -e NAME="$NAME" \
  -e EMAIL="$EMAIL" \
  -e PASSWORD="$PASSWORD" \
  -e APP_URL="$APP_URL" \
  -v /data/storage:/var/www/html/storage \
  -v /data/plugins:/var/www/html/app/Vito/Plugins \
  vitodeploy/vito:latest
