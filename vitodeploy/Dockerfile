# Use Alpine-based HA base
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# Install Apache + PHP + dependencies
RUN apk add --no-cache \
    apache2 \
    apache2-utils \
    php83 \
    php83-apache2 \
    php83-mbstring \
    php83-xml \
    php83-curl \
    php83-zip \
    php83-sqlite3 \
    php83-json \
    php83-cli \
    php83-common \
    php83-bcmath \
    php83-session \
    php83-tokenizer \
    php83-dom \
    php83-fileinfo \
    php83-pdo \
    php83-pdo_sqlite \
    git \
    unzip \
    curl

# Create PHP symlinks for compatibility
RUN ln -sf /usr/bin/php83 /usr/bin/php

# Prepare web root
RUN mkdir -p /var/www/html/storage && chmod -R 777 /var/www/html/storage

# Download Vito
RUN git clone https://github.com/vitodeploy/vito.git /var/www/html || true

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]
