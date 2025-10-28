#!/bin/bash

# Auto Version Bump Management Script
# Usage: ./auto-version.sh [enable|disable|status|test]

set -e

HOOK_FILE=".git/hooks/pre-commit"
HOOK_BACKUP=".git/hooks/pre-commit.backup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    echo "Auto Version Bump Management"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  enable   - Enable automatic version bumping on commits"
    echo "  disable  - Disable automatic version bumping"
    echo "  status   - Show current status"
    echo "  test     - Test the version bump without committing"
    echo "  commit   - Interactive commit message generator"
    echo "  help     - Show this help message"
    echo ""
    echo "When enabled, version will be automatically bumped when you commit"
    echo "changes to: run.sh, Dockerfile, or config.yaml"
    echo ""
    echo "The system also auto-generates conventional commit messages"
}

enable_auto_version() {
    if [[ -f "$HOOK_FILE" ]]; then
        echo -e "${YELLOW}Pre-commit hook already exists${NC}"
        echo -e "${GREEN}✓ Auto-version bump is already enabled${NC}"
    else
        echo -e "${RED}✗ Pre-commit hook not found${NC}"
        echo "Please ensure the hook file exists at: $HOOK_FILE"
        exit 1
    fi
    
    chmod +x "$HOOK_FILE"
    echo -e "${GREEN}✓ Auto-version bump enabled${NC}"
    echo "Version will be automatically bumped when you commit changes to core files"
}

disable_auto_version() {
    if [[ -f "$HOOK_FILE" ]]; then
        if [[ -f "$HOOK_BACKUP" ]]; then
            rm "$HOOK_BACKUP"
        fi
        mv "$HOOK_FILE" "$HOOK_BACKUP"
        echo -e "${GREEN}✓ Auto-version bump disabled${NC}"
        echo "Hook backed up to: $HOOK_BACKUP"
    else
        echo -e "${YELLOW}Auto-version bump is already disabled${NC}"
    fi
}

show_status() {
    if [[ -f "$HOOK_FILE" ]] && [[ -x "$HOOK_FILE" ]]; then
        echo -e "${GREEN}✓ Auto-version bump is ENABLED${NC}"
        echo "Core files that trigger version bumps:"
        echo "  - run.sh"
        echo "  - Dockerfile" 
        echo "  - config.yaml"
    else
        echo -e "${RED}✗ Auto-version bump is DISABLED${NC}"
    fi
    
    echo ""
    echo "Current version: $(grep '"version":' config.yaml | sed 's/.*"version": "\([^"]*\)".*/\1/')"
}

test_version_bump() {
    echo -e "${YELLOW}Testing version bump (dry run)...${NC}"
    
    if ./bump-version.sh patch; then
        echo -e "${GREEN}✓ Version bump test successful${NC}"
        
        # Revert the test changes
        git checkout -- config.yaml Dockerfile run.sh README.md 2>/dev/null || true
        echo -e "${YELLOW}✓ Test changes reverted${NC}"
    else
        echo -e "${RED}✗ Version bump test failed${NC}"
        exit 1
    fi
}

case "${1:-help}" in
    "enable")
        enable_auto_version
        ;;
    "disable")
        disable_auto_version
        ;;
    "status")
        show_status
        ;;
    "test")
        test_version_bump
        ;;
    "commit")
        if [[ -x "./prepare-commit.sh" ]]; then
            ./prepare-commit.sh
        else
            echo -e "${RED}prepare-commit.sh not found or not executable${NC}"
            exit 1
        fi
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac