# Simplified Supernote Private Cloud Add-on
ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV LANG=C.UTF-8

# Install dependencies required by the Supernote install script
RUN apk add --no-cache \
        ca-certificates \
        curl \
        wget \
        gnupg \
        tar \
        gzip \
        openssl \
        jq \
        procps \
        iputils \
        sudo \
        bash \
        netcat-openbsd \
        docker \
        docker-compose

# Docker is installed via apk above, no additional installation needed
# The Home Assistant add-on will have access to Docker via docker_api: true

# Create directories
RUN mkdir -p /app /data /share/supernote /backup/supernote

# Copy run script
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:9888/health || curl -f http://localhost:9888/ || exit 1

# Set working directory
WORKDIR /app

# Expose ports
EXPOSE 9888 8080 19071 6000 3306 6379

# Labels
LABEL \
    io.hass.name="Supernote Private Cloud" \
    io.hass.description="Supernote Private Cloud Add-on using official install script" \
    io.hass.arch="amd64|aarch64" \
    io.hass.type="addon" \
    io.hass.version="1.2.0" \
    maintainer="Gijs van den Hoven" \
    org.opencontainers.image.title="Supernote Private Cloud" \
    org.opencontainers.image.description="Deploy Supernote Private Cloud using official script" \
    org.opencontainers.image.licenses="MIT"

# Start the run script
CMD ["/app/run.sh"]