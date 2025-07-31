# R-Agent HTML Exploration Guide

## 🎯 Your Task: Build Navigation Knowledge

We have 16 sample HTML files from Argus. Each R-agent should examine 1-2 files and update NAVIGATION_MAP.md.

## 📋 Available Files

### Authentication & Home
- `LoginView.xhtml` - Login page (R1)
- `HomeView.xhtml` - Main dashboard (R1)

### Employee Management  
- `WorkerListView.xhtml` - Employee list (R2)
- `PersonalAreaIncomingView.xhtml` - Personal workspace (R2)
- `ServiceListView.xhtml` - Services/departments (R2)
- `GroupListView.xhtml` - Team groups (R2)

### Scheduling & Planning
- `SchedulePlanningView.xhtml` - Main scheduling (R7)
- `WorkScheduleAdjustmentView.xhtml` - Schedule edits (R7)
- `VacancyPlanningView.xhtml` - Vacation planning (R3)
- `OperatingScheduleSolutionView.xhtml` - Schedule optimization (R7)

### Analytics & Forecasting
- `ForecastListView.xhtml` - Forecast list (R3)
- `ForecastAccuracyView.xhtml` - Accuracy metrics (R3)
- `HistoricalDataListView.xhtml` - Historical data (R3)
- `ImportForecastView.xhtml` - Import forecasts (R3)

### Admin & Security
- `RoleListView.xhtml` - Role management (R1)
- `WorkRuleListView.xhtml` - Work rules/policies (R1)

## 🔍 What to Look For

### 1. Page Structure
```bash
# Read the file
cat samples/WorkerListView.xhtml

# Look for:
- <title> tag (page title)
- Russian text (menu items, labels)
- Form elements and inputs
- Data tables and lists
- Buttons and actions
```

### 2. Navigation Clues
- Breadcrumbs (`class="breadcrumb"`)
- Menu items (`class="menu"`)
- Links to other pages
- URL in form actions

### 3. Functionality
- What does this page do?
- What actions can users take?
- What data is displayed?

## 📝 Update NAVIGATION_MAP.md

After analyzing, add your findings:

```yaml
employee_list:
  url: "/ccwfm/views/env/personnel/WorkerListView.xhtml"
  menu_path: "Персонал > Сотрудники"  
  page_title: "Список сотрудников"
  key_elements:
    - "Table with employee names"
    - "Search/filter options"
    - "Add/Edit/Delete buttons"
  actions_available:
    - "Select employee (click row)"
    - "Add new employee"
    - "Filter by department"
  russian_terms:
    - "Сотрудники" = "Employees"
    - "Добавить" = "Add"
  notes: "Uses data-rk attribute for employee IDs"
```

## 🚀 Quick Start Commands

```bash
# For R2 exploring employee pages:
cd /Users/m/Documents/wfm/main/agents/HTML-RESERACH
cat samples/WorkerListView.xhtml | grep -E "title|button|Сотрудник"

# For R1 exploring login:
cat samples/LoginView.xhtml | head -50

# For R7 exploring scheduling:
cat samples/SchedulePlanningView.xhtml | grep -i "schedule\|план"
```

## 🤝 Coordination

1. **Check NAVIGATION_MAP.md** before starting
2. **Pick your files** based on your domain
3. **Update one section at a time** to avoid conflicts
4. **Share interesting patterns** in the Tips section

Ready to explore! Each page you document saves hours for other agents.