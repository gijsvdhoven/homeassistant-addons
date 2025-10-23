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

# Clone and setup Vito
WORKDIR /root
RUN bash <(curl -Ls https://raw.githubusercontent.com/vitodeploy/vito/3.x/scripts/install.sh)
