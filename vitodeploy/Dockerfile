ARG BUILD_FROM=ghcr.io/hassio-addons/base:17.1.0
FROM ${BUILD_FROM}

# Install dependencies
RUN apk add --no-cache apache2 php81 php81-apache2 php81-mbstring php81-pdo php81-pdo_sqlite php81-tokenizer php81-xml php81-fileinfo php81-session php81-json php81-curl php81-zip php81-dom php81-openssl git curl unzip openssl

# Download and install Vito
WORKDIR /var/www/html
RUN curl -L https://github.com/vitodeploy/vito/archive/refs/heads/main.zip -o vito.zip \
    && unzip vito.zip \
    && mv vito-main/* . \
    && rm -rf vito.zip vito-main

# Copy our startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Expose the internal port
EXPOSE 8000

# Start script (s6-overlay handles PID 1)
CMD ["/run.sh"]
