# Use Debian-based Home Assistant base image (so we can use apt-get)
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:latest
FROM ${BUILD_FROM}

# Install PHP + Apache
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-php php php-mbstring php-xml php-curl php-zip php-sqlite3 php-json php-cli php-common php-bcmath php-tokenizer git unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module
RUN a2enmod rewrite

# Prepare web root
RUN mkdir -p /var/www/html

# Clone Vito
RUN git clone https://github.com/vitodeploy/vito.git /var/www/html || true

# Make storage writable
RUN mkdir -p /var/www/html/storage && chmod -R 777 /var/www/html/storage

# Copy HA service scripts
COPY rootfs/ /

EXPOSE 80
