# Simplified Supernote Private Cloud Add-on
ARG BUILD_FROM=ghcr.io/hassio-addons/ubuntu-base/amd64:8.0.0
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required by the Supernote install script
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg \
        lsb-release \
        software-properties-common \
        tar \
        gzip \
        openssl \
        jq \
        procps \
        net-tools \
        iputils-ping \
        sudo \
        systemctl \
        dbus \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Docker (required by the Supernote script)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Docker Compose (standalone)
RUN DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) \
    && curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

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