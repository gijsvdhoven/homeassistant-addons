# Use Alpine-based HA base
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# Set environment variables
ENV HOME=/root
ENV COMPOSER_HOME=/root/.composer

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
    php83-pdo_mysql \
    php83-openssl \
    php83-ctype \
    php83-iconv \
    php83-simplexml \
    php83-xmlwriter \
    php83-phar \
    php83-gd \
    php83-intl \
    php83-opcache \
    php83-ftp \
    php83-pcntl \
    php83-posix \
    git \
    unzip \
    curl \
    bash \
    openssl

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create PHP symlinks
RUN ln -sf /usr/bin/php83 /usr/bin/php

# Clone and setup Vito
WORKDIR /var/www/html
RUN git clone https://github.com/vitodeploy/vito.git . && \
    rm -rf .git

# Install Vito dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --ignore-platform-req=php

# Create necessary directories and set permissions
RUN mkdir -p storage/{app,framework,logs} && \
    mkdir -p storage/framework/{cache,sessions,views,testing} && \
    mkdir -p bootstrap/cache && \
    mkdir -p database && \
    chmod -R 777 storage bootstrap/cache database

# Create default .env file
RUN cp .env.example .env 2>/dev/null || \
    echo -e "APP_NAME=Vito\nAPP_ENV=production\nAPP_KEY=\nAPP_DEBUG=false\nAPP_URL=http://localhost\n\nDB_CONNECTION=sqlite\nDB_DATABASE=/var/www/html/database/database.sqlite" > .env

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80

CMD ["/run.sh"]