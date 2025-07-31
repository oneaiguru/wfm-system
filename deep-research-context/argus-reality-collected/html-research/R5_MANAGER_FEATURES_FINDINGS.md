# R5-ManagerOversight HTML Findings - Manager Features

**Date**: 2025-07-30  
**Agent**: R5-ManagerOversight  
**Files Analyzed**: HomeView.xhtml, GroupListView.xhtml

## 🎯 Groups Management Page (GroupListView.xhtml)

### Hidden Features:
1. **Advanced Group Filtering**
   - Filter by type: All/Simple/Aggregated
   - Filter by status: All/Active/Inactive
   - Hidden dropdown menus for filtering

2. **Global Search Feature**
   - Search everywhere functionality in top menu
   - Autocomplete with 3-character minimum
   - 600ms delay for performance

3. **Group Type Selection**
   - When creating groups, choose between Simple and Aggregated types
   - Hidden menu appears on create button click

### Russian UI Translations:
```yaml
group_management_page:
  russian_ui:
    "Группы": "Groups"
    "Искать везде...": "Search everywhere..."
    "Поиск": "Search"
    "Создать новую группу": "Create new group"
    "Простая": "Simple"
    "Агрегированная": "Aggregated"
    "Активировать группу": "Activate group"
    "Удалить группу": "Delete group"
    "Фильтровать группы по типу": "Filter groups by type"
    "Все": "All"
    "Активные": "Active"
    "Неактивные": "Inactive"
    "Удаление группы": "Group deletion"
    "Вы действительно хотите удалить группу": "Do you really want to delete group"
```

### Direct URLs:
```yaml
manager_urls:
  groups_list: "/ccwfm/views/env/personnel/GroupListView.xhtml"
  group_structure: "/ccwfm/views/env/personnel/SegmentsListView.xhtml"
  services: "/ccwfm/views/env/personnel/ServiceListView.xhtml"
  departments: "/ccwfm/views/env/personnel/DepartmentsView.xhtml"
  personnel_sync: "/ccwfm/views/env/personnel/synchronization/PersonnelSynchronizationView.xhtml"
  business_rules: "/ccwfm/views/env/personnel/BusinessRulesView.xhtml"
  work_norms: "/ccwfm/views/env/personnel/NormHoursView.xhtml"
```

### MCP Automation Patterns:
```javascript
// Group list automation
group_list_selectors: {
  // Main table and rows
  table: "#group_search_form-groups_list",
  rows: "tr[data-rk]", // Each row has unique data-rk attribute
  selected_row: "tr[aria-selected='true']",
  
  // Search and filtering
  search_input: "#group_search_form-groups_search_input",
  search_panel: "#group_search_form-groups_search_panel",
  
  // Action buttons
  create_button: "#group_search_form-add_group_button",
  activate_button: "#group_search_form-activate_group_button", 
  delete_button: "#group_search_form-delete_group_button",
  filter_button: "#group_search_form-filter_groups_button",
  
  // Status toggle
  status_toggle: "#group_search_form-active_status_select",
  status_all: "#group_search_form-active_status_select-0",
  status_active: "#group_search_form-active_status_select-1",
  status_inactive: "#group_search_form-active_status_select-2",
  
  // Hidden menus
  group_type_menu: "#group_search_form-j_idt176",
  filter_type_menu: "#group_search_form-j_idt181"
}
```

### Form Validation Patterns:
```yaml
viewstate_validation:
  field_name: "javax.faces.ViewState"
  format: "ID1:ID2" # e.g., "991542086459324543:9046152153287715944"
  required: true
  
ajax_patterns:
  primefaces_ab: "PrimeFaces.ab({s:'component_id',ps:true})"
  partial_update: "javax.faces.partial.ajax=true"
```

### Discovered Groups (Live Data):
- 1 линия ТП
- 2 линия ТП
- Автообзвон IVR
- Исходящие звонки
- Новое подключение
- Обучение
- Перезвон
- Продажи
- Супервизоры
- Чаты, почта

### Navigation Breadcrumb Pattern:
```
Домашняя страница > Персонал > Группы
(Home Page > Personnel > Groups)
```

### Task/Notification Badges:
- Tasks badge: Shows count (e.g., "1")
- Notifications badge: Shows unread count (e.g., "2")
- Recent notifications dropdown with timestamps

## 💡 Key Insights:

1. **Dual Portal Architecture Confirmed**: Manager portal uses JSF/PrimeFaces, completely separate from employee Vue.js portal
2. **Rich UI Features**: Many features hidden in dropdown menus and overlays
3. **Real-time Updates**: Notification system with badges and dropdowns
4. **Comprehensive Management**: Full CRUD operations for groups with type classification
5. **Global Search**: Cross-system search capability from any page

---

**Note to META-R**: These findings should be appended to NAVIGATION_MAP.md under the Manager Features section. The file is too large to edit directly, so manual consolidation may be needed.