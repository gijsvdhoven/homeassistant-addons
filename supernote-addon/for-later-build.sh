#!/bin/bash
# Build script for Supernote Private Cloud Home Assistant Add-on
# Usage: ./build.sh [arch]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ADDON_NAME="supernote_private_cloud"
VERSION=$(grep "version:" config.yaml | awk '{print $2}' | tr -d '"')
ARCHITECTURES=("amd64" "aarch64" "armv7" "armhf" "i386")

log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to build for specific architecture
build_arch() {
    local arch=$1
    local image_name="ghcr.io/supernote-community/${arch}-${ADDON_NAME}:${VERSION}"
    
    log "Building ${ADDON_NAME} for ${arch}..."
    
    # Build the image
    docker build \
        --build-arg BUILD_FROM="homeassistant/${arch}-base:latest" \
        --build-arg BUILD_ARCH="${arch}" \
        --build-arg BUILD_VERSION="${VERSION}" \
        --platform "linux/${arch}" \
        --tag "${image_name}" \
        .
    
    if [ $? -eq 0 ]; then
        log "Successfully built ${image_name}"
        return 0
    else
        error "Failed to build ${image_name}"
        return 1
    fi
}

# Function to build all architectures
build_all() {
    log "Building ${ADDON_NAME} v${VERSION} for all architectures..."
    
    local success_count=0
    local total_count=${#ARCHITECTURES[@]}
    
    for arch in "${ARCHITECTURES[@]}"; do
        if build_arch "$arch"; then
            ((success_count++))
        fi
    done
    
    log "Build completed: ${success_count}/${total_count} architectures successful"
    
    if [ $success_count -eq $total_count ]; then
        log "All builds successful!"
        return 0
    else
        error "Some builds failed!"
        return 1
    fi
}

# Function to validate configuration
validate_config() {
    log "Validating configuration..."
    
    # Check if required files exist
    local required_files=(
        "config.yaml"
        "Dockerfile"
        "README.md"
        "CHANGELOG.md"
        "LICENSE"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            error "Required file missing: $file"
            return 1
        fi
    done
    
    # Validate config.yaml syntax
    if ! command -v yq &> /dev/null; then
        warn "yq not found, skipping YAML validation"
    else
        if ! yq eval '.' config.yaml > /dev/null; then
            error "Invalid YAML syntax in config.yaml"
            return 1
        fi
    fi
    
    log "Configuration validation passed"
    return 0
}

# Function to show usage
show_usage() {
    echo "Supernote Private Cloud Add-on Build Script"
    echo ""
    echo "Usage: $0 [COMMAND] [ARCH]"
    echo ""
    echo "Commands:"
    echo "  build [ARCH]     Build for specific architecture (or all if not specified)"
    echo "  validate         Validate configuration files"
    echo "  clean            Clean build artifacts"
    echo "  help             Show this help message"
    echo ""
    echo "Architectures:"
    for arch in "${ARCHITECTURES[@]}"; do
        echo "  - $arch"
    done
    echo ""
    echo "Examples:"
    echo "  $0 build amd64   # Build for amd64 only"
    echo "  $0 build         # Build for all architectures"
    echo "  $0 validate      # Validate configuration"
    echo ""
}

# Function to clean build artifacts
clean_build() {
    log "Cleaning build artifacts..."
    
    # Remove Docker images
    local images=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "supernote-community.*${ADDON_NAME}" || true)
    if [ -n "$images" ]; then
        echo "$images" | xargs docker rmi 2>/dev/null || true
        log "Removed Docker images"
    else
        info "No Docker images found to clean"
    fi
    
    # Clean Docker build cache
    docker builder prune -f
    
    log "Build cleanup completed"
}

# Main function
main() {
    local command="${1:-build}"
    local arch="${2:-}"
    
    case "$command" in
        "build")
            if ! validate_config; then
                exit 1
            fi
            
            if [ -n "$arch" ]; then
                if [[ " ${ARCHITECTURES[@]} " =~ " ${arch} " ]]; then
                    build_arch "$arch"
                else
                    error "Unsupported architecture: $arch"
                    echo "Supported architectures: ${ARCHITECTURES[*]}"
                    exit 1
                fi
            else
                build_all
            fi
            ;;
        "validate")
            validate_config
            ;;
        "clean")
            clean_build
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    error "Docker is required but not found in PATH"
    exit 1
fi

# Run main function
main "$@"