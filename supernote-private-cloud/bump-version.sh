#!/bin/bash

# Version bump script for Supernote Private Cloud Add-on
# Usage: ./bump-version.sh [patch|minor|major] [optional-custom-version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to get current version from config.yaml
get_current_version() {
    grep '"version":' "${SCRIPT_DIR}/config.yaml" | sed 's/.*"version": "\([^"]*\)".*/\1/'
}

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}
    
    case $type in
        "patch")
            patch=$((patch + 1))
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        *)
            echo -e "${RED}Invalid version type. Use: patch, minor, or major${NC}"
            exit 1
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to update version in files
update_version() {
    local old_version=$1
    local new_version=$2
    
    echo -e "${YELLOW}Updating version from ${old_version} to ${new_version}${NC}"
    
    # Update config.yaml
    sed -i.bak "s/\"version\": \"${old_version}\"/\"version\": \"${new_version}\"/" "${SCRIPT_DIR}/config.yaml"
    
    # Update Dockerfile
    sed -i.bak "s/io\.hass\.version=\"${old_version}\"/io.hass.version=\"${new_version}\"/" "${SCRIPT_DIR}/Dockerfile"
    
    # Update run.sh
    sed -i.bak "s/v${old_version}/v${new_version}/" "${SCRIPT_DIR}/run.sh"
    
    # Update README.md
    sed -i.bak "s/version-${old_version}-green/version-${new_version}-green/" "${SCRIPT_DIR}/README.md"
    
    # Clean up backup files
    rm -f "${SCRIPT_DIR}/config.yaml.bak"
    rm -f "${SCRIPT_DIR}/Dockerfile.bak"
    rm -f "${SCRIPT_DIR}/run.sh.bak"
    rm -f "${SCRIPT_DIR}/README.md.bak"
    
    echo -e "${GREEN}✓ Updated config.yaml${NC}"
    echo -e "${GREEN}✓ Updated Dockerfile${NC}"
    echo -e "${GREEN}✓ Updated run.sh${NC}"
    echo -e "${GREEN}✓ Updated README.md${NC}"
}

# Main logic
main() {
    local current_version
    local new_version
    local version_type=${1:-patch}
    local custom_version=$2
    
    current_version=$(get_current_version)
    
    if [[ -z "$current_version" ]]; then
        echo -e "${RED}Could not find current version in config.yaml${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Current version: ${current_version}${NC}"
    
    if [[ -n "$custom_version" ]]; then
        # Use custom version if provided
        new_version=$custom_version
        echo -e "${YELLOW}Using custom version: ${new_version}${NC}"
    else
        # Increment version based on type
        new_version=$(increment_version "$current_version" "$version_type")
        echo -e "${YELLOW}Incrementing ${version_type} version to: ${new_version}${NC}"
    fi
    
    # Validate new version format
    if [[ ! $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Invalid version format: ${new_version}. Use semantic versioning (e.g., 1.2.3)${NC}"
        exit 1
    fi
    
    # Update all files
    update_version "$current_version" "$new_version"
    
    echo -e "${GREEN}✓ Version bump complete: ${current_version} → ${new_version}${NC}"
    echo -e "${YELLOW}Files updated:${NC}"
    echo "  - config.yaml"
    echo "  - Dockerfile"
    echo "  - run.sh"
    echo "  - README.md"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review the changes"
    echo "  2. Commit the version bump"
    echo "  3. Create a git tag: git tag v${new_version}"
    echo "  4. Push changes and tag: git push && git push --tags"
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [patch|minor|major] [custom-version]"
    echo ""
    echo "Version types:"
    echo "  patch  - Increment patch version (1.2.3 → 1.2.4)"
    echo "  minor  - Increment minor version (1.2.3 → 1.3.0)"
    echo "  major  - Increment major version (1.2.3 → 2.0.0)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Bump patch version"
    echo "  $0 minor              # Bump minor version"
    echo "  $0 major              # Bump major version"
    echo "  $0 patch 1.2.4       # Set specific version"
    exit 0
fi

main "$@"