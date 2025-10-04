#!/usr/bin/with-contenv bashio
set -e

ROOT_URL=$(bashio::config 'postgres_root_url')
ROOT_USER=$(bashio::config 'postgres_root_user')
ROOT_PASS=$(bashio::config 'postgres_root_password')

DB_NAME=$(bashio::config 'database_name')
DB_USER=$(bashio::config 'database_user')
DB_PASS=$(bashio::config 'database_password')
POSTGRES_AUTOSTART=$(bashio::config 'postgres_autostart')

# Extract host:port from JDBC URL
DB_HOSTPORT=$(echo "$ROOT_URL" | sed -E 's|jdbc:postgresql://([^/]+)/.*|\1|')

echo "Ensuring database '$DB_NAME' and role '$DB_USER' exist..."

PGPASSWORD=$ROOT_PASS psql -h "${DB_HOSTPORT%%:*}" -p "${DB_HOSTPORT##*:}" -U "$ROOT_USER" -d postgres <<-EOSQL
   CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS' IF NOT EXISTS;
   CREATE DATABASE $DB_NAME OWNER $DB_USER IF NOT EXISTS;
EOSQL

echo "Starting Tolgee..."
exec java -jar /tolgee.jar \
  --spring.datasource.url="jdbc:postgresql://$DB_HOSTPORT/$DB_NAME" \
  --spring.datasource.username="$DB_USER" \
  --spring.datasource.password="$DB_PASS" \
  --tolgee.postgres.autostart.enabled="$POSTGRES_AUTOSTART" \
  --tolgee.file-storage.fs-data-path="/data/tolgee"
