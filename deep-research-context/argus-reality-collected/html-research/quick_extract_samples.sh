#!/bin/bash
# Quick extraction of key files for R-agents to start exploring

echo "Extracting sample HTML files for R-agent exploration..."

# Create temp folder
mkdir -p samples

# Extract from first few zips to get variety
for i in 1 2 10 20 30 40 50; do
  echo "Checking zip $i..."
  
  # Extract just the View files
  unzip -j "cc1010wfmcc.argustelecom.ru ($i).zip" "*View.xhtml" -d samples/ 2>/dev/null || true
done

# Also check dated zips for different content
unzip -j "cc1010wfmcc.argustelecom.ru - 2025-07-25T183431.449.zip" "*View.xhtml" -d samples/ 2>/dev/null || true

# List what we found
echo "=== Sample files extracted ==="
ls -la samples/*.xhtml 2>/dev/null | wc -l
echo "files found"

echo ""
echo "=== File list ==="
ls samples/*.xhtml 2>/dev/null | head -20

echo ""
echo "R-agents can now explore these files in samples/ folder"