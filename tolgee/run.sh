#!/usr/bin/with-contenv bashio

# Get configuration
POSTGRES_HOST=$(bashio::config 'postgres_host')
POSTGRES_PORT=$(bashio::config 'postgres_port')
POSTGRES_ROOT_USER=$(bashio::config 'postgres_root_user')
POSTGRES_ROOT_PASSWORD=$(bashio::config 'postgres_root_password')
TOLGEE_DB_NAME=$(bashio::config 'tolgee_db_name')
TOLGEE_DB_USER=$(bashio::config 'tolgee_db_user')
TOLGEE_DB_PASSWORD=$(bashio::config 'tolgee_db_password')
INITIAL_USERNAME=$(bashio::config 'initial_username')

bashio::log.info "Starting Tolgee add-on..."

# Validate required fields
if bashio::var.is_empty "${POSTGRES_ROOT_PASSWORD}"; then
    bashio::log.fatal "PostgreSQL root password is required!"
    exit 1
fi

if bashio::var.is_empty "${TOLGEE_DB_PASSWORD}"; then
    bashio::log.fatal "Tolgee database password is required!"
    exit 1
fi

# Generate or load JWT secret
JWT_SECRET_FILE="/data/jwt_secret"
if [ ! -f "${JWT_SECRET_FILE}" ]; then
    bashio::log.info "Generating new JWT secret..."
    JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
    echo "${JWT_SECRET}" > "${JWT_SECRET_FILE}"
    chmod 600 "${JWT_SECRET_FILE}"
    bashio::log.info "JWT secret generated and saved"
else
    bashio::log.info "Loading existing JWT secret..."
    JWT_SECRET=$(cat "${JWT_SECRET_FILE}")
fi

# Wait for PostgreSQL to be ready
bashio::log.info "Waiting for PostgreSQL to be ready..."
timeout=60
elapsed=0
while ! pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        bashio::log.fatal "PostgreSQL not ready after ${timeout} seconds"
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done

bashio::log.info "PostgreSQL is ready!"

# Create database and user
bashio::log.info "Setting up database and user..."

export PGPASSWORD="${POSTGRES_ROOT_PASSWORD}"

# Check if database exists
DB_EXISTS=$(psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -tAc "SELECT 1 FROM pg_database WHERE datname='${TOLGEE_DB_NAME}'" 2>/dev/null)

if [ "$DB_EXISTS" != "1" ]; then
    bashio::log.info "Creating database ${TOLGEE_DB_NAME}..."
    psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -c "CREATE DATABASE ${TOLGEE_DB_NAME};" || {
        bashio::log.error "Failed to create database"
        exit 1
    }
else
    bashio::log.info "Database ${TOLGEE_DB_NAME} already exists"
fi

# Check if user exists
USER_EXISTS=$(psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${TOLGEE_DB_USER}'" 2>/dev/null)

if [ "$USER_EXISTS" != "1" ]; then
    bashio::log.info "Creating user ${TOLGEE_DB_USER}..."
    psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -c "CREATE USER ${TOLGEE_DB_USER} WITH PASSWORD '${TOLGEE_DB_PASSWORD}';" || {
        bashio::log.error "Failed to create user"
        exit 1
    }
else
    bashio::log.info "User ${TOLGEE_DB_USER} already exists"
fi

# Grant privileges
bashio::log.info "Granting privileges..."
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -c "GRANT ALL PRIVILEGES ON DATABASE ${TOLGEE_DB_NAME} TO ${TOLGEE_DB_USER};" || {
    bashio::log.error "Failed to grant privileges"
    exit 1
}

# Additional grants for PostgreSQL 15+
psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_ROOT_USER}" -d "${TOLGEE_DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${TOLGEE_DB_USER};" 2>/dev/null || true

unset PGPASSWORD

bashio::log.info "Database setup complete!"

# Set environment variables for Tolgee
export SPRING_DATASOURCE_URL="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${TOLGEE_DB_NAME}"
export SPRING_DATASOURCE_USERNAME="${TOLGEE_DB_USER}"
export SPRING_DATASOURCE_PASSWORD="${TOLGEE_DB_PASSWORD}"
export TOLGEE_AUTHENTICATION_JWT_SECRET="${JWT_SECRET}"
export TOLGEE_AUTHENTICATION_INITIAL_USERNAME="${INITIAL_USERNAME}"

# Start Tolgee
bashio::log.info "Starting Tolgee..."
exec java -jar /app/tolgee.jar
