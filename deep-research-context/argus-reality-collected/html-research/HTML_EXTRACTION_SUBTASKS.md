# HTML Extraction & Organization Subtasks

## 🎯 Goal: Extract and organize 130+ zips into meaningful folders

## 📋 Subtask Plan

### Task 1: Quick Survey (5 mins)
```bash
# Get overview of what we have
ls *.zip | wc -l  # Count total zips
ls *.zip | head -20 | xargs -I {} unzip -l {} | grep -E "(View|List)\.xhtml" | sort -u > all_views.txt
```

### Task 2: Create Extraction Script (10 mins)
```bash
#!/bin/bash
# extract_and_organize.sh

# Create organized folders
mkdir -p extracted/{
  01_authentication,
  02_employee_management,
  03_calendar_vacation,
  04_schedule_planning,
  05_manager_dashboard,
  06_requests_approval,
  07_reports_analytics,
  08_admin_security,
  09_mobile_views,
  10_api_responses,
  99_unknown
}

# Extract all zips
for zip in *.zip; do
  echo "Processing $zip..."
  
  # Extract to temp
  unzip -q "$zip" -d temp_extract/
  
  # Move files to organized folders based on path/name
  find temp_extract -name "*.xhtml" -o -name "*.html" | while read file; do
    filename=$(basename "$file")
    filepath=$(echo "$file" | tr '[:upper:]' '[:lower:]')
    
    # Route to appropriate folder
    if [[ $filepath == *"login"* ]] || [[ $filepath == *"auth"* ]]; then
      mv "$file" extracted/01_authentication/
    elif [[ $filepath == *"worker"* ]] || [[ $filepath == *"employee"* ]] || [[ $filepath == *"personnel"* ]]; then
      mv "$file" extracted/02_employee_management/
    elif [[ $filepath == *"calendar"* ]] || [[ $filepath == *"vacation"* ]] || [[ $filepath == *"request"* ]]; then
      mv "$file" extracted/03_calendar_vacation/
    elif [[ $filepath == *"schedule"* ]] || [[ $filepath == *"planning"* ]] || [[ $filepath == *"shift"* ]]; then
      mv "$file" extracted/04_schedule_planning/
    elif [[ $filepath == *"dashboard"* ]] || [[ $filepath == *"monitoring"* ]] || [[ $filepath == *"kpi"* ]]; then
      mv "$file" extracted/05_manager_dashboard/
    elif [[ $filepath == *"approval"* ]] || [[ $filepath == *"pending"* ]]; then
      mv "$file" extracted/06_requests_approval/
    elif [[ $filepath == *"report"* ]] || [[ $filepath == *"analytics"* ]] || [[ $filepath == *"forecast"* ]]; then
      mv "$file" extracted/07_reports_analytics/
    elif [[ $filepath == *"role"* ]] || [[ $filepath == *"security"* ]] || [[ $filepath == *"admin"* ]]; then
      mv "$file" extracted/08_admin_security/
    elif [[ $filepath == *"mobile"* ]]; then
      mv "$file" extracted/09_mobile_views/
    elif [[ $filepath == *"/api/"* ]] || [[ $filepath == *".json"* ]]; then
      mv "$file" extracted/10_api_responses/
    else
      mv "$file" extracted/99_unknown/
    fi
  done
  
  # Clean temp
  rm -rf temp_extract/
done

# Generate summary
for folder in extracted/*/; do
  count=$(find "$folder" -name "*.xhtml" -o -name "*.html" | wc -l)
  echo "$folder: $count files"
done > extraction_summary.txt
```

### Task 3: Deduplicate Files (5 mins)
```bash
# Many zips contain same pages - keep unique only
cd extracted
for folder in */; do
  cd "$folder"
  # Keep files with largest size (most complete)
  ls -la *.xhtml 2>/dev/null | awk '{print $9, $5}' | sort -k1,1 -k2,2nr | awk '!seen[$1]++ {print $1}'
  cd ..
done
```

### Task 4: Create Quick Index (5 mins)
```bash
# Create index with Russian text found
for folder in extracted/*/; do
  echo "=== $folder ==="
  grep -h "title\|Главная\|Персонал\|Календарь" "$folder"/*.xhtml 2>/dev/null | head -5
done > russian_text_index.txt
```

### Task 5: Ask R-Agents for Known Patterns
Create message for agents who already worked:
```markdown
# TO: R-Agents who already tested Argus

Please share any navigation patterns you discovered:
1. Which pages did you visit?
2. What Russian menu items did you click?
3. Any direct URLs that worked?
4. Which forms/buttons you found?

Example format:
- Feature: Vacation Request
- URL: /ccwfm/views/env/personnel/calendar/CalendarView.xhtml
- Menu: Персонал > Календарь
- Action: Right-click on date
```

## 🎯 Expected Folder Structure

```
extracted/
├── 01_authentication/
│   ├── LoginView.xhtml
│   └── logout.html
├── 02_employee_management/
│   ├── WorkerListView.xhtml
│   ├── EmployeeEditView.xhtml
│   └── PersonnelDashboard.xhtml
├── 03_calendar_vacation/
│   ├── CalendarView.xhtml
│   ├── VacationRequestForm.xhtml
│   └── RequestListView.xhtml
├── 04_schedule_planning/
│   ├── SchedulePlanningView.xhtml
│   ├── ShiftTemplateView.xhtml
│   └── TeamScheduleView.xhtml
├── 05_manager_dashboard/
│   ├── MonitoringDashboardView.xhtml
│   ├── TeamKPIView.xhtml
│   └── ApprovalQueueView.xhtml
└── ...
```

## 📊 Prioritization for R-Agents

### High Priority Pages (Give to R-agents first):
1. **CalendarView.xhtml** - Vacation requests
2. **WorkerListView.xhtml** - Employee management
3. **MonitoringDashboardView.xhtml** - Manager features
4. **SchedulePlanningView.xhtml** - Core scheduling
5. **LoginView.xhtml** - Authentication flow

### Quick Win Strategy:
```markdown
# For each R-agent:
R1: "Here's 01_authentication folder - document the login flow"
R2: "Here's 03_calendar_vacation - find vacation request process"
R3: "Here's 05_manager_dashboard - identify approval widgets"
```

## 🔧 Execution Commands

```bash
# 1. Make script executable
chmod +x extract_and_organize.sh

# 2. Run extraction (will take ~10 mins for 130 zips)
./extract_and_organize.sh

# 3. Check results
cat extraction_summary.txt

# 4. Share folders with R-agents
ls extracted/
```

## 💡 Benefits

1. **Organized by function** - R-agents know what to expect
2. **No duplicates** - One source of truth per page
3. **Russian text indexed** - Quick reference for menu items
4. **Ready for agents** - Just point them to folders
5. **Builds on existing knowledge** - R-agents share what they learned

This approach is 100x simpler than complex analysis scripts!