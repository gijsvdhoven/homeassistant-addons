#!/usr/bin/with-contenv bashio
set -e

DB_URL=$(bashio::config 'database_url')
DB_USER=$(bashio::config 'database_user')
DB_PASS=$(bashio::config 'database_password')

echo "Starting Tolgee..."
exec java -jar /tolgee.jar \
  --spring.datasource.url="$DB_URL" \
  --spring.datasource.username="$DB_USER" \
  --spring.datasource.password="$DB_PASS"
