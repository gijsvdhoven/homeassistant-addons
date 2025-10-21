# Use official Home Assistant base image
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# Ensure bashio and s6-overlay are present (they are in this base)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add Docker CLI to control vitodeploy/vito container
RUN apk add --no-cache docker-cli bash

# Copy service definition
COPY rootfs/ /
