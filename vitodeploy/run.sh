#!/usr/bin/with-contenv bashio
set -euo pipefail

bashio::log.info "Launching Vito..."

# Make sure docker is available
if ! command -v docker &>/dev/null; then
    bashio::log.error "Docker CLI not found"
    exit 1
fi

# Create local volumes
mkdir -p /data/storage /data/plugins

# Stop existing Vito container (if any)
if docker ps -q --filter "name=addon_vito" | grep -q .; then
    bashio::log.info "Stopping previous Vito container..."
    docker stop addon_vito || true
fi

# Run Vito in background (detached)
bashio::log.info "Starting new Vito container..."
docker run -d \
  --name addon_vito \
  --network=host \
  -e APP_KEY="$(bashio::config 'app_key')" \
  -e NAME="$(bashio::config 'name')" \
  -e EMAIL="$(bashio::config 'email')" \
  -e PASSWORD="$(bashio::config 'password')" \
  -e APP_URL="$(bashio::config 'app_url')" \
  -v /data/storage:/var/www/html/storage \
  -v /data/plugins:/var/www/html/app/Vito/Plugins \
  vitodeploy/vito:latest

bashio::log.info "Vito is running and accessible on port 8000."
