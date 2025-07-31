# R1-AdminSecurity Testing Plan for Remaining Scenarios

## 📊 Current Verified Status
- **Completed**: 78/88 scenarios (89%)
- **Remaining**: 10 scenarios
- **Method Required**: MCP Browser Automation

## 🎯 Remaining Scenarios to Test

### 1. **Report Generation** (Scenario 78)
```bash
URL: /ccwfm/views/env/reports/ReportGenerator.xhtml
Expected: Report creation interface with export options
Test Steps:
1. Login with Konstantin/12345
2. Navigate to Reports section
3. Select report type
4. Configure parameters
5. Generate report
6. Verify export formats (PDF, Excel, CSV)
```

### 2. **Bulk Operations** (Scenario 79)
```bash
URL: /ccwfm/views/env/personnel/BulkOperations.xhtml
Expected: Multi-user selection and batch actions
Test Steps:
1. Access bulk operations interface
2. Select multiple employees
3. Test bulk activation/deactivation
4. Verify bulk role assignment
5. Check bulk data export
```

### 3. **Advanced Search** (Scenario 80)
```bash
URL: /ccwfm/views/env/search/AdvancedSearch.xhtml
Expected: Complex search filters and queries
Test Steps:
1. Access advanced search
2. Test multiple filter combinations
3. Search by role, department, status
4. Verify search results accuracy
5. Test saved search functionality
```

### 4. **Data Export** (Scenario 81)
```bash
URL: /ccwfm/views/env/export/DataExport.xhtml
Expected: CSV/Excel export functionality
Test Steps:
1. Access data export interface
2. Select data types to export
3. Configure export parameters
4. Test different file formats
5. Verify exported data integrity
```

### 5. **Audit Log Viewing** (Scenario 82)
```bash
URL: /ccwfm/views/env/audit/AuditLogView.xhtml
Expected: Security event logs and user actions
Test Steps:
1. Access audit log interface
2. View recent security events
3. Filter by user, action, date
4. Verify role creation logged
5. Check login/logout events
```

### 6. **User Activation/Deactivation** (Scenario 83)
```bash
URL: /ccwfm/views/env/personnel/UserActivation.xhtml
Expected: Enable/disable user accounts
Test Steps:
1. Access user activation interface
2. Select inactive user
3. Activate account
4. Verify user can login
5. Test deactivation process
```

### 7. **Password Policy Config** (Scenario 84)
```bash
URL: /ccwfm/views/env/security/PasswordPolicy.xhtml
Expected: Password complexity rules settings
Test Steps:
1. Access password policy settings
2. View current policy rules
3. Test policy modifications
4. Verify complexity requirements
5. Check expiration settings
```

### 8. **Session Management** (Scenario 85)
```bash
URL: /ccwfm/views/env/security/SessionManagement.xhtml
Expected: Session timeout configuration
Test Steps:
1. Access session management
2. View current timeout settings
3. Test session duration changes
4. Verify concurrent session limits
5. Check session termination
```

### 9. **Integration Config** (Scenario 86)
```bash
URL: /ccwfm/views/env/integration/IntegrationConfig.xhtml
Expected: External system connections
Test Steps:
1. Access integration settings
2. View configured integrations
3. Test connection parameters
4. Verify API endpoints
5. Check authentication methods
```

### 10. **System Monitoring** (Scenario 88)
```bash
URL: /ccwfm/views/env/monitoring/SystemDashboard.xhtml
Expected: Real-time metrics and system health
Test Steps:
1. Access monitoring dashboard
2. View system metrics
3. Check active users count
4. Monitor performance indicators
5. Verify alert configurations
```

## 🔑 Testing Prerequisites

### Authentication Pattern (Proven Working)
```bash
mcp__playwright-human-behavior__navigate → https://cc1010wfmcc.argustelecom.ru/ccwfm/
mcp__playwright-human-behavior__type → input[name="j_username"] → "Konstantin"
mcp__playwright-human-behavior__type → input[name="j_password"] → "12345"
mcp__playwright-human-behavior__click → button[name="submitAuth"]
mcp__playwright-human-behavior__wait_and_observe → .main-content
```

### Evidence Collection Requirements
- Screenshot each interface
- Extract Russian UI text
- Document any errors (403/404/500)
- Capture unique IDs created
- Note functional limitations

## 🚨 Known Issues to Watch For

1. **Session Timeout**: Re-login immediately if "Время жизни страницы истекло"
2. **Super Admin Required**: Scenarios 77 & 87 need different credentials
3. **Network Monitoring**: May disconnect after 45-60 minutes
4. **Password Expiration**: May prompt for password change

## 📋 Expected Outcomes

### Likely Accessible (8 scenarios)
- Report Generation
- Bulk Operations  
- Advanced Search
- Data Export
- Audit Log
- User Activation
- Password Policy
- System Monitoring

### May Require Super Admin (2 scenarios)
- Integration Config (possible 403)
- Session Management (possible 403)

## ✅ Success Criteria

Each scenario must have:
1. MCP command sequence documented
2. Russian text extracted
3. Screenshot captured (if accessible)
4. Functionality verified or error documented
5. BDD spec update prepared

---

**Next Step**: Execute this plan when MCP browser tools are available to complete R1's mission from 78/88 to 88/88 (100%).