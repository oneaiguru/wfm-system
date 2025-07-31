#!/bin/bash
# BDD Scenario Extraction Tool for Registry Population

echo "# BDD Scenario Extraction Report"
echo "Generated: $(date)"
echo ""

# Find all .feature files
for feature_file in /Users/m/Documents/wfm/main/project/specs/working/*.feature; do
    if [ -f "$feature_file" ]; then
        echo "## Processing: $(basename $feature_file)"
        echo ""
        
        # Extract scenarios with line numbers
        grep -n "Scenario:" "$feature_file" | while IFS=: read -r line_num scenario; do
            # Try to extract SPEC number from scenario name
            spec_num=$(echo "$scenario" | grep -o "SPEC-[0-9]\+" || echo "SPEC-XXX")
            
            # Extract tags from previous lines
            tags=$(sed -n "$((line_num-1))p" "$feature_file" | grep -o "@[a-zA-Z_-]*" || echo "")
            
            echo "- $spec_num: ${scenario#*Scenario:}"
            echo "  File: $(basename $feature_file):$line_num"
            echo "  Tags: $tags"
            echo "  Status: ⏳ pending"
            echo ""
        done
    fi
done

echo ""
echo "## Summary"
echo "Total feature files: $(find /Users/m/Documents/wfm/main/project/specs/working -name "*.feature" | wc -l)"
echo "Total scenarios found: $(grep -h "Scenario:" /Users/m/Documents/wfm/main/project/specs/working/*.feature 2>/dev/null | wc -l)"
echo ""
echo "Next steps:"
echo "1. Review extracted scenarios"
echo "2. Update MASTER_INDEX.md with findings"
echo "3. Verify against implementation"
echo "4. Categorize by status and feature"