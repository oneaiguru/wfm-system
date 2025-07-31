# R1 Authentication Block Documentation - Complete Details

## 🚨 **15 BLOCKED SCENARIOS - EXACT AUTHENTICATION REQUIREMENTS**

### **ADMIN PORTAL UNIVERSAL BLOCK**
- **Portal URL**: https://cc1010wfmcc.argustelecom.ru/ccwfm/
- **Login Credentials**: Konstantin / 12345
- **Current Status**: BLOCKED - Session timeout + Password expiration
- **Error Messages**: 
  - "Время жизни страницы истекло, или произошла ошибка соединения"
  - "Истекает срок действия пароля. Задать новый пароль сейчас?"

## 📋 **DETAILED SCENARIO BLOCKS**

### **SCENARIO 74: Role Creation Workflow**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/security/RoleListView.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Role list with "Создать новую роль" button
Blocked By: Session timeout on login
```

### **SCENARIO 75: User Management CRUD**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/personnel/WorkerListView.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Employee list, Add/Edit/Delete functions
Blocked By: Session timeout on login
```

### **SCENARIO 76: Permission Assignment**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/security/PermissionAssignment.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Role-permission mapping interface
Blocked By: Session timeout on login
```

### **SCENARIO 77: System Configuration**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/system/SystemConfigView.xhtml
Credentials: SUPER ADMIN NEEDED (Unknown)
Expected: 403 Forbidden for Konstantin, System settings for super admin
Blocked By: Session timeout + Need super admin credentials
```

### **SCENARIO 78: Report Generation**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/reports/ReportGenerator.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Report creation and export interface
Blocked By: Session timeout on login
```

### **SCENARIO 79: Bulk Operations**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/personnel/BulkOperations.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Multi-user selection and batch actions
Blocked By: Session timeout on login
```

### **SCENARIO 80: Advanced Search**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/search/AdvancedSearch.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Complex search filters and queries
Blocked By: Session timeout on login
```

### **SCENARIO 81: Data Export**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/export/DataExport.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: CSV/Excel export functionality
Blocked By: Session timeout on login
```

### **SCENARIO 82: Audit Log Viewing**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/audit/AuditLogView.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Security event logs and user actions
Blocked By: Session timeout on login
```

### **SCENARIO 83: User Activation/Deactivation**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/personnel/UserActivation.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Enable/disable user accounts
Blocked By: Session timeout on login
```

### **SCENARIO 84: Password Policy Config**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/security/PasswordPolicy.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Password complexity rules settings
Blocked By: Session timeout on login
```

### **SCENARIO 85: Session Management**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/security/SessionManagement.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Session timeout configuration (ironic)
Blocked By: Session timeout on login
```

### **SCENARIO 86: Integration Config**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/integration/IntegrationConfig.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: External system connections
Blocked By: Session timeout on login
```

### **SCENARIO 87: Backup/Restore**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/system/BackupRestore.xhtml
Credentials: SUPER ADMIN NEEDED (Unknown)
Expected: System backup and restore interface
Blocked By: Session timeout + Need super admin
```

### **SCENARIO 88: System Monitoring**
```
URL: https://cc1010wfmcc.argustelecom.ru/ccwfm/views/env/monitoring/SystemDashboard.xhtml
Credentials: Konstantin/12345 (Admin)
Expected: Real-time metrics and system health
Blocked By: Session timeout on login
```

## 🔐 **AUTHENTICATION ISSUE SUMMARY**

### **Primary Block**: Admin Portal Session Management
- **Issue**: Session expires immediately with password warning
- **Credentials Available**: Konstantin/12345 (standard admin)
- **Credentials Needed**: Super admin for scenarios 77 & 87
- **Solution Required**: Either fix session timeout or provide new credentials

### **MCP Testing Evidence**
All URLs tested with:
```bash
mcp__playwright-human-behavior__navigate → [URL]
Result: Redirected to login page
mcp__playwright-human-behavior__type → Credentials
mcp__playwright-human-behavior__click → Login button
Result: Session timeout error
```

---

**R1-AdminSecurity**  
*15 Scenarios Blocked - Exact Details Documented*