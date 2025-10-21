ARG BUILD_FROM=ghcr.io/hassio-addons/base:17.1.0
FROM ${BUILD_FROM}

# Install dependencies if needed (Apache is in Vito image)
RUN apk add --no-cache apache2

# Pull in the Vito app
FROM vitodeploy/vito:latest AS vito

# Back to base image
FROM ${BUILD_FROM}

# Copy Vito app into the base image
COPY --from=vito /var/www/html /var/www/html

# Copy our startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Expose the port
EXPOSE 8000

CMD [ "/run.sh" ]
