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
    git \
    unzip \
    curl \
    bash

# Install Composer manually
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create PHP symlinks for compatibility
RUN ln -sf /usr/bin/php83 /usr/bin/php

# Prepare web root
RUN mkdir -p /var/www/html && chmod -R 777 /var/www/html

# Download Vito
RUN git clone https://github.com/vitodeploy/vito.git /tmp/vito && \
    cp -r /tmp/vito/* /var/www/html/ && \
    rm -rf /tmp/vito

# Set up Laravel directories
RUN mkdir -p /var/www/html/storage/{app,framework,logs} && \
    mkdir -p /var/www/html/storage/framework/{cache,sessions,views} && \
    mkdir -p /var/www/html/bootstrap/cache && \
    chmod -R 777 /var/www/html/storage && \
    chmod -R 777 /var/www/html/bootstrap/cache || true

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80

CMD ["/run.sh"]