ARG BUILD_FROM
FROM $BUILD_FROM

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    icecast2 \
    darkice \
    libmp3lame0 \
    pulseaudio-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration templates and scripts
COPY darkice.cfg.template /etc/darkice.cfg.template
COPY icecast.xml.template /etc/icecast2/icecast.xml.template
COPY run.sh /

RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
