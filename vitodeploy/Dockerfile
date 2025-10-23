# Use Ubuntu base for better Docker/Sail compatibility
FROM ubuntu:22.04

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
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install PHP 8.3
RUN add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install -y \
    php8.3 \
    php8.3-cli \
    php8.3-fpm \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-sqlite3 \
    php8.3-redis \
    php8.3-zip \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-curl \
    php8.3-xml \
    php8.3-bcmath \
    php8.3-intl \
    php8.3-readline \
    php8.3-pcov \
    php8.3-msgpack \
    php8.3-igbinary \
    php8.3-ldap \
    php8.3-redis \
    php8.3-swoole \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Set environment variables
ENV HOME=/root
ENV COMPOSER_HOME=/root/.composer

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create PHP symlink
RUN ln -sf /usr/bin/php8.3 /usr/bin/php

# Install bashio for Home Assistant integration
RUN curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz" \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp \
    && mv /tmp/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio.tar.gz /tmp/*

# Clone and setup Vito
WORKDIR /var/www/html
RUN git clone https://github.com/vitodeploy/vito.git . && \
    rm -rf .git

# Install Vito dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --ignore-platform-req=php

# Build frontend assets if needed
RUN if [ -f package.json ]; then \
        echo "Building frontend assets..." && \
        npm ci --only=production && \
        npm run build; \
    else \
        echo "No package.json found, skipping frontend build"; \
    fi

# Create necessary directories
RUN mkdir -p storage/{app,framework,logs} && \
    mkdir -p storage/framework/{cache,sessions,views,testing} && \
    mkdir -p bootstrap/cache && \
    chmod -R 755 storage bootstrap/cache

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80

CMD ["/run.sh"]