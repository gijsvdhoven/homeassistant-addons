FROM ubuntu:latest

# The base image from Home Assistant’s build system is usually Debian-based.
# We'll pull the Vito image contents here.
RUN apt-get update && apt-get install -y \
    docker.io curl && \
    docker pull vitodeploy/vito:latest

# Create a wrapper script that sets up environment variables dynamically
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
