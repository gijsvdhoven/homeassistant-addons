# Vito Home Assistant Add-on Development Guide

## Architecture Overview

This is a **Home Assistant add-on** that packages the Vito deployment tool (Laravel application) to run inside Home Assistant with full Ingress support. The add-on architecture consists of:

- **Alpine Linux base** with Apache + PHP 8.3 stack (with platform overrides for Vito compatibility)
- **Laravel/Vito application** cloned from GitHub during build
- **Home Assistant integration** via bashio library and ingress configuration
- **SQLite database** for simplicity (MySQL optional via MariaDB add-on)

## Key Files & Their Purpose

- `config.yaml`: Home Assistant add-on configuration (ingress, ports, schema)
- `Dockerfile`: Multi-stage build for Alpine + Apache + PHP + Vito dependencies
- `run.sh`: Dynamic configuration script that handles ingress/direct access modes
- `README.md`: User installation and troubleshooting guide

## Critical Development Patterns

### 1. Home Assistant Add-on Standards

```yaml
# config.yaml - Essential ingress configuration
ingress: true
ingress_port: 80
ingress_entry: /
init: false # Prevents s6-overlay PID 1 errors
```

### 2. Dynamic URL Resolution

The add-on supports both ingress and direct access. In `run.sh`:

```bash
# Ingress mode detection
if bashio::addon.ingress_entry 2>/dev/null; then
    APP_URL="/api/hassio_ingress/${ADDON_SLUG}"
else
    APP_URL="http://homeassistant.local:8123"
fi
```

### 3. Laravel Environment Setup

Environment variables are dynamically generated in `run.sh` based on Home Assistant configuration:

```bash
# Auto-generated app key (persistent)
APP_KEY=$(cat "${PERSISTENT_DIR}/app_key")
ADMIN_EMAIL=$(bashio::config 'email')
```

### 4. Persistent Storage

Critical data persists across container restarts using `/data` directory:

```bash
# Persistent directories mapped to /data
PERSISTENT_DIR="/data"
mkdir -p "${PERSISTENT_DIR}/database"
mkdir -p "${PERSISTENT_DIR}/storage"
mkdir -p "${PERSISTENT_DIR}/bootstrap/cache"
mkdir -p "${PERSISTENT_DIR}/config"

# Symlink Laravel directories to persistent locations
ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage
ln -sf "${PERSISTENT_DIR}/bootstrap/cache" /var/www/html/bootstrap/cache
ln -sf "${PERSISTENT_DIR}/config/.env" /var/www/html/.env
DB_DATABASE="${PERSISTENT_DIR}/database/database.sqlite"
```

### 5. Apache Configuration Pattern

Document root points to Laravel's public directory with proper rewrite rules:

```apache
DocumentRoot "/var/www/html/public"
# Laravel .htaccess handles routing to index.php
```

## Development Workflows

### Building & Testing

```bash
# Build locally (from add-on directory)
docker build -t local/vito-addon .

# Run with Home Assistant integration
docker run --rm -p 8080:80 \
  -e APP_KEY="base64:$(openssl rand -base64 32)" \
  local/vito-addon
```

### Debugging Add-on Issues

```bash
# Access running add-on container
docker exec -it addon_local_vito /bin/bash

# Check Laravel logs
tail -f /var/www/html/storage/logs/laravel.log

# Verify Apache configuration
httpd -t -f /etc/apache2/httpd.conf
```

### Configuration Updates

**CRITICAL**: Always increment the `version` number in `config.yaml` for ANY change to the add-on (Dockerfile, run.sh, config updates, etc.). Home Assistant uses this version to trigger rebuilds and updates.

When modifying `config.yaml`:

1. **Increment `version` number** (e.g., "1.7.3" → "1.7.4")
2. Update `schema` section to match new `options`
3. Update `run.sh` to handle new configuration variables
4. Test both ingress and direct access modes

When modifying other files (Dockerfile, run.sh, etc.):

1. **Always increment `version` number in `config.yaml`**
2. Test the build locally before pushing

## Home Assistant Integration Points

### Bashio Library Usage

The add-on uses bashio for Home Assistant integration:

```bash
# Safe configuration reading with fallbacks
APP_KEY=$(bashio::config 'app_key' 2>/dev/null || echo "default")

# Ingress detection
if bashio::addon.ingress_entry 2>/dev/null; then
    # Configure for ingress mode
fi
```

### Permission Management

Critical for Laravel application:

```bash
# Required permissions for storage and cache
chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache
chmod 666 /var/www/html/database/database.sqlite
```

## External Dependencies

- **Vito Repository**: `https://github.com/vitodeploy/vito.git` (cloned during build)
- **Composer**: Manages PHP dependencies during build process
- **Home Assistant Base Image**: `ghcr.io/home-assistant/amd64-base:latest`

## Common Issues & Solutions

### s6-overlay Conflicts

Use `init: false` in config.yaml and avoid s6 services. Run processes directly with `exec` in run.sh.

### Bashio API Access Issues

Handle API access errors gracefully with error suppression:

```bash
# Suppress bashio API errors and use fallbacks
NAME=$(bashio::config 'name' 2>&1 | grep -v "ERROR" | tail -n1 || echo "vito")
```

### Missing System Dependencies

Ensure required tools are installed in Dockerfile:

```dockerfile
# Add OpenSSL for key generation
openssl
```

### Ingress Path Issues

Laravel needs proper `APP_URL` for asset generation. The ingress path `/api/hassio_ingress/${ADDON_SLUG}` must match the actual ingress entry.

### Database Permissions

SQLite file must be writable by Apache user (`apache:apache`) with 666 permissions on the database file and 777 on the directory.

### PHP Version Compatibility

Vito may require newer PHP versions than Alpine provides. Handle this with platform requirements override:

```dockerfile
# Install required PHP extensions for Vito
php83-ftp \
php83-pcntl \
php83-posix \

# Override PHP version requirement during Composer install
RUN composer install --ignore-platform-req=php --no-dev --optimize-autoloader
```

### Missing PHP Extensions

Vito requires `ext-ftp`, `ext-pcntl`, and `ext-posix`. Add to Dockerfile APK install:

```dockerfile
php83-ftp \
php83-pcntl \
php83-posix \
```

## Architecture Decisions

- **SQLite over MySQL**: Simplifies deployment, no external database required
- **Git clone during build**: Ensures latest Vito code, but increases build time
- **Apache over Nginx**: Better Laravel integration, simpler configuration
- **Single-stage Dockerfile**: Prioritizes simplicity over image size optimization
