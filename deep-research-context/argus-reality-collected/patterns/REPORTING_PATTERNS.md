# Reporting & Compliance Patterns - R6 Discoveries

**Source**: R6-ReportingCompliance 100% completion testing
**Date**: 2025-07-28
**Evidence**: 200+ MCP commands across 65 scenarios

## 🏗️ Report Engine Architecture

### Task-Based Asynchronous Execution Pattern
```javascript
// Reports execute as background tasks, not synchronously
// Pattern found in all 16 report types:
1. User configures report parameters
2. Click "Построить отчет" (Build Report)
3. System creates task with timestamp
4. Task executes in background
5. User receives notification on completion/failure
6. Report available in task list for download
```

### Report Types Discovered (16 total)
```
1. График работы сотрудников - Employee work schedule
2. Для Демонстрации - For demonstration
3. Общие КЦ - General call center
4. Общий отчет по рабочему времени - General working time report
5. Отчет по Логированию - Logging report
6. Отчет по ролям с подразделением - Roles report with subdivision
7. Отчёт о %Ready - Ready percentage report
8. Отчёт по %absenteeism новый - New absenteeism percentage report
9. Отчёт по AHT - Average handling time report
10. Отчёт по заработной плате - Payroll report
11. Отчёт по итогу планирования вакансий - Vacancy planning results report
12. Отчёт по опозданиям операторов - Operator tardiness report
13. Отчёт по предпочтениям - Preferences report
14. Отчёт по прогнозу и плану - Forecast and plan report
15. Расчёт заработной платы - Payroll calculation
16. Соблюдение расписания - Schedule adherence
```

### Report Configuration Pattern
```bash
# Standard configuration interface includes:
- Date range selector (от/до - from/to)
- Timezone selector (4 Russian timezones)
- Department/group filter
- Service filter (for multi-service reports)
- Template selector (for formatting)
- Export format (PDF, XLSX standard)
```

### Report Access URLs
```javascript
// Report List (5 custom reports):
/ccwfm/views/env/tmp/ReportTypeMapView.xhtml

// Standard Reports (direct access):
/ccwfm/views/env/report/WorkerScheduleAdherenceReportView.xhtml
/ccwfm/views/env/report/T13FormReportView.xhtml
/ccwfm/views/env/report/ForecastAndPlanReportView.xhtml
/ccwfm/views/env/report/OperatorLateReportView.xhtml
/ccwfm/views/env/report/AhtReportView.xhtml
/ccwfm/views/env/report/ReadyReportView.xhtml
/ccwfm/views/env/report/WorkerWishReportView.xhtml
/ccwfm/views/env/report/WorkerScheduleReportView.xhtml
/ccwfm/views/env/report/AbsenteeismNewReportView.xhtml
/ccwfm/views/env/report/ResultsOfVacancyPlanningReportView.xhtml

// Administrative Reports:
/ccwfm/views/env/tmp/ReportTypeEditorView.xhtml - Report editor
/ccwfm/views/env/tmp/task/ReportTaskListView.xhtml - Task execution list
```

## 📊 Compliance Features

### Absenteeism Tracking Pattern
```javascript
// Special character in report name indicates new version
"Отчёт по %absenteeism новый"
// Tracks:
- Absence percentage by employee/group
- Reasons for absence (linked to absence reasons reference)
- Compliance with labor standards
- Period-over-period comparison
```

### Tardiness Monitoring Pattern
```javascript
// "Отчёт по опозданиям операторов"
// Monitors:
- Late arrivals beyond grace period
- Frequency of tardiness
- Impact on service levels
- Group/individual breakdown
```

### Schedule Adherence Pattern
```javascript
// "Соблюдение расписания"
// Granular tracking levels:
- 1 minute intervals
- 5 minute intervals  
- 15 minute intervals
- 30 minute intervals
// Shows planned vs actual presence
```

## 🔒 Access Control Patterns

### Report Permission Hierarchy
```
1. Basic User: Can run personal reports only
2. Supervisor: Can run team reports
3. Manager: Can run department reports
4. Admin (Konstantin): Can access report configuration
5. System Admin: Full access including payroll reports

// 403 Forbidden indicates proper RBAC enforcement
```

### Direct URL vs Menu Access
```javascript
// Pattern: Many reports return 403 on direct URL access
// Solution: Navigate through menu system
if (directAccess === 403) {
  navigateToHomepage();
  clickMenu("Отчёты");
  clickSubmenu(reportName);
}
```

## 🔄 Real-time Monitoring Integration

### Auto-refresh Pattern
```javascript
// PrimeFaces Poll component with configurable intervals:
- 15 seconds (high frequency monitoring)
- 30 seconds (standard monitoring)
- 60 seconds (resource-conscious monitoring)
- Manual refresh option always available
```

### Monitoring Dashboard Types
```
1. Оперативный контроль - Operational control (text-based)
2. Статусы операторов - Operator statuses (grid view)
3. Управление группами - Group management (hierarchical)
4. Threshold monitoring - Service-level alerts
```

## 📋 Reference Data Management

### Comprehensive Configuration Interfaces
```javascript
// Each reference type has CRUD operations:
- Create (Создать)
- Read (list view with filters)
- Update (edit inline or modal)
- Delete (Удалить with confirmation)
- Activate/Deactivate toggle
```

### Reference Data Categories
```
1. Roles (11 configured) - RBAC foundation
2. Services (9 active) - Multi-service support
3. Channel Types (4) - Voice, SMS, Non-voice, Sales
4. Activities (4) - Activity categorization
5. Positions (7) - Organizational hierarchy
6. Time Zones (4) - Russian timezone support
7. Special Events (3) - With coefficient multipliers
8. Notification Schemes (9 categories) - Event-driven alerts
9. Vacation Schemes (11/14 through 28/28) - Work patterns
10. Absence Reasons - Categorized tracking
11. Production Calendar - Holiday imports
12. Threshold Settings - Per-service configuration
```

## 🌐 Integration Architecture

### REST API Registry Pattern
```javascript
// 7+ integration endpoints configured:
- Personnel synchronization
- Time tracking systems
- Payroll systems
- Forecasting data sources
- External scheduling systems
- Notification delivery
- Business intelligence exports
```

### Data Exchange Patterns
```xml
<!-- Production Calendar Import -->
<calendar>
  <year>2025</year>
  <holidays>
    <holiday date="2025-01-01" name="Новый год"/>
    <holiday date="2025-01-07" name="Рождество"/>
    <!-- Additional holidays -->
  </holidays>
</calendar>
```

## 🚨 Common Integration Issues

### Session Management
```javascript
// Admin portal: 10-15 minute timeout
// Employee portal: Persistent session
// Solution: Re-authenticate proactively
if (timeElapsed > 10 * 60 * 1000) {
  reAuthenticate();
}
```

### Large Data Set Handling
```javascript
// Reports with 1000+ employees may timeout
// Solution: Use filters to reduce data set
// Or use background task execution pattern
```

### Multi-language Considerations
```javascript
// Russian primary, English secondary
// All validation messages in Russian
// Date formats: DD.MM.YYYY
// Time formats: HH:MM (+05:00 timezone)
```

## 💡 Best Practices

### Report Development
1. Always use task-based execution for large reports
2. Provide progress indicators during generation
3. Include timezone in all datetime displays
4. Support both PDF and Excel exports
5. Implement proper error handling with Russian messages

### Compliance Tracking
1. Automate threshold monitoring
2. Send proactive notifications
3. Maintain audit trails
4. Support drill-down from summary to detail
5. Enable period comparisons

### Reference Data Management
1. Validate dependencies before deletion
2. Support bulk operations where appropriate
3. Maintain activation/deactivation vs deletion
4. Implement proper cascading updates
5. Version control for critical configurations

---

These patterns enable robust reporting and compliance functionality in enterprise WFM systems.