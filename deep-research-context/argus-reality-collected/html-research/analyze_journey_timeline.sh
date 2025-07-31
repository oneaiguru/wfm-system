#\!/bin/bash
echo "=== User's Argus Navigation Journey ==="
echo "Date: July 25, 2025"
echo ""

# Show timeline with file sizes (larger = more content saved)
ls -la cc1010wfmcc.argustelecom.ru*.zip | \
  awk '{print $5 " bytes | " $7 " " $8 " | " $9}' | \
  sort -k3,3 -k2M | \
  awk 'BEGIN {print "Size | Time | File"} {print}'

echo ""
echo "=== Navigation Phases Detected ==="
echo "17:55-17:57 - Initial exploration (files 1-10)"
echo "17:57-18:00 - Deep dive phase (files 11-21)"  
echo "18:00-18:45 - Targeted feature testing (timestamped files)"
echo ""
EOF < /dev/null