#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Global error handler
handle_error() {
    local exit_code=$?
    local line_number=$1
    bashio::log.error "Script failed at line ${line_number} with exit code ${exit_code}"
    bashio::log.error "Last command: ${BASH_COMMAND}"
    
    # Try to cleanup
    cleanup 2>/dev/null || true
    exit $exit_code
}

# Set error trap
trap 'handle_error ${LINENO}' ERR

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
    
    # Log to file only if LOG_FILE is set and directory exists
    if [[ -n "$LOG_FILE" ]] && [[ -n "$DATA_DIR" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
        echo "[$timestamp] [$level] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
    fi
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
    
    # Check Docker installation
    if ! command -v docker >/dev/null 2>&1; then
        log_message "ERROR" "Docker command not found"
        exit 1
    fi
    
    if ! command -v dockerd >/dev/null 2>&1; then
        log_message "ERROR" "Docker daemon not found"
        exit 1
    fi
    
    log_message "INFO" "Docker version: $(docker --version 2>/dev/null || echo 'unknown')"
    
    # Create necessary Docker directories
    mkdir -p /var/lib/docker
    mkdir -p /var/run
    
    # Start Docker daemon if not running
    if ! pgrep dockerd > /dev/null; then
        log_message "INFO" "Starting Docker daemon..."
        
        # Create a temporary log file for Docker daemon
        local docker_log="/tmp/dockerd.log"
        
        # Start Docker daemon with configuration optimized for containers
        dockerd \
            --host=unix:///var/run/docker.sock \
            --data-root=/var/lib/docker \
            --storage-driver=vfs \
            --exec-opt native.cgroupdriver=cgroupfs \
            --iptables=false \
            --bridge=none \
            --tls=false \
            --log-level=info \
            --pidfile=/var/run/dockerd.pid \
            > "${docker_log}" 2>&1 &
        
        local dockerd_pid=$!
        log_message "INFO" "Docker daemon started with PID: ${dockerd_pid}"
        
        # Give Docker a moment to initialize
        sleep 5
        
        # Check if Docker daemon is still running after initial startup
        if ! kill -0 "${dockerd_pid}" 2>/dev/null; then
            log_message "ERROR" "Docker daemon died during startup"
            log_message "ERROR" "Docker daemon logs:"
            cat "${docker_log}" 2>/dev/null || echo "No logs available"
            exit 1
        fi
        
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
            
            # Check if dockerd process is still running
            if ! kill -0 "${dockerd_pid}" 2>/dev/null; then
                log_message "ERROR" "Docker daemon process died during wait"
                log_message "ERROR" "Docker daemon logs:"
                cat "${docker_log}" 2>/dev/null || echo "No logs available"
                exit 1
            fi
            
            if [ $((attempt % 5)) -eq 0 ]; then
                log_message "INFO" "Still waiting for Docker daemon... (attempt ${attempt}/${max_attempts})"
                # Show recent Docker logs for debugging
                log_message "INFO" "Recent Docker logs:"
                tail -5 "${docker_log}" 2>/dev/null || echo "No recent logs"
            fi
        done
        
        if [ $attempt -eq $max_attempts ]; then
            log_message "ERROR" "Docker daemon failed to start within timeout"
            log_message "ERROR" "Final Docker daemon logs:"
            cat "${docker_log}" 2>/dev/null || echo "No logs available"
            exit 1
        fi
        # Clean up temporary log file
        rm -f "${docker_log}"
    else
        log_message "INFO" "Docker daemon is already running"
        # Test if we can connect to it
        if ! docker info &>/dev/null; then
            log_message "WARN" "Docker daemon is running but not responding, attempting restart..."
            pkill dockerd 2>/dev/null || true
            sleep 5
            # Recursive call to restart
            setup_docker
            return
        fi
    fi
    
    # Final verification that Docker is working
    log_message "INFO" "Verifying Docker functionality..."
    if ! docker version >/dev/null 2>&1; then
        log_message "ERROR" "Docker is not responding to commands"
        exit 1
    fi
    
    log_message "INFO" "Docker setup completed successfully"
}

# ==============================================================================
# INSTALL SCRIPT EXECUTION
# ==============================================================================

download_install_script() {
    bashio::log.info "Downloading Supernote Private Cloud installation script..."
    
    cd "${DATA_DIR}" || exit 1
    
    # Remove existing script if present
    rm -f install.sh
    
    # Download the install script using curl -O as required by security guidelines
    log_message "INFO" "Downloading script from ${INSTALL_URL}"
    if ! curl -O "${INSTALL_URL}"; then
        log_message "ERROR" "Failed to download installation script from ${INSTALL_URL}"
        exit 1
    fi
    
    # Verify the script was downloaded
    if [[ ! -f "install.sh" ]]; then
        log_message "ERROR" "Installation script not found after download"
        exit 1
    fi
    
    # Make it executable as required by security guidelines
    chmod +x install.sh
    
    log_message "INFO" "Installation script downloaded and made executable"
}

run_install_script() {
    bashio::log.info "Executing Supernote Private Cloud installation script..."
    
    cd "${DATA_DIR}" || exit 1
    
    # Verify script exists and is executable
    if [[ ! -f "install.sh" ]]; then
        log_message "ERROR" "Installation script not found"
        exit 1
    fi
    
    if [[ ! -x "install.sh" ]]; then
        log_message "ERROR" "Installation script is not executable"
        exit 1
    fi
    
    # Set environment variables that the script expects
    export DEBIAN_FRONTEND=noninteractive
    export TERM=xterm
    
    # Run the installation script locally as required by security guidelines
    log_message "INFO" "Executing local installation script: ./install.sh"
    if ./install.sh 2>&1 | tee -a "${LOG_FILE}"; then
        log_message "INFO" "Supernote Private Cloud installation completed successfully"
    else
        log_message "ERROR" "Installation script failed"
        # Show the last few lines of output for debugging
        log_message "ERROR" "Last 10 lines of installation output:"
        tail -10 "${LOG_FILE}" 2>/dev/null || echo "No log output available"
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
    
    # Stop all Docker containers first
    if command -v docker >/dev/null 2>&1; then
        cd "${DATA_DIR}" || true
        
        if [ -f "docker-compose.yml" ]; then
            log_message "INFO" "Stopping Docker Compose services..."
            docker-compose down --timeout 30 2>/dev/null || true
        fi
        
        # Stop any remaining containers
        docker stop $(docker ps -q) 2>/dev/null || true
    fi
    
    # Stop Docker daemon if we started it
    if pgrep dockerd >/dev/null; then
        log_message "INFO" "Stopping Docker daemon..."
        pkill -TERM dockerd 2>/dev/null || true
        sleep 5
        pkill -KILL dockerd 2>/dev/null || true
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
    bashio::log.info "Starting Supernote Private Cloud Add-on v1.2.2"
    
    # Initialize
    log_message "INFO" "=== Initialization Phase ==="
    init_logging
    load_config
    setup_logging
    
    log_message "INFO" "=== Docker Setup Phase ==="
    setup_docker
    
    log_message "INFO" "=== Installation Phase ==="
    # Check if already installed
    if [ -f "${DATA_DIR}/docker-compose.yml" ] && [ "${AUTO_UPDATE}" = "false" ]; then
        log_message "INFO" "Supernote Private Cloud is already installed, starting services..."
        cd "${DATA_DIR}" || exit 1
        if ! docker-compose up -d; then
            log_message "ERROR" "Failed to start existing services"
            exit 1
        fi
    else
        # Download and run install script
        download_install_script
        run_install_script
    fi
    
    log_message "INFO" "=== Service Startup Phase ==="
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