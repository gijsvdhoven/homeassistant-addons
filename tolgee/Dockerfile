ARG BUILD_FROM
FROM $BUILD_FROM

# Install PostgreSQL client for database setup
RUN apk add --no-cache \
    postgresql-client \
    openjdk21-jre \
    bash \
    curl

# Download Tolgee
ARG TOLGEE_VERSION=3.133.0
RUN mkdir -p /app && \
    curl -L -o /app/tolgee.jar \
    "https://github.com/tolgee/tolgee-platform/releases/download/v${TOLGEE_VERSION}/tolgee-${TOLGEE_VERSION}.jar"

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
