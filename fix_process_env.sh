#!/bin/bash

# Fix all process.env issues in UI files
echo "🔧 Fixing process.env issues in UI files..."

# Find all TypeScript/TSX files and fix process.env
find src/ui/src -name "*.tsx" -o -name "*.ts" | while read file; do
    if grep -q "process\.env\.REACT_APP_API_URL" "$file"; then
        echo "Fixing: $file"
        sed -i.bak 's/process\.env\.REACT_APP_API_URL/import.meta.env.VITE_API_URL/g' "$file"
        sed -i.bak 's/http:\/\/localhost:8000/http:\/\/localhost:8001/g' "$file"
    fi
done

# Clean up backup files
find src/ui/src -name "*.bak" -delete

echo "✅ Fixed all process.env issues!"
echo "🚀 Now run: npm run dev"