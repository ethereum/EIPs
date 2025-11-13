#!/bin/bash
# EIP Validation Script
# Quick validation utility for EIPs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if eipw is installed
if ! command -v eipw &> /dev/null; then
    echo -e "${RED}Error: eipw is not installed${NC}"
    echo "Install it with: cargo install eipw"
    echo "Make sure to add ~/.cargo/bin to your PATH"
    exit 1
fi

# Get the repository root (assuming script is in scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/eipw.toml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

# Function to validate a single file
validate_file() {
    local file="$1"
    echo -e "${YELLOW}Validating: $file${NC}"
    
    if eipw --config "$CONFIG_FILE" "$file"; then
        echo -e "${GREEN}✓ $file passed validation${NC}"
        return 0
    else
        echo -e "${RED}✗ $file failed validation${NC}"
        return 1
    fi
}

# Main logic
if [ $# -eq 0 ]; then
    # No arguments: validate all EIPs
    echo -e "${YELLOW}Validating all EIPs...${NC}"
    eipw --config "$CONFIG_FILE" "$REPO_ROOT/EIPS/"
else
    # Validate specific file(s)
    failed=0
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}Error: File not found: $file${NC}"
            failed=1
            continue
        fi
        if ! validate_file "$file"; then
            failed=1
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All files passed validation!${NC}"
        exit 0
    else
        echo -e "${RED}Some files failed validation${NC}"
        exit 1
    fi
fi

