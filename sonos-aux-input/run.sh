#!/usr/bin/with-contenv bashio
set +u  # Allow unbound variables

bashio::log.info "=============================================="
bashio::log.info "       Sonos AUX Input Addon Starting"
bashio::log.info "=============================================="

# Read configuration values
STREAM_NAME=$(bashio::config 'stream_name')
STREAM_DESCRIPTION=$(bashio::config 'stream_description')
STREAM_GENRE=$(bashio::config 'stream_genre')
BITRATE=$(bashio::config 'bitrate')
PORT=$(bashio::config 'port')
# Ensure port is a plain number (strip any whitespace/quotes)
PORT=$(echo "${PORT}" | tr -d '[:space:]"')
# Default to 8010 if port is null or empty
if [ -z "${PORT}" ] || [ "${PORT}" = "null" ]; then
    PORT=8010
    bashio::log.warning "Port was null, using default: ${PORT}"
fi
SAMPLE_RATE=44100  # CD quality, hardcoded
ICECAST_PASSWORD=$(bashio::config 'icecast_password')
MOUNT_POINT=$(bashio::config 'mount_point')

bashio::log.info ""
bashio::log.info "[Configuration]"
bashio::log.info "  Stream name: ${STREAM_NAME}"
bashio::log.info "  Stream description: ${STREAM_DESCRIPTION}"
bashio::log.info "  Stream genre: ${STREAM_GENRE}"
bashio::log.info "  Bitrate: ${BITRATE} kbps"
bashio::log.info "  Port: ${PORT}"
bashio::log.info "  Sample rate: ${SAMPLE_RATE} Hz (CD quality)"
bashio::log.info "  Mount point: ${MOUNT_POINT}"
bashio::log.info ""

# Check PulseAudio environment
bashio::log.info "[PulseAudio Environment]"
bashio::log.info "  PULSE_SERVER: ${PULSE_SERVER:-not set}"
bashio::log.info "  PULSE_SOURCE: ${PULSE_SOURCE:-not set}"
bashio::log.info ""

# List PulseAudio sources (input devices)
bashio::log.info "[PulseAudio Sources]"
bashio::log.info "Available PulseAudio input sources:"
PA_SOURCES=$(pactl list sources short 2>&1)
if [ $? -eq 0 ]; then
    echo "${PA_SOURCES}" | while IFS= read -r line; do
        bashio::log.info "  ${line}"
    done
else
    bashio::log.warning "Could not list PulseAudio sources: ${PA_SOURCES}"
fi
bashio::log.info ""

# Determine audio source
bashio::log.info "[Audio Source Selection]"

if [ -n "${PULSE_SOURCE:-}" ]; then
    bashio::log.info "Using Home Assistant selected audio input: ${PULSE_SOURCE}"
    AUDIO_SOURCE="${PULSE_SOURCE}"
else
    bashio::log.info "No PULSE_SOURCE set, auto-detecting USB audio input..."

    # Try to find a USB audio input source (not a monitor)
    USB_SOURCE=$(pactl list sources short 2>/dev/null | grep -i "usb" | grep -i "input\|analog-stereo" | grep -v "monitor" | head -n1 | awk '{print $2}')

    if [ -n "${USB_SOURCE}" ]; then
        bashio::log.info "Found USB audio input: ${USB_SOURCE}"
        AUDIO_SOURCE="${USB_SOURCE}"
        export PULSE_SOURCE="${USB_SOURCE}"
    else
        # Fallback to default source
        DEFAULT_SOURCE=$(pactl info 2>/dev/null | grep "Default Source" | cut -d: -f2 | tr -d ' ')
        if [ -n "${DEFAULT_SOURCE}" ]; then
            bashio::log.info "No USB input found, using PulseAudio default: ${DEFAULT_SOURCE}"
            AUDIO_SOURCE="${DEFAULT_SOURCE}"
            export PULSE_SOURCE="${DEFAULT_SOURCE}"
        else
            bashio::log.error ""
            bashio::log.error "=============================================="
            bashio::log.error "ERROR: No audio input source available!"
            bashio::log.error "=============================================="
            bashio::log.error ""
            bashio::log.error "Please select an audio input device in the addon's"
            bashio::log.error "Audio settings (click the Audio tab in the addon config)."
            bashio::log.error ""
            exit 1
        fi
    fi
fi

bashio::log.info "Final audio source: ${AUDIO_SOURCE}"
bashio::log.info ""

# Test PulseAudio recording
bashio::log.info "[Audio Source Test]"
bashio::log.info "Testing PulseAudio source..."
parecord --channels=2 --rate="${SAMPLE_RATE}" --device="${AUDIO_SOURCE}" /dev/null 2>&1 &
TEST_PID=$!
sleep 1
if kill -0 $TEST_PID 2>/dev/null; then
    kill $TEST_PID 2>/dev/null
    bashio::log.info "PulseAudio source test: SUCCESS"
else
    bashio::log.warning "PulseAudio source test may have failed - continuing anyway..."
fi
bashio::log.info ""

# Create log directory for icecast
bashio::log.info "[Icecast2 Setup]"
bashio::log.info "Creating log directory..."
mkdir -p /var/log/icecast2
chown -R nobody:nogroup /var/log/icecast2 2>/dev/null || true

# Generate Icecast configuration from template
bashio::log.info "Generating Icecast configuration from template..."
sed -e "s|__ICECAST_PASSWORD__|${ICECAST_PASSWORD}|g" \
    -e "s|__MOUNT_POINT__|${MOUNT_POINT}|g" \
    -e "s|__PORT__|${PORT}|g" \
    /etc/icecast2/icecast.xml.template > /etc/icecast2/icecast.xml
bashio::log.info "Icecast configuration written to /etc/icecast2/icecast.xml"

# Start Icecast2 server
bashio::log.info "Starting Icecast2 server..."
icecast2 -c /etc/icecast2/icecast.xml &
ICECAST_PID=$!
bashio::log.info "Icecast2 started with PID ${ICECAST_PID}"

# Wait for Icecast to be ready
bashio::log.info "Waiting for Icecast2 to initialize..."
sleep 3

# Verify Icecast is running
if ! kill -0 ${ICECAST_PID} 2>/dev/null; then
    bashio::log.error ""
    bashio::log.error "=============================================="
    bashio::log.error "ERROR: Icecast2 failed to start!"
    bashio::log.error "=============================================="
    bashio::log.error ""
    bashio::log.error "Check the Icecast configuration and logs."
    bashio::log.error "Icecast error log:"
    if [ -f /var/log/icecast2/error.log ]; then
        cat /var/log/icecast2/error.log | while IFS= read -r line; do
            bashio::log.error "  ${line}"
        done
    else
        bashio::log.error "  (no error log found)"
    fi
    exit 1
fi

bashio::log.info "Icecast2 is running and listening on port ${PORT}"
bashio::log.info ""

# Generate Darkice configuration from template
bashio::log.info "[Darkice Setup]"
bashio::log.info "Generating Darkice configuration from template..."
sed -e "s|__AUDIO_DEVICE__|pulseaudio|g" \
    -e "s|__PA_SOURCE_NAME__|${AUDIO_SOURCE}|g" \
    -e "s|__SAMPLE_RATE__|${SAMPLE_RATE}|g" \
    -e "s|__BITRATE__|${BITRATE}|g" \
    -e "s|__PORT__|${PORT}|g" \
    -e "s|__ICECAST_PASSWORD__|${ICECAST_PASSWORD}|g" \
    -e "s|__MOUNT_POINT__|${MOUNT_POINT}|g" \
    -e "s|__STREAM_NAME__|${STREAM_NAME}|g" \
    -e "s|__STREAM_DESCRIPTION__|${STREAM_DESCRIPTION}|g" \
    -e "s|__STREAM_GENRE__|${STREAM_GENRE}|g" \
    /etc/darkice.cfg.template > /etc/darkice.cfg
bashio::log.info "Darkice configuration written to /etc/darkice.cfg"

bashio::log.info "Darkice configuration summary:"
bashio::log.info "  Input: PulseAudio"
bashio::log.info "  Source: ${AUDIO_SOURCE}"
bashio::log.info "  Sample rate: ${SAMPLE_RATE} Hz"
bashio::log.info "  Channels: 2 (stereo)"
bashio::log.info "  Output format: MP3 @ ${BITRATE} kbps CBR"
bashio::log.info "  Stream mount: /${MOUNT_POINT}"

# Start Darkice
bashio::log.info "Starting Darkice audio encoder..."
darkice -c /etc/darkice.cfg &
DARKICE_PID=$!
bashio::log.info "Darkice started with PID ${DARKICE_PID}"

# Wait a moment and check if Darkice started
bashio::log.info "Waiting for Darkice to connect to Icecast..."
sleep 3

if ! kill -0 ${DARKICE_PID} 2>/dev/null; then
    bashio::log.error ""
    bashio::log.error "=============================================="
    bashio::log.error "ERROR: Darkice failed to start!"
    bashio::log.error "=============================================="
    bashio::log.error ""
    bashio::log.error "Possible causes:"
    bashio::log.error "  1. The selected audio input is not accessible"
    bashio::log.error "  2. The device doesn't support the configured sample rate (${SAMPLE_RATE} Hz)"
    bashio::log.error "  3. PulseAudio connection failed"
    bashio::log.error ""
    bashio::log.error "Try:"
    bashio::log.error "  1. Select a different audio input in the addon's Audio settings"
    bashio::log.error "  2. Check that your USB sound card is connected"
    bashio::log.error "  3. Restart the addon"
    bashio::log.error ""
    kill ${ICECAST_PID} 2>/dev/null
    exit 1
fi

bashio::log.info "Darkice is running and encoding audio"
bashio::log.info ""

# Get the Home Assistant host IP for the stream URL
HOST_IP=$(hostname -I | awk '{print $1}')

bashio::log.info "=============================================="
bashio::log.info "    Sonos AUX Input is now STREAMING!"
bashio::log.info "=============================================="
bashio::log.info ""
bashio::log.info "Stream URL: http://${HOST_IP}:${PORT}/${MOUNT_POINT}"
bashio::log.info ""
bashio::log.info "To add this stream to Sonos:"
bashio::log.info "  1. Open Sonos desktop app (or web app)"
bashio::log.info "  2. Go to: Manage -> Add Radio Station"
bashio::log.info "  3. Enter the stream URL above"
bashio::log.info "  4. Give it a name (e.g., '${STREAM_NAME}')"
bashio::log.info ""
bashio::log.info "Alternative: Use TuneIn 'My Radio Stations' to add custom URLs"
bashio::log.info ""
bashio::log.info "Icecast status page: http://${HOST_IP}:${PORT}/"
bashio::log.info "=============================================="
bashio::log.info ""
bashio::log.info "Addon is now running. Monitoring processes..."

# Handle shutdown gracefully
cleanup() {
    bashio::log.info ""
    bashio::log.info "Shutdown signal received, stopping services..."
    bashio::log.info "Stopping Darkice (PID ${DARKICE_PID})..."
    kill ${DARKICE_PID} 2>/dev/null
    bashio::log.info "Stopping Icecast2 (PID ${ICECAST_PID})..."
    kill ${ICECAST_PID} 2>/dev/null
    bashio::log.info "Shutdown complete."
    exit 0
}

trap cleanup SIGTERM SIGINT

# Keep the script running and monitor processes
MONITOR_COUNT=0
while true; do
    # Check Icecast
    if ! kill -0 ${ICECAST_PID} 2>/dev/null; then
        bashio::log.error "Icecast2 process (PID ${ICECAST_PID}) died unexpectedly!"
        bashio::log.error "Checking error log..."
        if [ -f /var/log/icecast2/error.log ]; then
            tail -20 /var/log/icecast2/error.log | while IFS= read -r line; do
                bashio::log.error "  ${line}"
            done
        fi
        kill ${DARKICE_PID} 2>/dev/null
        exit 1
    fi

    # Check Darkice
    if ! kill -0 ${DARKICE_PID} 2>/dev/null; then
        bashio::log.warning "Darkice process (PID ${DARKICE_PID}) died, attempting restart..."
        sleep 2
        darkice -c /etc/darkice.cfg &
        DARKICE_PID=$!
        bashio::log.info "Darkice restarted with new PID ${DARKICE_PID}"
    fi

    # Periodic status update (every ~5 minutes)
    MONITOR_COUNT=$((MONITOR_COUNT + 1))
    if [ $((MONITOR_COUNT % 30)) -eq 0 ]; then
        bashio::log.info "Status: Streaming active (Icecast PID: ${ICECAST_PID}, Darkice PID: ${DARKICE_PID})"
    fi

    sleep 10
done
