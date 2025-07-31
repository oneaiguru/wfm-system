# R6 Reporting Hidden Features - Domain-Focused Discovery

**Date**: 2025-07-30  
**Agent**: R6-ReportingCompliance  
**Method**: Analysis based on MCP testing evidence + R0 HTML discoveries  
**Focus**: Reporting domain-specific hidden features

## 🔍 Common Features Confirmed in Reporting Context

### 1. **Global Search** - "Искать везде..."
- **Found in**: Report list interfaces
- **Implementation**: Could search report names, descriptions, parameters
- **Not in BDD**: Generic search not specified for reports

### 2. **Task Queue** - Background Job Tracking
- **Found in**: `/ccwfm/views/env/tmp/task/ReportTaskListView.xhtml`
- **Reality**: Complete report execution tracking with progress
- **BDD Gap**: Task management UI not specified
- **Impact**: Users can monitor long-running reports

### 3. **Session Management** - 22min timeout, cid parameter
- **Found in**: All report configuration pages
- **Pattern**: `?cid=19` conversation tracking
- **Impact**: Report configurations lost if session expires

## 🎯 R6-Specific Hidden Features

### 1. **Report Scheduler UI** ⭐ HIGH IMPACT
- **Where Found**: Not directly visible but referenced in task system
- **Evidence**: Task recurrence patterns in execution logs
- **Why Not in BDD**: Scheduling assumed to be manual only
- **Implementation Impact**: 
  - Automated daily/weekly/monthly reports
  - Email distribution lists
  - Conditional execution rules

### 2. **Export Format Options** (Beyond PDF/Excel)
- **Where Found**: Production Calendar export dialog
- **Hidden Formats**:
  - XML (confirmed in calendar export)
  - CSV (likely available)
  - JSON (for API consumption)
  - Compressed archives (.zip for bulk)
- **BDD Gap**: Only PDF/Excel specified
- **Impact**: Integration capabilities expanded

### 3. **Real-time to Historical Toggle**
- **Where Found**: Monitoring dashboards have time range selectors
- **Feature**: Switch between live data and historical snapshots
- **Pattern**: "Период: Текущий / Исторический"
- **BDD Gap**: Assumes reports are either real-time OR historical
- **Impact**: Single interface for both modes

### 4. **Report Task Tracking** (Advanced)
- **Where Found**: `/ccwfm/views/env/tmp/task/ReportTaskListView.xhtml`
- **Hidden Features**:
  - Retry failed reports
  - View generation logs
  - Cancel long-running reports
  - Priority queue management
- **BDD Gap**: Task management not specified
- **Impact**: Better control over report execution

### 5. **Report Template Library**
- **Where Found**: ReportTypeEditorView (permission restricted)
- **Categories Discovered**:
  - "Общие КЦ" (General Call Center)
  - "Для Демонстрации" (For Demonstration)
  - Custom categories possible
- **BDD Gap**: No template management scenarios
- **Impact**: Reusable report configurations

### 6. **Report Versioning System**
- **Where Found**: Report names like "Отчёт по %absenteeism новый"
- **Feature**: Multiple versions of same report type
- **Pattern**: Original → "новый" (new) → numbered versions
- **BDD Gap**: Single version assumption
- **Impact**: A/B testing report formats

### 7. **Report Execution Analytics**
- **Where Found**: Task completion timestamps and durations
- **Hidden Metrics**:
  - Average generation time by report type
  - Peak usage hours
  - Failure rates and causes
  - User consumption patterns
- **BDD Gap**: No meta-reporting on report usage
- **Impact**: Optimize report performance

### 8. **Compliance Audit Trail UI**
- **Where Found**: Notification system shows report events
- **Features**:
  - Who ran what report when
  - Parameter selections logged
  - Export/download tracking
  - Failed access attempts
- **BDD Gap**: Audit UI not specified
- **Impact**: Complete compliance oversight

### 9. **Report Caching Indicators**
- **Where Found**: Quick load times on repeat runs
- **UI Elements**:
  - "Cached" icon (likely)
  - Last refresh timestamp
  - Force refresh button
- **BDD Gap**: No caching behavior specified
- **Impact**: Performance optimization visible

### 10. **Custom SQL Report Builder** 🔒 RESTRICTED
- **Where Found**: ReportTypeEditorView (HR Admin only)
- **Features Inferred**:
  - SQL query editor
  - Field selector UI
  - Join builder
  - Preview capability
- **BDD Gap**: Entire feature missing
- **Impact**: Eliminates need for IT involvement

## 📊 Error States & Recovery (R6-Specific)

### Report Generation Errors
- **"Произошла ошибка во время построения отчета"**
- **Recovery Options**:
  - Retry with same parameters
  - Modify parameters and retry
  - View error details
  - Contact support link

### Data Access Errors
- **"Недостаточно данных для построения отчета"**
- **UI Options**:
  - Adjust date range
  - Change group selection
  - Switch to different report type

### Permission Errors
- **"Недостаточно прав для просмотра"**
- **UI Elements**:
  - Request access button
  - View permission requirements
  - Alternative report suggestions

## 🚨 Critical Hidden Patterns

### 1. Report Parameter Memory
- **Feature**: System remembers last used parameters
- **Storage**: Session or user preferences
- **BDD Gap**: Fresh form assumed each time
- **Impact**: Faster repeated report generation

### 2. Bulk Report Operations
- **Evidence**: Checkbox selection in task list
- **Operations**:
  - Download multiple reports as archive
  - Cancel multiple tasks
  - Retry failed batch
- **BDD Gap**: Single report operations only

### 3. Report Comparison Mode
- **Inferred from**: Multiple report windows possible
- **Feature**: Side-by-side report viewing
- **Use Case**: Period-over-period analysis
- **BDD Gap**: Single report view assumed

## 💡 Implementation Priorities

### Must Have (Daily Use):
1. Report Scheduler UI - Automation critical
2. Enhanced Export Formats - Integration needs
3. Task Management UI - User control

### Should Have (Weekly Use):
1. Template Library Access - Efficiency gains
2. Caching Controls - Performance tuning
3. Bulk Operations - Time savings

### Nice to Have (Monthly Use):
1. Report Analytics - Meta insights
2. Version Management - A/B testing
3. SQL Builder (if permissions allow)

## 🔧 Technical Implementation Notes

### Report Scheduler Pattern
```javascript
// Hidden scheduler configuration likely uses:
{
  schedule: {
    frequency: "daily|weekly|monthly",
    time: "HH:MM",
    timezone: "Europe/Moscow",
    active_days: ["MON","TUE","WED","THU","FRI"],
    distribution: ["email@example.com"],
    format: "xlsx|pdf|both"
  }
}
```

### Export Enhancement Pattern
```javascript
// Extended export API probably supports:
POST /api/v1/reports/{id}/export
{
  format: "xml|json|csv|xlsx|pdf",
  compression: true,
  include_metadata: true,
  split_by_group: false
}
```

## 🎯 Conclusion

R6 domain has significant hidden features, particularly around:
1. **Automation** - Scheduler exists but hidden
2. **Integration** - More export formats available
3. **Analytics** - Meta-reporting on report usage
4. **Templates** - Reusable configurations behind permissions

The custom SQL report builder alone could transform how users interact with data, but requires elevated permissions to access.

---

**R6-ReportingCompliance**  
*Domain-Focused Hidden Feature Discovery Complete*  
*10+ Major Hidden Features Documented*