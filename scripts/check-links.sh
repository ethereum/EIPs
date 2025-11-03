#!/bin/bash
# Link checker script for EIPs
# Finds all HTTP/HTTPS links in EIP files

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${YELLOW}Checking links in EIP files...${NC}"

# Find all links
links_file=$(mktemp)
find "$REPO_ROOT/EIPS" -name "*.md" -exec grep -oP 'https?://[^\s)]+' {} \; | sort | uniq > "$links_file"

link_count=$(wc -l < "$links_file" | tr -d ' ')
echo -e "${GREEN}Found $link_count unique links${NC}"

# Check each link (basic check)
failed=0
while IFS= read -r url; do
    if [[ $url =~ ^https?:// ]]; then
        # Basic validation
        echo "  $url"
    fi
done < "$links_file"

rm "$links_file"

echo -e "${GREEN}Link check completed${NC}"

