# Use Debian-based Home Assistant base image
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:latest
FROM ${BUILD_FROM}

# Install Apache + PHP + dependencies
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-php php php-mbstring php-xml php-curl php-zip php-sqlite3 php-json php-cli php-common php-bcmath git unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module
RUN a2enmod rewrite

# Prepare web root and storage
RUN mkdir -p /var/www/html
RUN mkdir -p /var/www/html/storage && chmod -R 777 /var/www/html/storage

# Download Vito
RUN git clone https://github.com/vitodeploy/vito.git /var/www/html || true

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose HTTP port
EXPOSE 80

# Run entrypoint
CMD ["/entrypoint.sh"]
