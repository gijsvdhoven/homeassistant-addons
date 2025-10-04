#!/usr/bin/env bash
set -e

# --- Configuration ---
POSTGRES_HOST=${POSTGRES_HOST:-core-postgres}  # Hostname of the Postgres add-on
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-postgres}       # Root user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
DB_NAME=${DB_NAME:-tolgee}
DB_ROLE=${DB_ROLE:-tolgee}
DB_PASS=${DB_PASS:-tolgee}

export PGPASSWORD="$POSTGRES_PASSWORD"

# --- Wait for Postgres to be ready ---
echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT..."
until psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -c '\q' 2>/dev/null; do
  echo "Postgres is unavailable - sleeping 2s"
  sleep 2
done

# --- Ensure role exists ---
echo "Ensuring role '$DB_ROLE' exists..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<SQL
DO
\$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_ROLE') THEN
      CREATE ROLE $DB_ROLE LOGIN PASSWORD '$DB_PASS';
   END IF;
END
\$\$;
SQL

# --- Ensure database exists ---
echo "Ensuring database '$DB_NAME' exists..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<SQL
DO
\$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
      EXECUTE 'CREATE DATABASE $DB_NAME OWNER $DB_ROLE';
   END IF;
END
\$\$;
SQL

echo "Database and role are ready."

# --- Start Tolgee ---
echo "Starting Tolgee..."
java -jar /tolgee.jar
