#!/bin/bash

# Commit Message Preparation Script
# Usage: ./prepare-commit.sh [type] [description]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "Commit Message Preparation Script"
    echo ""
    echo "Usage: $0 [type] [description]"
    echo ""
    echo "Types:"
    echo "  feat     - New feature"
    echo "  fix      - Bug fix"
    echo "  docs     - Documentation changes"
    echo "  style    - Code style changes (formatting, etc.)"
    echo "  refactor - Code refactoring"
    echo "  test     - Adding or updating tests"
    echo "  chore    - Maintenance tasks"
    echo "  perf     - Performance improvements"
    echo "  build    - Build system changes"
    echo "  ci       - CI/CD changes"
    echo ""
    echo "Examples:"
    echo "  $0 fix \"Docker daemon startup issues\""
    echo "  $0 feat \"Add automatic version bumping\""
    echo "  $0 docs \"Update README with new features\""
}

get_changed_files() {
    # Get staged files
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || echo "")
    
    if [[ -z "$staged_files" ]]; then
        # If no staged files, get modified files
        staged_files=$(git diff --name-only 2>/dev/null || echo "")
    fi
    
    echo "$staged_files"
}

get_version() {
    grep '"version":' config.yaml | sed 's/.*"version": "\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown"
}

generate_conventional_commit() {
    local type="$1"
    local description="$2"
    local changed_files
    changed_files=$(get_changed_files)
    local version
    version=$(get_version)
    
    # Validate type
    case "$type" in
        feat|fix|docs|style|refactor|test|chore|perf|build|ci)
            ;;
        *)
            echo -e "${RED}Invalid commit type: $type${NC}"
            show_help
            exit 1
            ;;
    esac
    
    # Generate commit message
    local commit_msg="${type}: ${description}

Version: ${version}

Files changed:"
    
    # Add changed files to message
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            commit_msg="${commit_msg}
- ${file}"
        fi
    done <<< "$changed_files"
    
    # Add scope if it's add-on related
    if echo "$changed_files" | grep -qE "(run\.sh|Dockerfile|config\.yaml)"; then
        commit_msg="${type}(addon): ${description}

Version: ${version}

Core files changed:"
        while IFS= read -r file; do
            if [[ -n "$file" ]] && echo "$file" | grep -qE "(run\.sh|Dockerfile|config\.yaml)"; then
                commit_msg="${commit_msg}
- ${file}"
            fi
        done <<< "$changed_files"
        
        if echo "$changed_files" | grep -vqE "(run\.sh|Dockerfile|config\.yaml)"; then
            commit_msg="${commit_msg}

Other files changed:"
            while IFS= read -r file; do
                if [[ -n "$file" ]] && echo "$file" | grep -vqE "(run\.sh|Dockerfile|config\.yaml)"; then
                    commit_msg="${commit_msg}
- ${file}"
                fi
            done <<< "$changed_files"
        fi
    fi
    
    echo "$commit_msg"
}

interactive_mode() {
    echo -e "${BLUE}=== Interactive Commit Message Generator ===${NC}"
    echo ""
    
    # Show current status
    local version
    version=$(get_version)
    echo -e "${YELLOW}Current version: ${version}${NC}"
    
    local changed_files
    changed_files=$(get_changed_files)
    if [[ -n "$changed_files" ]]; then
        echo -e "${YELLOW}Changed files:${NC}"
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                echo "  - $file"
            fi
        done <<< "$changed_files"
    else
        echo -e "${YELLOW}No changed files detected${NC}"
    fi
    
    echo ""
    
    # Get commit type
    echo -e "${BLUE}Select commit type:${NC}"
    echo "1) feat     - New feature"
    echo "2) fix      - Bug fix"
    echo "3) docs     - Documentation changes"
    echo "4) refactor - Code refactoring"
    echo "5) chore    - Maintenance tasks"
    echo "6) style    - Code style changes"
    echo "7) perf     - Performance improvements"
    echo "8) test     - Adding tests"
    echo "9) build    - Build system changes"
    echo "10) ci      - CI/CD changes"
    echo ""
    
    read -p "Enter choice (1-10): " choice
    
    case $choice in
        1) type="feat" ;;
        2) type="fix" ;;
        3) type="docs" ;;
        4) type="refactor" ;;
        5) type="chore" ;;
        6) type="style" ;;
        7) type="perf" ;;
        8) type="test" ;;
        9) type="build" ;;
        10) type="ci" ;;
        *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
    esac
    
    # Get description
    echo ""
    read -p "Enter commit description: " description
    
    if [[ -z "$description" ]]; then
        echo -e "${RED}Description cannot be empty${NC}"
        exit 1
    fi
    
    # Generate and show message
    local commit_msg
    commit_msg=$(generate_conventional_commit "$type" "$description")
    
    echo ""
    echo -e "${GREEN}Generated commit message:${NC}"
    echo "----------------------------------------"
    echo "$commit_msg"
    echo "----------------------------------------"
    echo ""
    
    # Ask if user wants to save it
    read -p "Save this commit message? (y/N): " save_choice
    
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        echo "$commit_msg" > .git/COMMIT_EDITMSG
        echo -e "${GREEN}✓ Commit message saved to .git/COMMIT_EDITMSG${NC}"
        echo "You can now run: git commit --file=.git/COMMIT_EDITMSG"
    else
        echo -e "${YELLOW}Commit message not saved${NC}"
    fi
}

# Main logic
if [[ $# -eq 0 ]]; then
    interactive_mode
elif [[ $# -eq 2 ]]; then
    commit_msg=$(generate_conventional_commit "$1" "$2")
    echo "$commit_msg" > .git/COMMIT_EDITMSG
    echo -e "${GREEN}✓ Commit message generated and saved${NC}"
    echo "Run: git commit --file=.git/COMMIT_EDITMSG"
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
else
    echo -e "${RED}Invalid arguments${NC}"
    show_help
    exit 1
fi