# R1-AdminSecurity Complete 88 Scenarios Detailed Execution Plan

## 🎯 **COMPREHENSIVE SCENARIO MAPPING WITH MCP COMMANDS**

### **AUTHENTICATION & SESSION MANAGEMENT (10 scenarios)**

#### **Scenario 1: Admin Portal Login**
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__screenshot → capture login form
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
mcp__playwright-human-behavior__wait_and_observe → .main-content
mcp__playwright-human-behavior__get_content → verify login success
```
**Evidence**: Login form, welcome message, user name display

#### **Scenario 2: Session Persistence Testing**
```bash
# After login from Scenario 1
mcp__playwright-human-behavior__wait_and_observe → body → 300000 (5 minutes)
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/home/HomeView.xhtml
mcp__playwright-human-behavior__get_content → check if still logged in
```
**Evidence**: Session duration, timeout behavior

#### **Scenario 3: Password Expiration Handling**
```bash
# When password warning appears
mcp__playwright-human-behavior__get_content → capture "Истекает срок действия пароля"
mcp__playwright-human-behavior__click → *:has-text('Не сейчас')
mcp__playwright-human-behavior__wait_and_observe → .main-content
mcp__playwright-human-behavior__screenshot → document password warning
```
**Evidence**: Warning message, bypass option

#### **Scenario 4: Session Timeout Recovery**
```bash
# When "Время жизни страницы истекло" appears
mcp__playwright-human-behavior__screenshot → capture timeout error
mcp__playwright-human-behavior__click → *:has-text('Обновить')
# Re-login sequence
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
```
**Evidence**: Error message, recovery process

#### **Scenario 5: Logout Functionality**
```bash
# After successful login
mcp__playwright-human-behavior__click → .logout-button, *:has-text('Выход')
mcp__playwright-human-behavior__wait_and_observe → .login-form
mcp__playwright-human-behavior__get_content → verify logout success
```
**Evidence**: Logout button, return to login

#### **Scenario 6: Invalid Credentials Testing**
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[type="text"] → "InvalidUser"
mcp__playwright-human-behavior__type → input[type="password"] → "WrongPass"
mcp__playwright-human-behavior__click → button[type="submit"]
mcp__playwright-human-behavior__get_content → capture error message
mcp__playwright-human-behavior__screenshot → document invalid login
```
**Evidence**: Error message for invalid credentials

#### **Scenario 7: Remember Me Functionality**
```bash
mcp__playwright-human-behavior__click → input[type="checkbox"][name="remember"]
mcp__playwright-human-behavior__type → input[type="text"] → "Konstantin"
mcp__playwright-human-behavior__type → input[type="password"] → "12345"
mcp__playwright-human-behavior__click → button[type="submit"]
# Clear session and return
mcp__playwright-human-behavior__manage_storage → clear → sessionStorage
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__get_content → check if remembered
```
**Evidence**: Checkbox state, persistence behavior

#### **Scenario 8: Password Change Flow**
```bash
# When password expiration appears
mcp__playwright-human-behavior__click → *:has-text('Изменить пароль')
mcp__playwright-human-behavior__wait_and_observe → .password-change-form
mcp__playwright-human-behavior__type → input[name="oldPassword"] → "12345"
mcp__playwright-human-behavior__type → input[name="newPassword"] → "NewPass123"
mcp__playwright-human-behavior__type → input[name="confirmPassword"] → "NewPass123"
mcp__playwright-human-behavior__screenshot → capture password change form
```
**Evidence**: Password change form, validation rules

#### **Scenario 9: Multi-Session Prevention**
```bash
# First login
[Standard login sequence]
# Attempt second login from different browser
mcp__playwright-human-behavior__manage_storage → clear → all
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
[Standard login sequence]
mcp__playwright-human-behavior__get_content → check for session conflict
```
**Evidence**: Multi-session handling behavior

#### **Scenario 10: Session Activity Timeout**
```bash
# After login
mcp__playwright-human-behavior__wait_and_observe → body → 60000 (1 minute)
mcp__playwright-human-behavior__click → random element (activity)
mcp__playwright-human-behavior__wait_and_observe → body → 1800000 (30 minutes)
mcp__playwright-human-behavior__navigate → any admin URL
mcp__playwright-human-behavior__get_content → check if timed out
```
**Evidence**: Activity-based session extension

### **ROLE MANAGEMENT (15 scenarios)**

#### **Scenario 11: Role List Display**
```bash
# After successful login
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/RoleListView.xhtml
mcp__playwright-human-behavior__wait_and_observe → .role-table
mcp__playwright-human-behavior__screenshot → capture role list
mcp__playwright-human-behavior__get_content → count existing roles
```
**Evidence**: Role list interface, existing roles

#### **Scenario 12: Create New Role**
```bash
mcp__playwright-human-behavior__click → button:has-text('Создать новую роль')
mcp__playwright-human-behavior__wait_and_observe → .role-form
mcp__playwright-human-behavior__type → input[name="roleName"] → "TestRole-2025-07-27"
mcp__playwright-human-behavior__type → textarea[name="description"] → "MCP Test Role"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__get_content → capture generated Role ID
```
**Evidence**: Role creation form, auto-generated ID

#### **Scenario 13: Role Permission Assignment**
```bash
# In role creation/edit form
mcp__playwright-human-behavior__click → .permissions-tab
mcp__playwright-human-behavior__click → input[type="checkbox"][value="VIEW_EMPLOYEES"]
mcp__playwright-human-behavior__click → input[type="checkbox"][value="EDIT_SCHEDULES"]
mcp__playwright-human-behavior__click → input[type="checkbox"][value="APPROVE_REQUESTS"]
mcp__playwright-human-behavior__screenshot → capture permission selection
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
```
**Evidence**: Permission checkboxes, assignment success

#### **Scenario 14: Edit Existing Role**
```bash
mcp__playwright-human-behavior__click → tr:has-text('TestRole') button.edit
mcp__playwright-human-behavior__wait_and_observe → .role-form
mcp__playwright-human-behavior__type → textarea[name="description"] → " - Updated"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__get_content → verify update success
```
**Evidence**: Edit form, update confirmation

#### **Scenario 15: Delete Role**
```bash
mcp__playwright-human-behavior__click → tr:has-text('TestRole') button.delete
mcp__playwright-human-behavior__wait_and_observe → .confirmation-dialog
mcp__playwright-human-behavior__screenshot → capture delete confirmation
mcp__playwright-human-behavior__click → button:has-text('Подтвердить')
mcp__playwright-human-behavior__get_content → verify deletion
```
**Evidence**: Delete confirmation, removal from list

#### **Scenario 16: Role Search/Filter**
```bash
mcp__playwright-human-behavior__type → input[placeholder="Поиск ролей"] → "Admin"
mcp__playwright-human-behavior__wait_and_observe → .role-table
mcp__playwright-human-behavior__get_content → count filtered results
mcp__playwright-human-behavior__screenshot → filtered role list
```
**Evidence**: Search functionality, filtered results

#### **Scenario 17: Role Activation/Deactivation**
```bash
mcp__playwright-human-behavior__click → tr:has-text('TestRole') .status-toggle
mcp__playwright-human-behavior__wait_and_observe → .status-change-confirm
mcp__playwright-human-behavior__click → button:has-text('Деактивировать')
mcp__playwright-human-behavior__get_content → verify status change
```
**Evidence**: Status toggle, confirmation dialog

#### **Scenario 18: Bulk Role Operations**
```bash
mcp__playwright-human-behavior__click → input[type="checkbox"].select-all
mcp__playwright-human-behavior__click → button:has-text('Массовые действия')
mcp__playwright-human-behavior__click → *:has-text('Экспорт выбранных')
mcp__playwright-human-behavior__wait_and_observe → .export-dialog
mcp__playwright-human-behavior__screenshot → bulk operations menu
```
**Evidence**: Bulk selection, available operations

#### **Scenario 19: Role Permission Inheritance**
```bash
mcp__playwright-human-behavior__click → button:has-text('Создать новую роль')
mcp__playwright-human-behavior__click → select[name="parentRole"]
mcp__playwright-human-behavior__click → option:has-text('Manager')
mcp__playwright-human-behavior__wait_and_observe → .inherited-permissions
mcp__playwright-human-behavior__screenshot → inherited permissions display
```
**Evidence**: Parent role selection, inheritance display

#### **Scenario 20: Role Assignment to Users**
```bash
mcp__playwright-human-behavior__click → tr:has-text('TestRole') button.assign-users
mcp__playwright-human-behavior__wait_and_observe → .user-assignment-dialog
mcp__playwright-human-behavior__click → input[type="checkbox"]:nth-of-type(1)
mcp__playwright-human-behavior__click → button:has-text('Назначить')
mcp__playwright-human-behavior__get_content → verify assignment
```
**Evidence**: User assignment interface, success message

#### **Scenario 21: Role Permission Conflicts**
```bash
# Assign conflicting permissions
mcp__playwright-human-behavior__click → input[value="APPROVE_ALL"]
mcp__playwright-human-behavior__click → input[value="DENY_ALL"]
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__get_content → capture conflict warning
mcp__playwright-human-behavior__screenshot → conflict resolution dialog
```
**Evidence**: Conflict detection, resolution options

#### **Scenario 22: Role Cloning**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Manager') button.clone
mcp__playwright-human-behavior__wait_and_observe → .role-form
mcp__playwright-human-behavior__get_content → verify pre-filled data
mcp__playwright-human-behavior__type → input[name="roleName"] → "Manager-Clone"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
```
**Evidence**: Clone functionality, pre-populated form

#### **Scenario 23: Role History/Audit**
```bash
mcp__playwright-human-behavior__click → tr:has-text('TestRole') button.history
mcp__playwright-human-behavior__wait_and_observe → .audit-log
mcp__playwright-human-behavior__screenshot → capture audit entries
mcp__playwright-human-behavior__get_content → read change history
```
**Evidence**: Audit log display, change tracking

#### **Scenario 24: Role Export**
```bash
mcp__playwright-human-behavior__click → button:has-text('Экспорт ролей')
mcp__playwright-human-behavior__wait_and_observe → .export-options
mcp__playwright-human-behavior__click → input[value="CSV"]
mcp__playwright-human-behavior__click → button:has-text('Экспортировать')
mcp__playwright-human-behavior__screenshot → export confirmation
```
**Evidence**: Export options, file generation

#### **Scenario 25: Role Import**
```bash
mcp__playwright-human-behavior__click → button:has-text('Импорт ролей')
mcp__playwright-human-behavior__wait_and_observe → .import-dialog
mcp__playwright-human-behavior__click → input[type="file"]
mcp__playwright-human-behavior__screenshot → import interface
mcp__playwright-human-behavior__get_content → import validation rules
```
**Evidence**: Import interface, validation display

### **USER MANAGEMENT (20 scenarios)**

#### **Scenario 26: Employee List Display**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/personnel/WorkerListView.xhtml
mcp__playwright-human-behavior__wait_and_observe → .employee-table
mcp__playwright-human-behavior__screenshot → employee list interface
mcp__playwright-human-behavior__get_content → count total employees (513)
```
**Evidence**: Employee list, total count display

#### **Scenario 27: Create New Employee**
```bash
mcp__playwright-human-behavior__click → button:has-text('Добавить нового сотрудника')
mcp__playwright-human-behavior__wait_and_observe → .employee-form
mcp__playwright-human-behavior__type → input[name="firstName"] → "Test"
mcp__playwright-human-behavior__type → input[name="lastName"] → "User"
mcp__playwright-human-behavior__type → input[name="email"] → "test@example.com"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__get_content → capture Worker ID
```
**Evidence**: Employee form, auto-generated Worker-ID

#### **Scenario 28: Employee Department Assignment**
```bash
mcp__playwright-human-behavior__click → select[name="department"]
mcp__playwright-human-behavior__click → option:has-text('ТП Группа Поляковой')
mcp__playwright-human-behavior__click → select[name="position"]
mcp__playwright-human-behavior__click → option:has-text('Специалист')
mcp__playwright-human-behavior__screenshot → department/position selection
```
**Evidence**: Department dropdown, position assignment

#### **Scenario 29: Employee Activation**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Test User') button.activate
mcp__playwright-human-behavior__wait_and_observe → .activation-dialog
mcp__playwright-human-behavior__type → input[name="activationDate"] → "2025-07-27"
mcp__playwright-human-behavior__click → button:has-text('Активировать')
mcp__playwright-human-behavior__get_content → verify activation
```
**Evidence**: Activation dialog, status change

#### **Scenario 30: Employee Deactivation**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Test User') button.deactivate
mcp__playwright-human-behavior__wait_and_observe → .deactivation-dialog
mcp__playwright-human-behavior__type → textarea[name="reason"] → "Test deactivation"
mcp__playwright-human-behavior__click → button:has-text('Деактивировать')
mcp__playwright-human-behavior__screenshot → deactivation confirmation
```
**Evidence**: Deactivation reason, status update

#### **Scenario 31: Employee Search**
```bash
mcp__playwright-human-behavior__type → input[placeholder="Поиск сотрудников"] → "Бирюков"
mcp__playwright-human-behavior__wait_and_observe → .employee-table
mcp__playwright-human-behavior__get_content → verify filtered results
mcp__playwright-human-behavior__screenshot → search results
```
**Evidence**: Search functionality, result filtering

#### **Scenario 32: Employee Profile Edit**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Бирюков') button.edit
mcp__playwright-human-behavior__wait_and_observe → .employee-form
mcp__playwright-human-behavior__type → input[name="phone"] → "+7900123456"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__get_content → verify update
```
**Evidence**: Edit form, field updates

#### **Scenario 33: Employee Photo Upload**
```bash
mcp__playwright-human-behavior__click → .photo-upload-area
mcp__playwright-human-behavior__wait_and_observe → .file-dialog
mcp__playwright-human-behavior__screenshot → photo upload interface
mcp__playwright-human-behavior__get_content → upload requirements
```
**Evidence**: Photo upload UI, size/format requirements

#### **Scenario 34: Employee Schedule Assignment**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Test User') button.schedule
mcp__playwright-human-behavior__wait_and_observe → .schedule-assignment
mcp__playwright-human-behavior__click → select[name="scheduleTemplate"]
mcp__playwright-human-behavior__click → option:has-text('5/2 Standard')
mcp__playwright-human-behavior__screenshot → schedule assignment
```
**Evidence**: Schedule templates, assignment interface

#### **Scenario 35: Employee Skills Management**
```bash
mcp__playwright-human-behavior__click → .skills-tab
mcp__playwright-human-behavior__click → button:has-text('Добавить навык')
mcp__playwright-human-behavior__type → input[name="skillName"] → "Customer Service"
mcp__playwright-human-behavior__click → select[name="skillLevel"]
mcp__playwright-human-behavior__click → option:has-text('Expert')
mcp__playwright-human-behavior__screenshot → skills management
```
**Evidence**: Skills interface, proficiency levels

#### **Scenario 36: Employee Access Card**
```bash
mcp__playwright-human-behavior__click → button:has-text('Управление картой')
mcp__playwright-human-behavior__wait_and_observe → .access-card-dialog
mcp__playwright-human-behavior__type → input[name="cardNumber"] → "1234567890"
mcp__playwright-human-behavior__click → button:has-text('Активировать карту')
mcp__playwright-human-behavior__get_content → verify card activation
```
**Evidence**: Access card management, activation process

#### **Scenario 37: Employee Training Records**
```bash
mcp__playwright-human-behavior__click → .training-tab
mcp__playwright-human-behavior__click → button:has-text('Добавить обучение')
mcp__playwright-human-behavior__type → input[name="courseName"] → "Security Training"
mcp__playwright-human-behavior__type → input[name="completionDate"] → "2025-07-20"
mcp__playwright-human-behavior__screenshot → training records
```
**Evidence**: Training interface, certification tracking

#### **Scenario 38: Employee Documents**
```bash
mcp__playwright-human-behavior__click → .documents-tab
mcp__playwright-human-behavior__click → button:has-text('Загрузить документ')
mcp__playwright-human-behavior__wait_and_observe → .document-upload
mcp__playwright-human-behavior__click → select[name="documentType"]
mcp__playwright-human-behavior__click → option:has-text('Паспорт')
mcp__playwright-human-behavior__screenshot → document management
```
**Evidence**: Document types, upload interface

#### **Scenario 39: Employee Bulk Import**
```bash
mcp__playwright-human-behavior__click → button:has-text('Импорт сотрудников')
mcp__playwright-human-behavior__wait_and_observe → .import-dialog
mcp__playwright-human-behavior__click → button:has-text('Скачать шаблон')
mcp__playwright-human-behavior__screenshot → import template
mcp__playwright-human-behavior__get_content → template format
```
**Evidence**: Import template, format requirements

#### **Scenario 40: Employee Export**
```bash
mcp__playwright-human-behavior__click → input[type="checkbox"].select-all
mcp__playwright-human-behavior__click → button:has-text('Экспорт')
mcp__playwright-human-behavior__click → input[value="Excel"]
mcp__playwright-human-behavior__click → button:has-text('Экспортировать')
mcp__playwright-human-behavior__screenshot → export options
```
**Evidence**: Export formats, selection options

#### **Scenario 41: Employee History**
```bash
mcp__playwright-human-behavior__click → tr:has-text('Бирюков') button.history
mcp__playwright-human-behavior__wait_and_observe → .employee-history
mcp__playwright-human-behavior__screenshot → history timeline
mcp__playwright-human-behavior__get_content → change entries
```
**Evidence**: Employee history, change tracking

#### **Scenario 42: Manager Assignment**
```bash
mcp__playwright-human-behavior__click → select[name="manager"]
mcp__playwright-human-behavior__type → input.manager-search → "Полякова"
mcp__playwright-human-behavior__click → .manager-suggestion:first
mcp__playwright-human-behavior__click → button:has-text('Назначить')
mcp__playwright-human-behavior__get_content → verify assignment
```
**Evidence**: Manager search, assignment confirmation

#### **Scenario 43: Team Assignment**
```bash
mcp__playwright-human-behavior__click → .teams-tab
mcp__playwright-human-behavior__click → input[type="checkbox"][value="Support Team"]
mcp__playwright-human-behavior__click → input[type="checkbox"][value="Evening Shift"]
mcp__playwright-human-behavior__click → button:has-text('Сохранить команды')
mcp__playwright-human-behavior__screenshot → team assignments
```
**Evidence**: Multiple team support, assignment UI

#### **Scenario 44: Employee Termination**
```bash
mcp__playwright-human-behavior__click → button:has-text('Уволить сотрудника')
mcp__playwright-human-behavior__wait_and_observe → .termination-dialog
mcp__playwright-human-behavior__type → input[name="terminationDate"] → "2025-07-27"
mcp__playwright-human-behavior__type → textarea[name="reason"] → "Test termination"
mcp__playwright-human-behavior__screenshot → termination process
```
**Evidence**: Termination workflow, required fields

#### **Scenario 45: Employee Reinstatement**
```bash
mcp__playwright-human-behavior__click → button:has-text('Показать уволенных')
mcp__playwright-human-behavior__click → tr:has-text('Test User') button.reinstate
mcp__playwright-human-behavior__wait_and_observe → .reinstatement-dialog
mcp__playwright-human-behavior__type → textarea[name="reinstatementReason"] → "Error correction"
mcp__playwright-human-behavior__screenshot → reinstatement process
```
**Evidence**: Reinstatement option, approval workflow

### **SECURITY BOUNDARIES (15 scenarios)**

#### **Scenario 46: System Configuration Access**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/SystemConfigView.xhtml
mcp__playwright-human-behavior__wait_and_observe → body
mcp__playwright-human-behavior__get_content → capture error/success
mcp__playwright-human-behavior__screenshot → access result
```
**Evidence**: 403 Forbidden or system config interface

#### **Scenario 47: Super Admin Functions**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/admin/SuperAdminView.xhtml
mcp__playwright-human-behavior__get_content → capture access result
mcp__playwright-human-behavior__screenshot → permission error
```
**Evidence**: Access denial for standard admin

#### **Scenario 48: Cross-Portal Security**
```bash
# From admin portal
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/admin
mcp__playwright-human-behavior__get_content → capture redirect/error
# From employee portal  
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__get_content → verify isolation
```
**Evidence**: Portal isolation confirmation

#### **Scenario 49: API Endpoint Protection**
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/api/users
mcp__playwright-human-behavior__get_content → capture response
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/api/roles
mcp__playwright-human-behavior__screenshot → API protection
```
**Evidence**: API access denial patterns

#### **Scenario 50: Direct URL Access**
```bash
# Without login
mcp__playwright-human-behavior__manage_storage → clear → all
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/RoleListView.xhtml
mcp__playwright-human-behavior__get_content → verify redirect to login
mcp__playwright-human-behavior__screenshot → authentication requirement
```
**Evidence**: Direct access prevention

#### **Scenario 51: Session Hijacking Prevention**
```bash
# Get session after login
mcp__playwright-human-behavior__execute_javascript → "document.cookie"
# Clear and try to use session
mcp__playwright-human-behavior__manage_storage → clear → all
mcp__playwright-human-behavior__execute_javascript → "document.cookie = '[stolen session]'"
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/home/HomeView.xhtml
mcp__playwright-human-behavior__get_content → verify rejection
```
**Evidence**: Session security validation

#### **Scenario 52: SQL Injection Testing**
```bash
mcp__playwright-human-behavior__type → input[placeholder="Поиск"] → "'; DROP TABLE users; --"
mcp__playwright-human-behavior__click → button:has-text('Поиск')
mcp__playwright-human-behavior__wait_and_observe → .search-results
mcp__playwright-human-behavior__get_content → verify safe handling
```
**Evidence**: Input sanitization confirmation

#### **Scenario 53: XSS Prevention**
```bash
mcp__playwright-human-behavior__type → input[name="description"] → "<script>alert('XSS')</script>"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__wait_and_observe → .saved-content
mcp__playwright-human-behavior__get_content → verify escaped output
```
**Evidence**: XSS protection validation

#### **Scenario 54: CSRF Protection**
```bash
# Check for CSRF token
mcp__playwright-human-behavior__execute_javascript → "document.querySelector('[name=csrf_token]').value"
# Attempt request without token
mcp__playwright-human-behavior__execute_javascript → "fetch('/api/delete', {method: 'POST'})"
mcp__playwright-human-behavior__get_content → verify CSRF rejection
```
**Evidence**: CSRF token requirement

#### **Scenario 55: File Upload Security**
```bash
mcp__playwright-human-behavior__click → input[type="file"]
# Attempt malicious file types
mcp__playwright-human-behavior__screenshot → file type restrictions
mcp__playwright-human-behavior__get_content → allowed extensions list
```
**Evidence**: File type validation

#### **Scenario 56: Resource Directory Protection**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/WEB-INF/
mcp__playwright-human-behavior__get_content → verify 404
mcp__playwright-human-behavior__navigate → /ccwfm/META-INF/
mcp__playwright-human-behavior__screenshot → directory protection
```
**Evidence**: Protected directory blocking

#### **Scenario 57: Error Information Leakage**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/resources/
mcp__playwright-human-behavior__get_content → capture error message
mcp__playwright-human-behavior__screenshot → verify generic error
```
**Evidence**: Generic error messages (no stack traces)

#### **Scenario 58: Rate Limiting**
```bash
# Rapid login attempts
for i in 1..10:
  mcp__playwright-human-behavior__type → input[type="text"] → "test"
  mcp__playwright-human-behavior__type → input[type="password"] → "wrong"
  mcp__playwright-human-behavior__click → button[type="submit"]
mcp__playwright-human-behavior__get_content → check for rate limit
```
**Evidence**: Rate limiting activation

#### **Scenario 59: Password Policy Enforcement**
```bash
# In password change
mcp__playwright-human-behavior__type → input[name="newPassword"] → "123"
mcp__playwright-human-behavior__click → button:has-text('Изменить')
mcp__playwright-human-behavior__get_content → capture policy error
mcp__playwright-human-behavior__screenshot → password requirements
```
**Evidence**: Password complexity rules

#### **Scenario 60: Audit Trail Security**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/audit/AuditLogView.xhtml
mcp__playwright-human-behavior__wait_and_observe → .audit-entries
mcp__playwright-human-behavior__screenshot → audit log access
mcp__playwright-human-behavior__get_content → verify read-only
```
**Evidence**: Audit log immutability

### **MONITORING & REPORTS (8 scenarios)**

#### **Scenario 61: System Monitoring Dashboard**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/monitoring/SystemMonitoringView.xhtml
mcp__playwright-human-behavior__wait_and_observe → .monitoring-widgets
mcp__playwright-human-behavior__screenshot → monitoring interface
mcp__playwright-human-behavior__get_content → available metrics
```
**Evidence**: Monitoring dashboard, real-time data

#### **Scenario 62: User Activity Reports**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/reports/UserActivityReport.xhtml
mcp__playwright-human-behavior__click → input[name="dateFrom"]
mcp__playwright-human-behavior__type → input[name="dateFrom"] → "2025-07-01"
mcp__playwright-human-behavior__click → button:has-text('Сформировать')
mcp__playwright-human-behavior__screenshot → activity report
```
**Evidence**: Report generation, data display

#### **Scenario 63: Security Event Logs**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SecurityEventLog.xhtml
mcp__playwright-human-behavior__wait_and_observe → .event-table
mcp__playwright-human-behavior__click → select[name="eventType"]
mcp__playwright-human-behavior__click → option:has-text('Failed Login')
mcp__playwright-human-behavior__screenshot → security events
```
**Evidence**: Security event filtering, details

#### **Scenario 64: Permission Usage Report**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/reports/PermissionUsageReport.xhtml
mcp__playwright-human-behavior__click → button:has-text('Анализ использования')
mcp__playwright-human-behavior__wait_and_observe → .usage-chart
mcp__playwright-human-behavior__screenshot → permission analytics
```
**Evidence**: Permission usage visualization

#### **Scenario 65: System Performance Metrics**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/monitoring/PerformanceMetrics.xhtml
mcp__playwright-human-behavior__wait_and_observe → .performance-graphs
mcp__playwright-human-behavior__click → button:has-text('Обновить')
mcp__playwright-human-behavior__screenshot → performance data
```
**Evidence**: Performance graphs, refresh capability

#### **Scenario 66: Failed Access Attempts**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/FailedAccessLog.xhtml
mcp__playwright-human-behavior__wait_and_observe → .failed-attempts
mcp__playwright-human-behavior__get_content → attempt details
mcp__playwright-human-behavior__screenshot → failed access log
```
**Evidence**: Failed attempt tracking, IP logging

#### **Scenario 67: Data Export Audit**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/audit/DataExportLog.xhtml
mcp__playwright-human-behavior__wait_and_observe → .export-history
mcp__playwright-human-behavior__click → tr:first button.details
mcp__playwright-human-behavior__screenshot → export audit details
```
**Evidence**: Export tracking, user attribution

#### **Scenario 68: Compliance Reports**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/reports/ComplianceReport.xhtml
mcp__playwright-human-behavior__click → select[name="complianceType"]
mcp__playwright-human-behavior__click → option:has-text('GDPR')
mcp__playwright-human-behavior__click → button:has-text('Сформировать отчет')
mcp__playwright-human-behavior__screenshot → compliance status
```
**Evidence**: Compliance reporting, regulation support

### **INTEGRATION & SYSTEM (10 scenarios)**

#### **Scenario 69: LDAP Integration Test**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/integration/LDAPSettings.xhtml
mcp__playwright-human-behavior__wait_and_observe → .ldap-config
mcp__playwright-human-behavior__click → button:has-text('Тест подключения')
mcp__playwright-human-behavior__screenshot → LDAP test result
```
**Evidence**: LDAP configuration, test capability

#### **Scenario 70: SSO Configuration**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SSOConfiguration.xhtml
mcp__playwright-human-behavior__wait_and_observe → .sso-settings
mcp__playwright-human-behavior__get_content → SSO providers
mcp__playwright-human-behavior__screenshot → SSO configuration
```
**Evidence**: SSO setup interface, provider options

#### **Scenario 71: Email Notification Settings**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/EmailSettings.xhtml
mcp__playwright-human-behavior__click → button:has-text('Отправить тест')
mcp__playwright-human-behavior__type → input[name="testEmail"] → "test@example.com"
mcp__playwright-human-behavior__screenshot → email test interface
```
**Evidence**: Email configuration, test functionality

#### **Scenario 72: Backup Configuration**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/BackupSettings.xhtml
mcp__playwright-human-behavior__wait_and_observe → .backup-schedule
mcp__playwright-human-behavior__click → button:has-text('Создать резервную копию')
mcp__playwright-human-behavior__screenshot → backup interface
```
**Evidence**: Backup settings, manual backup option

#### **Scenario 73: System Maintenance Mode**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/MaintenanceMode.xhtml
mcp__playwright-human-behavior__wait_and_observe → .maintenance-toggle
mcp__playwright-human-behavior__screenshot → maintenance controls
mcp__playwright-human-behavior__get_content → maintenance options
```
**Evidence**: Maintenance mode interface

#### **Scenario 74: License Management**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/LicenseManagement.xhtml
mcp__playwright-human-behavior__wait_and_observe → .license-info
mcp__playwright-human-behavior__get_content → license details
mcp__playwright-human-behavior__screenshot → license status
```
**Evidence**: License information display

#### **Scenario 75: Database Connection Pool**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/monitoring/DatabasePool.xhtml
mcp__playwright-human-behavior__wait_and_observe → .pool-stats
mcp__playwright-human-behavior__click → button:has-text('Обновить статистику')
mcp__playwright-human-behavior__screenshot → connection pool data
```
**Evidence**: Database pool monitoring

#### **Scenario 76: Cache Management**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/system/CacheManagement.xhtml
mcp__playwright-human-behavior__wait_and_observe → .cache-statistics
mcp__playwright-human-behavior__click → button:has-text('Очистить кэш')
mcp__playwright-human-behavior__screenshot → cache management UI
```
**Evidence**: Cache controls, statistics

#### **Scenario 77: API Rate Limits**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/api/RateLimitSettings.xhtml
mcp__playwright-human-behavior__wait_and_observe → .rate-limit-config
mcp__playwright-human-behavior__type → input[name="requestsPerMinute"] → "100"
mcp__playwright-human-behavior__screenshot → rate limit settings
```
**Evidence**: API rate limit configuration

#### **Scenario 78: System Logs Viewer**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/logs/SystemLogs.xhtml
mcp__playwright-human-behavior__wait_and_observe → .log-viewer
mcp__playwright-human-behavior__click → select[name="logLevel"]
mcp__playwright-human-behavior__click → option:has-text('ERROR')
mcp__playwright-human-behavior__screenshot → log filtering
```
**Evidence**: Log viewer interface, filtering options

### **ADVANCED SECURITY (10 scenarios)**

#### **Scenario 79: Two-Factor Authentication**
```bash
# After enabling 2FA
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/TwoFactorSetup.xhtml
mcp__playwright-human-behavior__wait_and_observe → .qr-code
mcp__playwright-human-behavior__screenshot → 2FA setup interface
mcp__playwright-human-behavior__get_content → setup instructions
```
**Evidence**: 2FA configuration, QR code display

#### **Scenario 80: IP Whitelist Management**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/IPWhitelist.xhtml
mcp__playwright-human-behavior__click → button:has-text('Добавить IP')
mcp__playwright-human-behavior__type → input[name="ipAddress"] → "192.168.1.0/24"
mcp__playwright-human-behavior__click → button:has-text('Сохранить')
mcp__playwright-human-behavior__screenshot → IP whitelist
```
**Evidence**: IP restriction management

#### **Scenario 81: Security Headers Configuration**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SecurityHeaders.xhtml
mcp__playwright-human-behavior__wait_and_observe → .headers-config
mcp__playwright-human-behavior__click → input[name="enableHSTS"]
mcp__playwright-human-behavior__screenshot → security headers
```
**Evidence**: HTTP security headers setup

#### **Scenario 82: Password Rotation Policy**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/PasswordPolicy.xhtml
mcp__playwright-human-behavior__type → input[name="maxPasswordAge"] → "90"
mcp__playwright-human-behavior__type → input[name="passwordHistory"] → "5"
mcp__playwright-human-behavior__click → button:has-text('Применить')
mcp__playwright-human-behavior__screenshot → password policy
```
**Evidence**: Password rotation settings

#### **Scenario 83: Session Security Settings**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SessionSettings.xhtml
mcp__playwright-human-behavior__type → input[name="sessionTimeout"] → "30"
mcp__playwright-human-behavior__click → input[name="singleSession"]
mcp__playwright-human-behavior__screenshot → session security
```
**Evidence**: Session configuration options

#### **Scenario 84: Encryption Settings**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/EncryptionSettings.xhtml
mcp__playwright-human-behavior__wait_and_observe → .encryption-status
mcp__playwright-human-behavior__get_content → encryption algorithms
mcp__playwright-human-behavior__screenshot → encryption config
```
**Evidence**: Data encryption settings

#### **Scenario 85: Security Scanning**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SecurityScan.xhtml
mcp__playwright-human-behavior__click → button:has-text('Запустить сканирование')
mcp__playwright-human-behavior__wait_and_observe → .scan-progress
mcp__playwright-human-behavior__screenshot → security scan interface
```
**Evidence**: Security scanning capability

#### **Scenario 86: Privileged Access Management**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/PrivilegedAccess.xhtml
mcp__playwright-human-behavior__wait_and_observe → .privileged-users
mcp__playwright-human-behavior__click → button:has-text('Запросить доступ')
mcp__playwright-human-behavior__screenshot → PAM interface
```
**Evidence**: Privileged access controls

#### **Scenario 87: Security Dashboard**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/SecurityDashboard.xhtml
mcp__playwright-human-behavior__wait_and_observe → .security-metrics
mcp__playwright-human-behavior__screenshot → security overview
mcp__playwright-human-behavior__get_content → threat indicators
```
**Evidence**: Security metrics dashboard

#### **Scenario 88: Incident Response**
```bash
mcp__playwright-human-behavior__navigate → /ccwfm/views/env/security/IncidentResponse.xhtml
mcp__playwright-human-behavior__click → button:has-text('Создать инцидент')
mcp__playwright-human-behavior__type → input[name="incidentTitle"] → "Test Security Incident"
mcp__playwright-human-behavior__click → select[name="severity"]
mcp__playwright-human-behavior__click → option:has-text('High')
mcp__playwright-human-behavior__screenshot → incident management
```
**Evidence**: Incident response system

## 🔧 **SYSTEMATIC RECOVERY APPROACH FOR BLOCKED SCENARIOS**

### **For Session Timeout Issues (15-20 scenarios affected):**
1. Clear all browser storage before each attempt
2. Use fresh login sequence immediately
3. Navigate to target URL within 30 seconds
4. Screenshot any partial success
5. Document exact timeout duration

### **For 403 Forbidden (5-8 scenarios affected):**
1. Verify these require super admin privileges
2. Document the exact error message
3. Try alternative similar functions
4. Map permission requirements

### **For Missing Features (3-5 scenarios):**
1. Check if feature exists in different location
2. Look for alternative UI paths
3. Document as "Not Implemented" if truly missing

## 📊 **REALISTIC COMPLETION TRACKING**

**Currently Verified with Full MCP**: ~50 scenarios
**Can Complete with Recovery**: +25-30 scenarios  
**Permanently Blocked**: 5-8 scenarios (super admin)
**Missing/Not Implemented**: 3-5 scenarios

**Realistic Target**: 75-80/88 scenarios (85-90%) with systematic approach

---

This detailed plan provides specific MCP commands for EVERY scenario, making it clear what needs to be tested and how to document evidence properly.