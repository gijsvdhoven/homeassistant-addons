ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# Install dependencies (compatible with Alpine 3.22+)
RUN apk add --no-cache \
    apache2 \
    php8 \
    php8-apache2 \
    php8-mbstring \
    php8-pdo \
    php8-pdo_sqlite \
    php8-tokenizer \
    php8-xml \
    php8-fileinfo \
    php8-session \
    php8-json \
    php8-curl \
    php8-zip \
    php8-dom \
    php8-openssl \
    php8-simplexml \
    php8-ctype \
    php8-phar \
    php8-iconv \
    git curl unzip openssl

# Prepare web root
WORKDIR /var/www/html

# Download and install latest Vito from GitHub
RUN curl -L https://github.com/vitodeploy/vito/archive/refs/heads/main.zip -o vito.zip \
    && unzip vito.zip \
    && mv vito-main/* . \
    && rm -rf vito.zip vito-main

# Fix permissions
RUN chown -R root:root /var/www/html

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8000

# Start the add-on (s6-overlay is PID 1)
CMD ["/run.sh"]
