#!/usr/bin/env bash
set -e

# Read HA add-on options from options.json
POSTGRES_ROOT_URL=$(jq -r '.postgres_root_url' /data/options.json)
POSTGRES_ROOT_USER=$(jq -r '.postgres_root_user' /data/options.json)
POSTGRES_ROOT_PASSWORD=$(jq -r '.postgres_root_password' /data/options.json)
DB_NAME=$(jq -r '.database_name' /data/options.json)
DB_ROLE=$(jq -r '.database_user' /data/options.json)
DB_PASS=$(jq -r '.database_password' /data/options.json)
POSTGRES_AUTOSTART=$(jq -r '.postgres_autostart' /data/options.json)

echo "Tolgee add-on starting..."

# Wait for PostgreSQL if autostart is enabled
if [ "$POSTGRES_AUTOSTART" = "true" ]; then
  echo "Autostarting PostgreSQL..."
  # Here you can trigger starting the postgres add-on container if needed
fi

# Extract host and port from JDBC URL
POSTGRES_HOST=$(echo $POSTGRES_ROOT_URL | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\1|')
POSTGRES_PORT=$(echo $POSTGRES_ROOT_URL | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\2|')

echo "Ensuring PostgreSQL role '$DB_ROLE' exists..."
PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_ROLE') THEN CREATE ROLE $DB_ROLE LOGIN PASSWORD '$DB_PASS'; END IF; END \$\$;"

echo "Ensuring PostgreSQL database '$DB_NAME' exists..."
PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN CREATE DATABASE $DB_NAME OWNER $DB_ROLE; END IF; END \$\$;"

echo "Tolgee database and role setup complete."

# Start Tolgee
exec java -jar /tolgee.jar
