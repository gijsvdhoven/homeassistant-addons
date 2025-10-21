ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM vitodeploy/vito:latest

# Copy start script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
