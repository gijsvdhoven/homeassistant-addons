#!/usr/bin/with-contenv bashio
set -e

# --- Read options from add-on config ---
ROOT_URL=$(bashio::config 'postgres_root_url')
ROOT_USER=$(bashio::config 'postgres_root_user')
ROOT_PASS=$(bashio::config 'postgres_root_password')

DB_NAME=$(bashio::config 'database_name')
DB_USER=$(bashio::config 'database_user')
DB_PASS=$(bashio::config 'database_password')
POSTGRES_AUTOSTART=$(bashio::config 'postgres_autostart')

# --- Extract host:port ---
DB_HOSTPORT=$(echo "$ROOT_URL" | sed -E 's|jdbc:postgresql://([^/]+)/.*|\1|')
DB_HOST=${DB_HOSTPORT%%:*}
DB_PORT=${DB_HOSTPORT##*:}

echo "Ensuring role '$DB_USER' exists..."

# Ensure role exists
PGPASSWORD=$ROOT_PASS psql -h "$DB_HOST" -p "$DB_PORT" -U "$ROOT_USER" -d postgres <<-EOSQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';
   END IF;
END
\$\$;
EOSQL

# Check/create database separately
echo "Ensuring database '$DB_NAME' exists..."
DB_EXISTS=$(PGPASSWORD=$ROOT_PASS psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" -h "$DB_HOST" -p "$DB_PORT" -U "$ROOT_USER" -d postgres)

if [ "$DB_EXISTS_]()
