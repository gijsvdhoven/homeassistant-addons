# Use the official Vito Docker image
FROM vitodeploy/vito:latest

# Install bashio and jq for Home Assistant integration
RUN apt-get update && apt-get install -y curl jq \
    && curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz" \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp \
    && mv /tmp/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio.tar.gz /tmp/* \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Expose port 80 (Vito's default)
EXPOSE 80

# Use our run script instead of Vito's default
CMD ["/run.sh"]
