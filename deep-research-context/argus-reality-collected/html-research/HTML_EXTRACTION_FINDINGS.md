# HTML Extraction Quick Findings

**Date**: 2025-07-30  
**Status**: Initial extraction from SchedulePlanningView.xhtml (150KB)

## 🔑 Key Discoveries

### 1. PrimeFaces Framework
- **Technology**: PrimeFaces 6.1 (JSF-based UI framework)
- **Core Pattern**: `PrimeFaces.ab()` for AJAX behaviors
- **Widget System**: `PrimeFaces.cw()` for component widgets

### 2. Russian UI Terms Found
```yaml
page_titles:
  - "Создание расписаний" (Schedule Creation)
  - "Планирование расписания" (Schedule Planning)
  - "Обновление расписания" (Schedule Update)

menu_items:
  - "Мой кабинет" (My Cabinet)
  - "Заявки" (Requests)
  - "Персонал" (Personnel)
  - "Сотрудники" (Employees)
  - "Группы" (Groups)
  - "Службы" (Services)
  - "Справочники" (Directories)
  - "Прогнозирование" (Forecasting)
  - "Планирование" (Planning)
  - "Мониторинг" (Monitoring)
  - "Отчёты" (Reports)

actions:
  - "Искать везде..." (Search everywhere...)
  - "Выход из системы" (Exit system)
  - "Непрочитанные оповещения" (Unread notifications)
```

### 3. Form Field Patterns
```javascript
// Common input patterns
input[type="text"]
input[type="password"] 
input[type="hidden"] // ViewState tracking

// PrimeFaces components
ui-autocomplete-input
ui-selectonemenu
ui-datatable
ui-panel
```

### 4. JavaScript Functions
```javascript
// Key widget variables
widget_j_idt37 // Ajax status
widget_top_menu_form_j_idt51 // Autocomplete search
widget_templates_form_templates // DataTable
widget_planning_form_plan_start // Date picker
widget_planning_form_plan_end // Date picker

// Common functions
PrimeFaces.ab() // AJAX behavior
PrimeFaces.cw() // Create widget
PrimeFaces.focus() // Focus management
Argus.System.Ajax._trigger() // Custom AJAX handling
```

### 5. Hidden UI Elements
- Block UI overlay (`display: none`)
- Hidden form inputs for ViewState
- Autocomplete panels (`ui-helper-hidden`)
- Dialog containers (`ui-hidden-container`)

### 6. Direct URLs Discovered
```yaml
planning_urls:
  - /ccwfm/views/env/planning/SchedulePlanningView.xhtml
  - /ccwfm/views/env/planning/ActualSchedulePlanView.xhtml
  - /ccwfm/views/env/planning/SchedulePlanningSettingsView.xhtml
  - /ccwfm/views/env/planning/UserPlanningConfigsView.xhtml
  - /ccwfm/views/env/adjustment/WorkScheduleAdjustmentView.xhtml
  - /ccwfm/views/env/schedule/OperatingScheduleSolutionView.xhtml
  - /ccwfm/views/env/vacancy/VacancyPlanningView.xhtml

personnel_urls:
  - /ccwfm/views/env/personnel/WorkerListView.xhtml
  - /ccwfm/views/env/personnel/GroupListView.xhtml
  - /ccwfm/views/env/personnel/ServiceListView.xhtml
  - /ccwfm/views/env/personnel/PersonalAreaIncomingView.xhtml
```

### 7. MCP Automation Patterns
```javascript
// Click patterns
onclick="PrimeFaces.ab({s:'element_id',ps:true});return false;"

// Table row selection
tr[data-ri="0"][data-rk="12919828"] // Row index and key

// Menu navigation
.menulink.ripplelink // Menu items
.ui-icon-triangle-1-e // Submenu indicators

// Form submission
PrimeFaces.addSubmitParam('form_id',{'param':'value'}).submit('form_id')
```

## 📊 Summary Statistics
- **Menu Items**: 50+ navigation links
- **Russian Terms**: 100+ UI labels
- **Form Fields**: Multiple complex forms
- **AJAX Endpoints**: All using PrimeFaces patterns
- **Hidden Elements**: Dialogs, overlays, panels

## 🎯 Next Steps
1. Extract from remaining 13 HTML files
2. Build complete Russian dictionary
3. Create MCP selector library
4. Document all direct URLs

---

**Note**: This is preliminary analysis from one file. Full extraction pending from R-agents.