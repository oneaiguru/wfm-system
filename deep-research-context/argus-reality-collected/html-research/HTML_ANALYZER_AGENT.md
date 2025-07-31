# HTML Analyzer Agent - Navigation Map Creator

## 🎯 Mission
Analyze 130+ saved Argus HTML pages to create precise navigation GPS for R-agents.

## 💡 The Problem You're Solving
R-agents waste 70% of time on navigation:
- Getting lost in Russian menus
- Re-navigating after timeouts  
- Searching for features repeatedly
- No direct paths to BDD scenarios

## 📊 Your Resources
**130+ ZIP files**: Each contains complete Argus page snapshots
- **Main pages**: `/ccwfm/views/env/*/`
- **API endpoints**: `/gw/api/v1/*/` 
- **Russian UI**: Full menu structure, breadcrumbs, forms

## 🎯 Your Analysis Tasks

### 1. Feature Discovery
Extract key features from pages:
```python
# Look for these URL patterns:
- /personnel/calendar/ → vacation_request
- /personnel/employees/ → employee_management  
- /requests/ → approval_workflows
- /schedule/ → schedule_planning
- /dashboard/ → manager_dashboard
```

### 2. Navigation Path Extraction
For each feature, document:
```yaml
vacation_request:
  path: "Главная > Мой кабинет > Календарь"
  url: "/ccwfm/views/env/personnel/calendar/CalendarView.xhtml"
  breadcrumbs: "Home > Personal > Calendar"
  entry_point: "Right-click on date"
  key_actions: ["Создать заявку", "Выбрать тип", "Отпуск"]
```

### 3. Menu Structure Mapping
Extract complete menu hierarchy:
```yaml
main_menu:
  - "Главная" (Home)
  - "Персонал" (Personnel):
    - "Сотрудники" (Employees)
    - "Календарь" (Calendar)
    - "Заявки" (Requests)
  - "Планирование" (Planning)
  - "Отчеты" (Reports)
```

### 4. Form Analysis
Document all forms and inputs:
```yaml
vacation_form:
  inputs:
    - date_picker: "Дата начала"
    - dropdown: "Тип отпуска" 
    - textarea: "Комментарий"
  buttons:
    - "Создать заявку"
    - "Отмена"
```

## 🔧 Implementation Strategy

### Phase 1: Batch Analysis
```python
# Process 10 zips at a time
for zip_batch in zip_files[:10]:
    extract_and_analyze(zip_batch)
    
# Focus on most common pages first:
priority_pages = [
    'calendar', 'employee', 'request', 
    'dashboard', 'schedule', 'login'
]
```

### Phase 2: Pattern Recognition
```python
# Find navigation patterns
def extract_breadcrumbs(soup):
    # Look for: .breadcrumb, .ui-breadcrumb
    # Extract: "Home > Personnel > Calendar"
    
def extract_menu_items(soup):
    # Find: nav elements, menu links
    # Map: Russian text → URLs
    
def extract_forms(soup):
    # All form inputs and actions
    # Map: field names → Russian labels
```

### Phase 3: GPS Generation
Create navigation shortcuts:
```yaml
# Instead of: "Find vacation somewhere"
# Provide: Direct GPS to feature

SHORTCUTS:
  vacation_request:
    direct_url: "/ccwfm/views/env/personnel/calendar/CalendarView.xhtml"
    menu_path: "Персонал → Календарь"
    action: "Right-click date → Создать заявку → Отпуск"
    
  employee_list:
    direct_url: "/ccwfm/views/env/personnel/WorkerListView.xhtml"
    menu_path: "Персонал → Сотрудники"
    filters: ["Активные", "Все", "По отделам"]
```

## 📋 Output Requirements

### 1. NAVIGATION_MAP.yaml
```yaml
ARGUS_NAVIGATION_MAP:
  vacation_request:
    url: "/ccwfm/views/env/personnel/calendar/CalendarView.xhtml"
    menu_path: "Персонал > Календарь"
    breadcrumbs: "Главная > Мой кабинет > Календарь"
    entry_action: "Right-click on date"
    form_elements: ["date_picker", "type_dropdown", "comment"]
    
  employee_management:
    url: "/ccwfm/views/env/personnel/WorkerListView.xhtml" 
    menu_path: "Персонал > Сотрудники"
    key_buttons: ["Добавить", "Редактировать", "Удалить"]
    search_fields: ["ФИО", "Отдел", "Должность"]
```

### 2. RUSSIAN_UI_DICTIONARY.yaml
```yaml
# All Russian UI text → English meanings
UI_TRANSLATIONS:
  "Главная": "Home"
  "Персонал": "Personnel" 
  "Календарь": "Calendar"
  "Создать заявку": "Create Request"
  "Отпуск": "Vacation"
  "Сотрудники": "Employees"
```

### 3. FEATURE_CATALOG.json
```json
{
  "features_found": 15,
  "pages_analyzed": 130,
  "navigation_shortcuts": 25,
  "forms_documented": 40,
  "menu_items": 60
}
```

## 🚀 Success Criteria

### Speed Improvements for R-Agents:
- **80% time saved** on navigation
- **Direct paths** to all BDD scenarios  
- **No more getting lost** in Russian menus
- **Reusable shortcuts** across all R-agents

### Quality Metrics:
- **100% coverage** of key features
- **Accurate Russian→English** translations
- **Working direct URLs** for all features
- **Complete form documentation**

## 🔧 Tools Available

### Python Libraries:
```python
import zipfile      # Extract saved pages
import BeautifulSoup # Parse HTML
import yaml         # Generate navigation maps
import json         # Feature catalogs
import re           # Pattern matching
```

### Sample Analysis Code:
```python
def analyze_page(filename, content):
    soup = BeautifulSoup(content, 'html.parser')
    
    # Extract navigation
    breadcrumbs = extract_breadcrumbs(soup)
    menu_items = extract_menu_items(soup)
    forms = extract_forms(soup)
    
    # Classify feature
    feature = classify_feature(filename, soup)
    
    return {
        'feature': feature,
        'navigation': breadcrumbs,
        'forms': forms,
        'shortcuts': generate_shortcuts(feature, soup)
    }
```

## 💡 Pro Tips

### Russian Text Recognition:
```python
# Key Russian terms to watch for:
vacation_terms = ['отпуск', 'заявка', 'календарь']
employee_terms = ['сотрудник', 'персонал', 'работник']
schedule_terms = ['график', 'планирование', 'расписание']
```

### URL Pattern Recognition:
```python
# Common Argus URL patterns:
/ccwfm/views/env/personnel/     # Personnel features
/ccwfm/views/env/planning/      # Planning features  
/ccwfm/views/env/monitoring/    # Dashboard features
/gw/api/v1/                     # API endpoints
```

### Form Element Discovery:
```python
# Look for PrimeFaces components:
- .ui-inputtext     # Text inputs
- .ui-dropdown      # Dropdowns
- .ui-calendar      # Date pickers
- .ui-button        # Action buttons
```

---

**Start by running NAVIGATION_ANALYZER.py on first 10 zips, then expand analysis based on patterns found.**