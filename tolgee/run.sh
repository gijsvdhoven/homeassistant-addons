#!/usr/bin/env bash
set -e

# --- Configuration ---
POSTGRES_HOST=${POSTGRES_HOST:-core-postgres}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
DB_NAME=tolgee
DB_ROLE=tolgee
DB_PASS=tolgee

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT..."
until psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -c '\q' 2>/dev/null; do
  echo "Postgres is unavailable - sleeping 2s"
  sleep 2
done

echo "Ensuring role '$DB_ROLE' exists..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<'SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'tolgee') THEN
      CREATE ROLE tolgee LOGIN PASSWORD 'tolgee';
   END IF;
END
$$;
SQL

echo "Ensuring database '$DB_NAME' exists..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<'SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tolgee') THEN
      PERFORM dblink_exec('dbname=postgres user=postgres password=postgres host=core-postgres port=5432', 
                          'CREATE DATABASE tolgee OWNER tolgee');
   END IF;
END
$$;
SQL

echo "Database and role are ready."

# --- Start Tolgee ---
echo "Starting Tolgee..."
java -jar /tolgee.jar
