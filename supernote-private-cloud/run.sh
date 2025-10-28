#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# ==============================================================================
# Home Assistant Add-on: Supernote Private Cloud
# Runs the official Supernote Private Cloud installation script
# ==============================================================================

# Default Constants
DEFAULT_INSTALL_URL="https://supernote-private-cloud.supernote.com/cloud/install.sh"
DEFAULT_DATA_DIR="/share/supernote"

# Runtime variables (set during configuration)
INSTALL_URL=""
DATA_DIR=""
LOG_FILE=""

# ==============================================================================
# LOGGING
# ==============================================================================

# Initialize logging
init_logging() {
    # DATA_DIR and LOG_FILE will be set in load_config()
    bashio::log.info "Supernote Private Cloud Add-on starting..."
}

# Setup log file after configuration is loaded
setup_logging() {
    mkdir -p "${DATA_DIR}"
    echo "=== Supernote Private Cloud Add-on started $(date) ===" > "${LOG_FILE}"
}

# Enhanced logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to Home Assistant
    case $level in
        "ERROR") bashio::log.error "${message}" ;;
        "WARN") bashio::log.warning "${message}" ;;
        "INFO") bashio::log.info "${message}" ;;
        "DEBUG") bashio::log.debug "${message}" ;;
        *) bashio::log.info "${message}" ;;
    esac
    
    # Log to file
    echo "[$timestamp] [$level] ${message}" >> "${LOG_FILE}"
}

# ==============================================================================
# CONFIGURATION
# ==============================================================================

load_config() {
    bashio::log.info "Loading add-on configuration..."
    
    # Get configuration options
    local install_url
    local auto_update
    local log_level
    local data_directory
    
    install_url=$(bashio::config 'install_url')
    auto_update=$(bashio::config 'auto_update')
    log_level=$(bashio::config 'log_level')
    data_directory=$(bashio::config 'data_directory')
    
    # Set runtime variables
    INSTALL_URL="${install_url:-$DEFAULT_INSTALL_URL}"
    AUTO_UPDATE="${auto_update:-true}"
    LOG_LEVEL="${log_level:-info}"
    DATA_DIR="${data_directory:-$DEFAULT_DATA_DIR}"
    LOG_FILE="${DATA_DIR}/addon.log"
    
    # Export for use in script
    export INSTALL_URL
    export AUTO_UPDATE
    export LOG_LEVEL
    export DATA_DIR
    
    log_message "INFO" "Configuration loaded - Install URL: ${INSTALL_URL}"
    log_message "INFO" "Data directory: ${DATA_DIR}"
}

# ==============================================================================
# DOCKER SETUP
# ==============================================================================

setup_docker() {
    bashio::log.info "Setting up Docker environment..."
    
    # Start Docker daemon if not running
    if ! pgrep dockerd > /dev/null; then
        log_message "INFO" "Starting Docker daemon..."
        dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 &
        
        # Wait for Docker to be ready
        local max_attempts=30
        local attempt=0
        while [ $attempt -lt $max_attempts ]; do
            if docker info &>/dev/null; then
                log_message "INFO" "Docker daemon is ready"
                break
            fi
            sleep 2
            ((attempt++))
        done
        
        if [ $attempt -eq $max_attempts ]; then
            log_message "ERROR" "Docker daemon failed to start"
            exit 1
        fi
    else
        log_message "INFO" "Docker daemon is already running"
    fi
}

# ==============================================================================
# INSTALL SCRIPT EXECUTION
# ==============================================================================

download_install_script() {
    bashio::log.info "Downloading Supernote Private Cloud installation script..."
    
    cd "${DATA_DIR}" || exit 1
    
    # Download the install script
    if ! curl -fsSL "${INSTALL_URL}" -o install.sh; then
        log_message "ERROR" "Failed to download installation script from ${INSTALL_URL}"
        exit 1
    fi
    
    # Make it executable
    chmod +x install.sh
    
    log_message "INFO" "Installation script downloaded successfully"
}

run_install_script() {
    bashio::log.info "Executing Supernote Private Cloud installation script..."
    
    cd "${DATA_DIR}" || exit 1
    
    # Set environment variables that the script expects
    export DEBIAN_FRONTEND=noninteractive
    export TERM=xterm
    
    # Run the installation script
    if ./install.sh 2>&1 | tee -a "${LOG_FILE}"; then
        log_message "INFO" "Supernote Private Cloud installation completed successfully"
    else
        log_message "ERROR" "Installation script failed"
        exit 1
    fi
}

# ==============================================================================
# SERVICE MONITORING
# ==============================================================================

wait_for_services() {
    bashio::log.info "Waiting for Supernote services to be ready..."
    
    local services=("9888" "8080" "19071" "6000")
    local max_attempts=60
    
    for port in "${services[@]}"; do
        local attempt=0
        bashio::log.info "Checking service on port ${port}..."
        
        while [ $attempt -lt $max_attempts ]; do
            if nc -z localhost "${port}" 2>/dev/null; then
                log_message "INFO" "Service on port ${port} is ready"
                break
            fi
            sleep 5
            ((attempt++))
        done
        
        if [ $attempt -eq $max_attempts ]; then
            log_message "WARN" "Service on port ${port} not ready after timeout"
        fi
    done
}

monitor_services() {
    bashio::log.info "Starting service monitoring..."
    
    while true; do
        # Check if docker-compose services are running
        cd "${DATA_DIR}" || exit 1
        
        if [ -f "docker-compose.yml" ]; then
            # Check service status
            if ! docker-compose ps -q | xargs docker inspect -f '{{.State.Running}}' | grep -q false; then
                log_message "DEBUG" "All services are running"
            else
                log_message "WARN" "Some services are not running, attempting restart..."
                docker-compose restart
            fi
        fi
        
        # Sleep for 5 minutes between checks
        sleep 300
    done
}

# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

cleanup() {
    bashio::log.info "Shutting down Supernote Private Cloud..."
    
    cd "${DATA_DIR}" || exit 1
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose down --timeout 30 2>/dev/null || true
    fi
    
    # Stop Docker daemon if we started it
    if pgrep dockerd >/dev/null; then
        pkill dockerd 2>/dev/null || true
    fi
    
    log_message "INFO" "Shutdown completed"
    exit 0
}

# Set signal handlers
trap cleanup SIGTERM SIGINT

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    bashio::log.info "Starting Supernote Private Cloud Add-on v1.2.0"
    
    # Initialize
    init_logging
    load_config
    setup_logging
    setup_docker
    
    # Check if already installed
    if [ -f "${DATA_DIR}/docker-compose.yml" ] && [ "${AUTO_UPDATE}" = "false" ]; then
        log_message "INFO" "Supernote Private Cloud is already installed, starting services..."
        cd "${DATA_DIR}" || exit 1
        docker-compose up -d
    else
        # Download and run install script
        download_install_script
        run_install_script
    fi
    
    # Wait for services to be ready
    wait_for_services
    
    # Show access information
    local host_ip
    host_ip=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    bashio::log.info "=== Supernote Private Cloud is running ==="
    bashio::log.info "Web Interface: http://${host_ip}:9888"
    bashio::log.info "API Service: http://${host_ip}:8080"
    bashio::log.info "Backend Service: http://${host_ip}:19071"
    bashio::log.info "Note Library: http://${host_ip}:6000"
    bashio::log.info "============================================"
    
    # Start monitoring services
    monitor_services
}

# Start main function
main "$@"