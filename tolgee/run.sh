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

echo "Ensuring database '$DB_NAME' and role '$DB_USER' exist..."

PGPASSWORD=$ROOT_PASS psql -h "$DB_HOST" -p "$DB_PORT" -U "$ROOT_USER" -d postgres <<-EOSQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';
   END IF;
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
      CREATE DATABASE $DB_NAME OWNER $DB_USER;
   END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL

echo "Starting Tolgee..."
exec java -jar /tolgee.jar \
  --server.address=0.0.0.0 \
  --server.port=8080 \
  --spring.datasource.url="jdbc:postgresql://$DB_HOSTPORT/$DB_NAME" \
  --spring.datasource.username="$DB_USER" \
  --spring.datasource.password="$DB_PASS" \
  --tolgee.postgres.autostart.enabled="$POSTGRES_AUTOSTART" \
  --tolgee.file-storage.fs-data-path="/data/tolgee"
