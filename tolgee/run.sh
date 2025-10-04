#!/usr/bin/env bash
set -e

# Read HA add-on options
POSTGRES_ROOT_URL=$(jq -r '.postgres_root_url' /data/options.json)
POSTGRES_ROOT_USER=$(jq -r '.postgres_root_user' /data/options.json)
POSTGRES_ROOT_PASSWORD=$(jq -r '.postgres_root_password' /data/options.json)
DB_NAME=$(jq -r '.database_name' /data/options.json)
DB_ROLE=$(jq -r '.database_user' /data/options.json)
DB_PASS=$(jq -r '.database_password' /data/options.json)

echo "Tolgee add-on starting..."

# Extract host and port from JDBC URL
POSTGRES_HOST=$(echo $POSTGRES_ROOT_URL | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\1|')
POSTGRES_PORT=$(echo $POSTGRES_ROOT_URL | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\2|')

# Wait until PostgreSQL is available
echo "Waiting for PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT..."
until PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -d postgres -c '\q' 2>/dev/null; do
  echo "Postgres not ready yet... retrying in 2s"
  sleep 2
done
echo "PostgreSQL is ready."

# Retry wrapper for psql commands
psql_retry() {
  local sql="$1"
  local attempts=0
  until PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -d postgres -c "$sql"; do
    attempts=$((attempts + 1))
    if [ $attempts -ge 10 ]; then
      echo "Failed to execute SQL after 10 attempts: $sql"
      exit 1
    fi
    echo "Retrying SQL command in 2s..."
    sleep 2
  done
}

# Ensure role exists
if ! PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_ROLE'" | grep -q 1; then
  echo "Creating role '$DB_ROLE'..."
  psql_retry "CREATE ROLE $DB_ROLE LOGIN PASSWORD '$DB_PASS';"
else
  echo "Role '$DB_ROLE' already exists."
fi

# Ensure database exists
if ! PGPASSWORD=$POSTGRES_ROOT_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_ROOT_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
  echo "Creating database '$DB_NAME'..."
  psql_retry "CREATE DATABASE $DB_NAME OWNER $DB_ROLE;"
else
  echo "Database '$DB_NAME' already exists."
fi

echo "Tolgee database and role setup complete."

# Start Tolgee
exec java -jar /tolgee.jar
