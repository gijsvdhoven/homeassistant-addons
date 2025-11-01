#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize MariaDB database for Supernote Private Cloud
# ==============================================================================

set -e

MYSQL_ROOT_PASSWORD=$(bashio::config 'mysql_root_password')
MYSQL_PASSWORD=$(bashio::config 'mysql_password')

bashio::log.info "Initializing database..."

# Wait for MySQL to be ready
for i in {1..30}; do
    if mysqladmin ping --silent; then
        bashio::log.info "MySQL is ready"
        break
    fi
    bashio::log.info "Waiting for MySQL to be ready... ($i/30)"
    sleep 2
done

# Set root password
mysql -u root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOSQL

# Run initialization scripts if database doesn't exist
if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE supernotedb;" 2>/dev/null; then
    bashio::log.info "Creating database and user..."
    
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
        CREATE DATABASE IF NOT EXISTS supernotedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS 'supernote'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON supernotedb.* TO 'supernote'@'localhost';
        FLUSH PRIVILEGES;
EOSQL

    # Run SQL initialization file if it exists
    if [ -f /docker-entrypoint-initdb.d/supernotedb.sql ]; then
        bashio::log.info "Running database initialization script..."
        mysql -u supernote -p"${MYSQL_PASSWORD}" supernotedb < /docker-entrypoint-initdb.d/supernotedb.sql
    fi
    
    bashio::log.info "Database initialized successfully"
else
    bashio::log.info "Database already exists, skipping initialization"
fi
