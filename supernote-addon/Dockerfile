ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Build arguments
ARG BUILD_ARCH
ARG BUILD_VERSION

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    jq \
    mariadb \
    mariadb-client \
    redis \
    supervisor \
    nginx \
    openssl \
    shadow \
    su-exec \
    tzdata \
    && rm -rf /var/cache/apk/*

# Create application directories
RUN mkdir -p \
    /app/data \
    /app/logs \
    /app/config \
    /app/backups \
    /var/log/supervisor \
    /var/lib/mysql \
    /var/lib/redis \
    /run/mysqld \
    /run/redis

# Create application user
RUN addgroup -g 1000 supernote && \
    adduser -D -s /bin/bash -u 1000 -G supernote supernote

# Set up MySQL data directory
RUN mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Copy supervisor configuration
COPY rootfs/etc/supervisor/ /etc/supervisor/

# Copy nginx configuration
COPY rootfs/etc/nginx/ /etc/nginx/

# Copy application files
COPY rootfs/app/ /app/
COPY rootfs/usr/local/bin/ /usr/local/bin/

# Copy database initialization
COPY rootfs/docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Make scripts executable
RUN chmod +x /usr/local/bin/run.sh \
    && chmod +x /usr/local/bin/init-database.sh \
    && chmod +x /app/scripts/*.sh

# Set proper permissions
RUN chown -R mysql:mysql /var/lib/mysql /run/mysqld \
    && chown -R redis:redis /var/lib/redis \
    && chown -R supernote:supernote /app

# Expose ports
EXPOSE 19072 19071 8080 9888 6000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:19072/ || exit 1

# Labels
LABEL \
    io.hass.name="Supernote Private Cloud" \
    io.hass.description="Private cloud solution for Supernote devices" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Supernote Community" \
    org.opencontainers.image.title="Supernote Private Cloud" \
    org.opencontainers.image.description="Private cloud solution for Supernote devices" \
    org.opencontainers.image.vendor="Supernote Community" \
    org.opencontainers.image.authors="Supernote Community" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/supernote-community/supernote-private-cloud-addon" \
    org.opencontainers.image.source="https://github.com/supernote-community/supernote-private-cloud-addon"

# Start supervisor
CMD ["/usr/local/bin/run.sh"]