# R1-AdminSecurity Hidden Features Discovery

**Date**: 2025-07-30
**Agent**: R1-AdminSecurity
**Focus**: Admin panels, system settings, audit logs

## 🔍 Discovered Features Not in BDD Specs

### 1. Personnel Data Collection Features
- **Menu Items Found**:
  - "Сбор данных по операторам" (Operator Data Collection)
  - "Передача данных по операторам" (Operator Data Transfer)
  - "Бизнес-правила" (Business Rules)
  - "Выработка" (Productivity/Output)
- **BDD Coverage**: NOT COVERED
- **Status**: Menu items exist but URLs need discovery

### 2. Advanced Reference Data Management
- **Menu Items Found**:
  - "Конфигурация эффективности рабочего времени" (Working Time Efficiency Configuration)
  - "Трудовые нормативы" (Labor Standards)
  - "Настройка правил обмена" (Exchange Rules Configuration)
  - "Схемы уведомлений" (Notification Schemes)
  - "Тип канала" (Channel Type)
  - "Деятельности" (Activities)
- **BDD Coverage**: PARTIALLY COVERED (basic reference data only)
- **APIs Found**: Attempting to access returns 403 Forbidden

### 3. System Administration Areas (403 Forbidden)
- **Location**: /ccwfm/views/env/system/
- **Description**: System configuration requiring super admin
- **BDD Coverage**: NOT COVERED - Higher privileges needed
- **Access Level**: Super Admin only
- **Russian Error**: "Ошибка системы" with 403 status

### 4. Audit Logging System (403 Forbidden)  
- **Location**: /ccwfm/views/env/audit/
- **Description**: Audit trail and logging features
- **BDD Coverage**: NOT COVERED - Access restricted
- **Access Level**: Requires elevated permissions
- **Implementation Status**: EXISTS but inaccessible with current credentials

### 5. Advanced Notification Management
- **Location**: /ccwfm/views/env/dict/NotificationSchemeListView.xhtml
- **Description**: Notification scheme configuration
- **BDD Coverage**: NOT COVERED
- **Status**: 403 Forbidden - requires higher privileges
- **Russian UI**: "Схемы уведомлений"

### 6. Specialized Personnel Features
- **Discovered Menu Items**:
  - "Настройка ознакомлений" (Acknowledgment Settings)
  - "Ознакомления" (Acknowledgments)
  - "Структура групп" (Group Structure)
  - "Синхронизация персонала" (Personnel Synchronization)
- **BDD Coverage**: NOT COVERED
- **Implementation Priority**: Medium - Administrative features

## 🚨 Access Level Discoveries

### Three-Tier Permission Structure Confirmed:
1. **Standard Admin** (Konstantin/12345) - Basic admin functions
2. **System Admin** - Can access /system/ paths (403 for us)
3. **Audit Admin** - Can access /audit/ paths (403 for us)

### Permission Patterns:
- 403 Forbidden = Feature exists but requires higher privileges
- 404 Not Found = Feature doesn't exist or wrong URL
- 200 OK = Accessible with current permissions

## 📊 Hidden Features Summary

### Definitely Exist (403 responses):
1. System administration panel
2. Audit logging interface
3. Notification scheme management
4. Advanced permission configurations

### Possibly Exist (need URL discovery):
1. Business rules engine
2. Operator data collection/transfer
3. Personnel synchronization tools
4. Acknowledgment management system

## 🎯 Next Exploration Areas

1. Try to find actual URLs for personnel features
2. Check if any keyboard shortcuts exist
3. Look for hidden admin URLs in /admin/* pattern
4. Test right-click context menus
5. Check for batch operations we missed

## 🎯 Successfully Accessed Hidden Features

### 1. Groups Management (Группы)
- **Location**: /ccwfm/views/env/personnel/GroupListView.xhtml
- **Description**: Group creation and management
- **BDD Coverage**: PARTIALLY COVERED
- **UI Elements**:
  - "Создать новую группу" (Create new group)
  - "Активировать группу" (Activate group)
  - "Удалить группу" (Delete group)
  - "Фильтровать группы по типу" (Filter groups by type)
- **Groups Found**: Support lines, IVR, Training, Sales, Supervisors
- **Implementation Status**: Working feature

### 2. Services Management (Службы)
- **Location**: /ccwfm/views/env/personnel/ServiceListView.xhtml
- **Description**: Service configuration
- **BDD Coverage**: NOT COVERED in detail
- **Implementation Status**: Accessible and working

### 3. Employee Activation Feature
- **Location**: Employee list page
- **UI Element**: "Активировать сотрудника" button
- **BDD Coverage**: NOT EXPLICITLY COVERED
- **Description**: Separate activation step for employees
- **Key Finding**: Employee creation and activation are separate processes

## 💡 Key Insights

1. **Argus has significant hidden functionality** not covered in BDD specs
2. **Multi-tier admin system** with different permission levels
3. **Russian-only features** that may not have English documentation
4. **System integration features** hidden behind permission walls
5. **Employee lifecycle** more complex than documented (create → activate → assign credentials)
6. **Group/Service hierarchy** exists beyond basic user management