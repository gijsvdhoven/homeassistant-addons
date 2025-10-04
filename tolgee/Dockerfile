ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install Java
RUN apk add --no-cache openjdk17 curl

# Download Tolgee release JAR
ENV TOLGEE_VERSION=3.61.0
RUN curl -L -o /tolgee.jar \
    https://github.com/tolgee/tolgee-platform/releases/download/v${TOLGEE_VERSION}/tolgee-${TOLGEE_VERSION}.jar

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       postgresql-client \
       openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*
EXPOSE 8080
COPY run.sh /run.sh
RUN chmod a+x /run.sh
CMD ["/run.sh"]
