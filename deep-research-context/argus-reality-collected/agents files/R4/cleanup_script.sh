#!/bin/bash

# Script to remove assumption-based R4-INTEGRATION-REALITY comments
# Preserve comments with genuine MCP evidence

SPECS_DIR="/Users/m/Documents/wfm/main/project/specs/working"

echo "=== R4 Comment Cleanup: Removing Assumption-Based Comments ==="

# Files with genuine MCP evidence to preserve
PRESERVE_FILES=(
    "11-mcp-verified-scenarios.feature"
    "21-1c-zup-integration.feature"
)

# Function to check if file should be preserved
should_preserve() {
    local file=$1
    for preserve_file in "${PRESERVE_FILES[@]}"; do
        if [[ "$file" == *"$preserve_file" ]]; then
            echo "PRESERVING: $file (contains genuine MCP evidence)"
            return 0
        fi
    done
    return 1
}

# Count total R4 comments before cleanup
echo "Counting R4 comments before cleanup..."
TOTAL_BEFORE=$(grep -r "R4-INTEGRATION-REALITY" "$SPECS_DIR" | wc -l)
echo "Total R4 comments found: $TOTAL_BEFORE"

# Process each file with R4 comments
for file in $(find "$SPECS_DIR" -name "*.feature" -exec grep -l "R4-INTEGRATION-REALITY" {} \;); do
    filename=$(basename "$file")
    
    if should_preserve "$file"; then
        continue
    fi
    
    echo "Processing: $filename"
    
    # Count comments in this file
    comment_count=$(grep -c "R4-INTEGRATION-REALITY" "$file")
    echo "  - Found $comment_count R4 comments"
    
    # Create backup
    cp "$file" "$file.r4-backup"
    
    # Remove R4 comment blocks (from R4-INTEGRATION-REALITY to next @tag or blank line)
    sed -i '' '/^[[:space:]]*# R4-INTEGRATION-REALITY/,/^[[:space:]]*# @[a-z-]*$/d' "$file"
    
    # Also remove any standalone R4 lines
    sed -i '' '/^[[:space:]]*# R4-INTEGRATION-REALITY/d' "$file"
    
    # Count remaining comments
    remaining=$(grep -c "R4-INTEGRATION-REALITY" "$file" 2>/dev/null || echo "0")
    removed=$((comment_count - remaining))
    echo "  - Removed $removed assumption-based comments"
done

# Count total R4 comments after cleanup
echo ""
echo "Counting R4 comments after cleanup..."
TOTAL_AFTER=$(grep -r "R4-INTEGRATION-REALITY" "$SPECS_DIR" | wc -l)
echo "Total R4 comments remaining: $TOTAL_AFTER"
echo "Total R4 comments removed: $((TOTAL_BEFORE - TOTAL_AFTER))"

echo ""
echo "✅ Cleanup complete!"
echo "Assumption-based comments removed, genuine MCP evidence preserved"