#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Supernote Private Cloud
# Starts the Supernote Private Cloud services
# ==============================================================================

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Directories
readonly DATA_DIR="/app/data"
readonly CONFIG_DIR="/app/config" 
readonly LOG_DIR="/app/logs"
readonly BACKUP_DIR="/app/backups"

log() {
    bashio::log.info "$1"
}

error() {
    bashio::log.error "$1"
}

warn() {
    bashio::log.warning "$1"
}

# Create required directories
create_directories() {
    log "Creating required directories..."
    
    mkdir -p \
        "${DATA_DIR}/supernote_data" \
        "${DATA_DIR}/uploads" \
        "${DATA_DIR}/convert" \
        "${DATA_DIR}/recycle" \
        "${LOG_DIR}/cloud" \
        "${LOG_DIR}/app" \
        "${LOG_DIR}/web" \
        "${LOG_DIR}/notelib" \
        "${CONFIG_DIR}/mysql" \
        "${CONFIG_DIR}/redis" \
        "${CONFIG_DIR}/nginx" \
        "${BACKUP_DIR}" \
        "/var/log/supervisor"
    
    # Set proper permissions
    chown -R supernote:supernote "${DATA_DIR}" "${LOG_DIR}" "${CONFIG_DIR}" "${BACKUP_DIR}"
    chmod -R 755 "${DATA_DIR}" "${LOG_DIR}" "${CONFIG_DIR}" "${BACKUP_DIR}"
}

# Generate configuration from Home Assistant options
generate_config() {
    log "Generating configuration from Home Assistant options..."
    
    # Get configuration from Home Assistant
    export MYSQL_ROOT_PASSWORD=$(bashio::config 'mysql_root_password')
    export MYSQL_PASSWORD=$(bashio::config 'mysql_password')
    export REDIS_PASSWORD=$(bashio::config 'redis_password')
    export LOG_LEVEL=$(bashio::config 'log_level')
    export SSL_ENABLED=$(bashio::config 'ssl_enabled')
    export BACKUP_ENABLED=$(bashio::config 'backup_enabled')
    export MAX_FILE_SIZE=$(bashio::config 'max_file_size')
    export SESSION_TIMEOUT=$(bashio::config 'session_timeout')
    
    # Fixed database configuration
    export MYSQL_DATABASE="supernotedb"
    export MYSQL_USER="enote"
    export MYSQL_HOST="localhost"
    export REDIS_HOST="localhost"
    
    # SSL configuration
    if bashio::config.true 'ssl_enabled'; then
        if bashio::config.has_value 'ssl_certfile' && bashio::config.has_value 'ssl_keyfile'; then
            export SSL_CERTFILE="/ssl/$(bashio::config 'ssl_certfile')"
            export SSL_KEYFILE="/ssl/$(bashio::config 'ssl_keyfile')"
        else
            warn "SSL enabled but certificate files not specified. Disabling SSL."
            export SSL_ENABLED=false
        fi
    fi
    
    # Create environment file for services
    cat > /app/.env << EOF
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_HOST=${MYSQL_HOST}
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_HOST=${REDIS_HOST}
LOG_LEVEL=${LOG_LEVEL}
SSL_ENABLED=${SSL_ENABLED}
SSL_CERTFILE=${SSL_CERTFILE:-}
SSL_KEYFILE=${SSL_KEYFILE:-}
BACKUP_ENABLED=${BACKUP_ENABLED}
MAX_FILE_SIZE=${MAX_FILE_SIZE}
SESSION_TIMEOUT=${SESSION_TIMEOUT}
DATA_DIR=${DATA_DIR}
LOG_DIR=${LOG_DIR}
CONFIG_DIR=${CONFIG_DIR}
EOF
    
    chmod 600 /app/.env
}

# Initialize MySQL
init_mysql() {
    log "Initializing MySQL..."
    
    # Ensure MySQL directory exists and has correct permissions
    mkdir -p /var/lib/mysql /run/mysqld
    chown -R mysql:mysql /var/lib/mysql /run/mysqld
    
    # Initialize database if not exists
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        log "Initializing MySQL database..."
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    fi
    
    # Start MySQL temporarily for initialization
    /usr/bin/mariadb --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!
    
    # Wait for MySQL to start
    log "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            log "MySQL is ready"
            break
        fi
        sleep 1
    done

    # Set root password (only if not already set)
    if /usr/bin/mariadb -u root -e "SELECT 1" &>/dev/null; then
        log "Setting root password..."
        /usr/bin/mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    fi

    # Run initialization scripts if database doesn't exist
    if ! /usr/bin/mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE supernotedb;" 2>/dev/null; then
        log "Creating database and user..."
        
        /usr/bin/mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS supernotedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'supernote'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON supernotedb.* TO 'supernote'@'localhost';
FLUSH PRIVILEGES;
EOF

        # Run SQL initialization file
       
        log "Running database initialization script from /usr/local/bin/supernotedb.sql..."
        /usr/bin/mariadb -u supernote -p"${MYSQL_PASSWORD}" supernotedb < /usr/local/bin/supernotedb.sql

        
        log "Database initialized successfully"
    else
        log "Database already exists, skipping initialization"
    fi
    
    # Stop temporary MySQL
    kill $MYSQL_PID
    wait $MYSQL_PID 2>/dev/null || true
}

# Generate supervisor configuration
generate_supervisor_config() {
    log "Generating supervisor configuration..."
    
    cat > /etc/supervisor/conf.d/supernote.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:mysql]
command=/usr/bin/mysqld_safe --user=mysql --datadir=/var/lib/mysql
autostart=true
autorestart=true
user=mysql
stdout_logfile=/var/log/supervisor/mysql.log
stderr_logfile=/var/log/supervisor/mysql_error.log
priority=100

[program:redis]
command=/usr/bin/redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes --dir /var/lib/redis
autostart=true
autorestart=true
user=redis
stdout_logfile=/var/log/supervisor/redis.log
stderr_logfile=/var/log/supervisor/redis_error.log
priority=200

[program:notelib]
command=/app/services/notelib/start.sh
autostart=true
autorestart=true
user=supernote
stdout_logfile=/var/log/supervisor/notelib.log
stderr_logfile=/var/log/supervisor/notelib_error.log
priority=300
environment=PATH="/usr/local/bin:/usr/bin:/bin"

[program:supernote-service]
command=/app/services/supernote-service/start.sh
autostart=true
autorestart=true
user=supernote
stdout_logfile=/var/log/supervisor/supernote-service.log
stderr_logfile=/var/log/supervisor/supernote-service_error.log
priority=400
environment=PATH="/usr/local/bin:/usr/bin:/bin"

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
user=root
stdout_logfile=/var/log/supervisor/nginx.log
stderr_logfile=/var/log/supervisor/nginx_error.log
priority=500
EOF
}

# Generate nginx configuration
generate_nginx_config() {
    log "Generating nginx configuration..."
    
    cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size ${MAX_FILE_SIZE};
    
    upstream backend {
        server localhost:19071;
    }
    
    upstream frontend {
        server localhost:9888;
    }
    
    server {
        listen 19072;
        server_name _;
        
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
}

# Main execution
main() {
    log "Starting Supernote Private Cloud addon..."
    
    # Create directories
    create_directories
    
    # Generate configuration
    generate_config
    
    # Initialize MySQL
    init_mysql
    
    # Generate service configurations
    generate_supervisor_config
    generate_nginx_config
    
    # Display startup information
    log "Configuration complete!"
    log "Web interface will be available at: http://[HOST]:19072"
    log "Default login: admin / admin123"
    warn "Please change the default password after first login!"
    
    # Start supervisor
    log "Starting services..."
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supernote.conf
}

# Run main function
main "$@"