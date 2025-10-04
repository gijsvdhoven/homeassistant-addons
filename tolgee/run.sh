#!/usr/bin/env bash
set -euo pipefail

# Configuration file path
readonly CONFIG_FILE="/data/options.json"

# Read HA add-on options
read_config() {
    POSTGRES_ROOT_URL=$(jq -r '.postgres_root_url' "$CONFIG_FILE")
    POSTGRES_ROOT_USER=$(jq -r '.postgres_root_user' "$CONFIG_FILE")
    POSTGRES_ROOT_PASSWORD=$(jq -r '.postgres_root_password' "$CONFIG_FILE")
    DB_NAME=$(jq -r '.database_name' "$CONFIG_FILE")
    DB_ROLE=$(jq -r '.database_user' "$CONFIG_FILE")
    DB_PASS=$(jq -r '.database_password' "$CONFIG_FILE")
}

# Extract host and port from JDBC URL
parse_postgres_url() {
    POSTGRES_HOST=$(echo "$POSTGRES_ROOT_URL" | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\1|')
    POSTGRES_PORT=$(echo "$POSTGRES_ROOT_URL" | sed -E 's|jdbc:postgresql://([^:/]+):([0-9]+)/.*|\2|')
}

# Wait until PostgreSQL is available
wait_for_postgres() {
    echo "Waiting for PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT..."
    local attempts=0
    local max_attempts=30
    
    until PGPASSWORD="$POSTGRES_ROOT_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
          -U "$POSTGRES_ROOT_USER" -d postgres -c '\q' 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ $attempts -ge $max_attempts ]; then
            echo "ERROR: PostgreSQL not available after $max_attempts attempts"
            exit 1
        fi
        echo "PostgreSQL not ready yet... retrying in 2s (attempt $attempts/$max_attempts)"
        sleep 2
    done
    echo "PostgreSQL is ready."
}

# Retry wrapper for psql commands
psql_retry() {
    local sql="$1"
    local attempts=0
    local max_attempts=10
    
    until PGPASSWORD="$POSTGRES_ROOT_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
          -U "$POSTGRES_ROOT_USER" -d postgres -c "$sql" 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ $attempts -ge $max_attempts ]; then
            echo "ERROR: Failed to execute SQL after $max_attempts attempts: $sql"
            exit 1
        fi
        echo "Retrying SQL command in 2s... (attempt $attempts/$max_attempts)"
        sleep 2
    done
}

# Check if role exists
role_exists() {
    PGPASSWORD="$POSTGRES_ROOT_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
        -U "$POSTGRES_ROOT_USER" -d postgres -tAc \
        "SELECT 1 FROM pg_roles WHERE rolname='$DB_ROLE'" | grep -q 1
}

# Check if database exists
database_exists() {
    PGPASSWORD="$POSTGRES_ROOT_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
        -U "$POSTGRES_ROOT_USER" -d postgres -tAc \
        "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1
}

# Ensure role exists
ensure_role() {
    if ! role_exists; then
        echo "Creating role '$DB_ROLE'..."
        psql_retry "CREATE ROLE \"$DB_ROLE\" LOGIN PASSWORD '$DB_PASS';"
    else
        echo "Role '$DB_ROLE' already exists."
    fi
}

# Ensure database exists
ensure_database() {
    if ! database_exists; then
        echo "Creating database '$DB_NAME'..."
        psql_retry "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_ROLE\";"
    else
        echo "Database '$DB_NAME' already exists."
    fi
}

# Configure Tolgee environment
configure_tolgee() {
    # Disable embedded Postgres (must be set first)
    export TOLGEE_POSTGRES_AUTOSTART="false"
    
    # Spring datasource configuration (standard Spring Boot properties)
    export SPRING_DATASOURCE_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$DB_NAME"
    export SPRING_DATASOURCE_USERNAME="$DB_ROLE"
    export SPRING_DATASOURCE_PASSWORD="$DB_PASS"
    
    # Tolgee-specific configuration (if needed)
    export TOLGEE_DATABASE_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$DB_NAME"
    export TOLGEE_DATABASE_USER="$DB_ROLE"
    export TOLGEE_DATABASE_PASSWORD="$DB_PASS"
    
    # Debug output
    echo "Environment variables configured:"
    echo "  TOLGEE_POSTGRES_AUTOSTART: $TOLGEE_POSTGRES_AUTOSTART"
    echo "  SPRING_DATASOURCE_URL: $SPRING_DATASOURCE_URL"
    echo "  SPRING_DATASOURCE_USERNAME: $SPRING_DATASOURCE_USERNAME"
    echo "  TOLGEE_DATABASE_URL: $TOLGEE_DATABASE_URL"
    echo "  TOLGEE_DATABASE_USER: $TOLGEE_DATABASE_USER"
}

# Main execution
main() {
    echo "Tolgee add-on starting..."
    
    read_config
    parse_postgres_url
    wait_for_postgres
    ensure_role
    ensure_database
    
    echo "Tolgee database and role setup complete."
    
    configure_tolgee
    
    echo "Starting Tolgee..."
    exec java -jar /tolgee.jar
}

main "$@"
