ARG BUILD_FROM
FROM $BUILD_FROM

# Install PostgreSQL client for database setup
RUN apk add --no-cache \
    postgresql-client \
    openjdk17-jre \
    openssl \
    bash

# Download Tolgee
ARG TOLGEE_VERSION=3.65.0
RUN wget -O /app/tolgee.jar \
    "https://github.com/tolgee/tolgee-platform/releases/download/v${TOLGEE_VERSION}/tolgee-${TOLGEE_VERSION}.jar"

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
