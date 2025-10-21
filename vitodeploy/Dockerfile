# Use official Home Assistant base image
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# Install PHP + Apache (using Debian packages — no missing alpine packages)
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-php php php-mbstring php-xml php-curl php-zip php-sqlite3 php-json php-cli php-common php-bcmath php-tokenizer git unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Set up Apache for Vito
RUN a2enmod rewrite

# Create directories
RUN mkdir -p /var/www/html

# Download and extract the Vito application from GitHub
RUN git clone https://github.com/vitodeploy/vito.git /var/www/html || true

# Make storage writable
RUN mkdir -p /var/www/html/storage && chmod -R 777 /var/www/html/storage

# Copy service definitions for HA
COPY rootfs/ /

# Expose web port
EXPOSE 80
