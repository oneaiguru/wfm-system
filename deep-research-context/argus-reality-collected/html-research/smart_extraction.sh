#!/bin/bash
# Smart HTML Extraction with Organization

echo "🚀 Starting smart extraction of 129 Argus HTML files..."

# Create organized structure
mkdir -p organized_html/{01_core_features/{authentication,employee_mgmt,calendar_vacation,scheduling},02_manager_features/{dashboards,approvals,team_views},03_analytics/{forecasts,reports,historical},04_admin/{security,configuration,system},05_metadata}

echo "📊 Phase 1: Survey and categorize zips..."

# Quick survey of content types
echo "=== ZIP CONTENT SURVEY ===" > organized_html/05_metadata/zip_survey.txt
echo "Total zips: 129" >> organized_html/05_metadata/zip_survey.txt
echo "" >> organized_html/05_metadata/zip_survey.txt

# Categorize zips
echo "Numbered zips (likely different pages):" >> organized_html/05_metadata/zip_survey.txt
ls cc1010wfmcc.argustelecom.ru\ \([0-9]*\).zip | wc -l >> organized_html/05_metadata/zip_survey.txt

echo "Dated zips (likely snapshots):" >> organized_html/05_metadata/zip_survey.txt
ls cc1010wfmcc.argustelecom.ru\ -\ 2025*.zip | wc -l >> organized_html/05_metadata/zip_survey.txt

echo "📁 Phase 2: Extract key files with deduplication..."

# Extract View files from representative zips
file_count=0

# Process numbered zips first (1, 5, 10, 15, 20, etc.)
for i in 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95; do
    if [ -f "cc1010wfmcc.argustelecom.ru ($i).zip" ]; then
        echo "Processing zip $i..."
        
        # Extract View files to temp
        unzip -j "cc1010wfmcc.argustelecom.ru ($i).zip" "*View.xhtml" -d temp_extract/ 2>/dev/null || continue
        
        # Categorize and move files
        for file in temp_extract/*.xhtml; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                
                # Skip if already extracted (deduplication)
                if [ -f "organized_html/01_core_features/authentication/$filename" ] || \
                   [ -f "organized_html/01_core_features/employee_mgmt/$filename" ] || \
                   [ -f "organized_html/01_core_features/calendar_vacation/$filename" ] || \
                   [ -f "organized_html/01_core_features/scheduling/$filename" ] || \
                   [ -f "organized_html/02_manager_features/dashboards/$filename" ] || \
                   [ -f "organized_html/02_manager_features/approvals/$filename" ] || \
                   [ -f "organized_html/02_manager_features/team_views/$filename" ] || \
                   [ -f "organized_html/03_analytics/forecasts/$filename" ] || \
                   [ -f "organized_html/03_analytics/reports/$filename" ] || \
                   [ -f "organized_html/03_analytics/historical/$filename" ] || \
                   [ -f "organized_html/04_admin/security/$filename" ] || \
                   [ -f "organized_html/04_admin/configuration/$filename" ] || \
                   [ -f "organized_html/04_admin/system/$filename" ] || \
                   [ -f "organized_html/05_metadata/$filename" ]; then
                    continue
                fi
                
                # Get file size for quality check
                filesize=$(stat -f%z "$file" 2>/dev/null || echo 0)
                
                # Categorize by filename patterns
                if [[ $filename == *"Login"* ]] || [[ $filename == *"Auth"* ]]; then
                    cp "$file" organized_html/01_core_features/authentication/
                    echo "$filename -> authentication (${filesize} bytes)"
                elif [[ $filename == *"Worker"* ]] || [[ $filename == *"Employee"* ]] || [[ $filename == *"Personnel"* ]] || [[ $filename == *"Personal"* ]]; then
                    cp "$file" organized_html/01_core_features/employee_mgmt/
                    echo "$filename -> employee_mgmt (${filesize} bytes)"
                elif [[ $filename == *"Calendar"* ]] || [[ $filename == *"Vacation"* ]] || [[ $filename == *"Request"* ]] || [[ $filename == *"Vacancy"* ]]; then
                    cp "$file" organized_html/01_core_features/calendar_vacation/
                    echo "$filename -> calendar_vacation (${filesize} bytes)"
                elif [[ $filename == *"Schedule"* ]] || [[ $filename == *"Planning"* ]] || [[ $filename == *"Shift"* ]]; then
                    cp "$file" organized_html/01_core_features/scheduling/
                    echo "$filename -> scheduling (${filesize} bytes)"
                elif [[ $filename == *"Dashboard"* ]] || [[ $filename == *"Monitoring"* ]] || [[ $filename == *"Operating"* ]]; then
                    cp "$file" organized_html/02_manager_features/dashboards/
                    echo "$filename -> dashboards (${filesize} bytes)"
                elif [[ $filename == *"Approval"* ]] || [[ $filename == *"Pending"* ]]; then
                    cp "$file" organized_html/02_manager_features/approvals/
                    echo "$filename -> approvals (${filesize} bytes)"
                elif [[ $filename == *"Team"* ]] || [[ $filename == *"Group"* ]]; then
                    cp "$file" organized_html/02_manager_features/team_views/
                    echo "$filename -> team_views (${filesize} bytes)"
                elif [[ $filename == *"Forecast"* ]] || [[ $filename == *"Predict"* ]]; then
                    cp "$file" organized_html/03_analytics/forecasts/
                    echo "$filename -> forecasts (${filesize} bytes)"
                elif [[ $filename == *"Report"* ]] || [[ $filename == *"Analytics"* ]]; then
                    cp "$file" organized_html/03_analytics/reports/
                    echo "$filename -> reports (${filesize} bytes)"
                elif [[ $filename == *"Historical"* ]] || [[ $filename == *"History"* ]]; then
                    cp "$file" organized_html/03_analytics/historical/
                    echo "$filename -> historical (${filesize} bytes)"
                elif [[ $filename == *"Role"* ]] || [[ $filename == *"Security"* ]] || [[ $filename == *"Permission"* ]]; then
                    cp "$file" organized_html/04_admin/security/
                    echo "$filename -> security (${filesize} bytes)"
                elif [[ $filename == *"Rule"* ]] || [[ $filename == *"Config"* ]] || [[ $filename == *"Setting"* ]]; then
                    cp "$file" organized_html/04_admin/configuration/
                    echo "$filename -> configuration (${filesize} bytes)"
                elif [[ $filename == *"Service"* ]] || [[ $filename == *"System"* ]]; then
                    cp "$file" organized_html/04_admin/system/
                    echo "$filename -> system (${filesize} bytes)"
                else
                    cp "$file" organized_html/05_metadata/
                    echo "$filename -> uncategorized (${filesize} bytes)"
                fi
                ((file_count++))
            fi
        done
        
        # Clean temp
        rm -rf temp_extract/
    fi
done

echo "📋 Phase 3: Generate metadata..."

# Create file index
echo "=== EXTRACTED FILES INDEX ===" > organized_html/05_metadata/file_index.txt
echo "Total files extracted: $file_count" >> organized_html/05_metadata/file_index.txt
echo "" >> organized_html/05_metadata/file_index.txt

for category in organized_html/*/; do
    category_name=$(basename "$category")
    echo "=== $category_name ===" >> organized_html/05_metadata/file_index.txt
    
    if [ "$category_name" != "05_metadata" ]; then
        for subcategory in "$category"*/; do
            if [ -d "$subcategory" ]; then
                subcat_name=$(basename "$subcategory")
                file_count_sub=$(find "$subcategory" -name "*.xhtml" | wc -l | tr -d ' ')
                echo "$subcat_name: $file_count_sub files" >> organized_html/05_metadata/file_index.txt
                
                # List files
                find "$subcategory" -name "*.xhtml" -exec basename {} \; | sort >> organized_html/05_metadata/file_index.txt
                echo "" >> organized_html/05_metadata/file_index.txt
            fi
        done
    fi
done

# Extract Russian terms
echo "🔍 Phase 4: Extract Russian terms..."
echo "=== RUSSIAN UI TERMS ===" > organized_html/05_metadata/russian_terms.txt

find organized_html -name "*.xhtml" -exec grep -h -o "[А-Яа-я][А-Яа-я ]*[А-Яа-я]" {} \; 2>/dev/null | sort -u | head -50 >> organized_html/05_metadata/russian_terms.txt

# Extract URL patterns
echo "🌐 Phase 5: Extract URL patterns..."
echo "=== URL PATTERNS ===" > organized_html/05_metadata/url_patterns.txt

find organized_html -name "*.xhtml" -exec grep -h "action=" {} \; 2>/dev/null | grep -o '"/[^"]*"' | sort -u >> organized_html/05_metadata/url_patterns.txt

echo "✅ Smart extraction complete!"
echo ""
echo "📊 Summary:"
echo "- Files extracted: $file_count"
echo "- Categories: $(find organized_html -type d -mindepth 2 | wc -l | tr -d ' ')"
echo "- Russian terms found: $(wc -l < organized_html/05_metadata/russian_terms.txt | tr -d ' ')"
echo "- URL patterns found: $(wc -l < organized_html/05_metadata/url_patterns.txt | tr -d ' ')"
echo ""
echo "📁 Check organized_html/ for categorized files"
echo "📋 Check organized_html/05_metadata/ for analysis results"