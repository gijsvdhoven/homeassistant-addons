# Use Ubuntu base for better Docker/Sail compatibility
FROM ubuntu:24.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    curl \
    gnupg \
    unzip \
    git \
    supervisor \
    curl \
    openssl \
    && rm -rf /var/lib/apt/lists/*


# Install bashio for Home Assistant integration
RUN curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz" \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp \
    && mv /tmp/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio.tar.gz /tmp/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Clone Vito repository
WORKDIR /var/www/html
RUN git clone https://github.com/vitodeploy/vito.git . \
    && rm -rf .git

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install and build frontend assets
RUN npm ci && npm run build

# Create necessary directories and set permissions
RUN mkdir -p storage/{app,framework,logs,ssh-keys} \
    && mkdir -p storage/framework/{cache,sessions,views,testing} \
    && mkdir -p bootstrap/cache \
    && chmod -R 755 storage bootstrap/cache

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8000

CMD ["/run.sh"]
