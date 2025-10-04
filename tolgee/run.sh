#!/usr/bin/env bash
set -e

echo "Ensuring role 'tolgee' exists..."
psql -U "$POSTGRES_USER" -d postgres <<'SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'tolgee') THEN
      CREATE ROLE tolgee LOGIN PASSWORD 'tolgee';
   END IF;
END
$$;
SQL

echo "Ensuring database 'tolgee' exists..."
psql -U "$POSTGRES_USER" -d postgres <<'SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tolgee') THEN
      PERFORM dblink_exec('dbname=postgres', 'CREATE DATABASE tolgee OWNER tolgee');
   END IF;
END
$$;
SQL
