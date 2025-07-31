# Report Generation API Patterns - R6 Discovery

**Source**: R6-ReportingCompliance Phase 1 API Research
**Date**: 2025-07-29
**Method**: MCP browser API monitoring during report interactions

## 🏗️ Architecture Discovery

### Framework: JSF with PrimeFaces (NOT REST)
Unlike modern REST APIs, Argus uses JavaServer Faces with PrimeFaces UI framework:
- ViewState-based form submissions
- Partial AJAX updates
- Session conversation tracking (cid parameter)
- Server-side component tree

## 📡 API Patterns Discovered

### 1. Report Configuration API Pattern
```http
POST /ccwfm/views/env/report/AhtReportView.xhtml?cid=7
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=aht_report_filter_form-period_start
javax.faces.partial.execute=aht_report_filter_form-period_start
javax.faces.behavior.event=valueChange
javax.faces.partial.event=change
aht_report_filter_form-period_start_input=29.07.2025
javax.faces.ViewState=4020454997303590642:-3928601112085208414
```

**Key Components**:
- `javax.faces.partial.ajax=true` - Enables partial page updates
- `javax.faces.source` - Component that triggered the request
- `javax.faces.ViewState` - Server session state tracking
- `cid=7` - Conversation scope ID

### 2. Report Task Execution Pattern
```
Flow:
1. Configure report parameters → ViewState updates
2. Submit report request → Task created server-side
3. Background processing → Task ID assigned
4. Poll for completion → Status updates
5. Download ready → Export link available
```

### 3. Report Types & URLs Mapping
```javascript
// Direct report URLs (require session):
/ccwfm/views/env/report/WorkerScheduleReportView.xhtml - График работы сотрудников
/ccwfm/views/env/report/AhtReportView.xhtml - Отчёт по AHT
/ccwfm/views/env/report/AbsenteeismNewReportView.xhtml - Отчёт по %absenteeism
/ccwfm/views/env/report/WorkerScheduleAdherenceReportView.xhtml - Соблюдение расписания
/ccwfm/views/env/report/T13FormReportView.xhtml - Расчёт заработной платы
/ccwfm/views/env/report/ForecastAndPlanReportView.xhtml - Отчёт по прогнозу и плану
/ccwfm/views/env/report/OperatorLateReportView.xhtml - Отчёт по опозданиям
/ccwfm/views/env/report/ReadyReportView.xhtml - Отчёт о %Ready
/ccwfm/views/env/report/WorkerWishReportView.xhtml - Отчёт по предпочтениям
/ccwfm/views/env/report/ResultsOfVacancyPlanningReportView.xhtml - Итоги планирования

// Report management:
/ccwfm/views/env/tmp/task/ReportTaskListView.xhtml - Task execution list
/ccwfm/views/env/tmp/ReportTypeMapView.xhtml - Custom report list
```

### 4. Form Structure Pattern
```javascript
// Standard report form IDs:
aht_report_filter_form - Main filter form
options_form - Export/action buttons
progress_form - Progress dialog
```

### 5. PrimeFaces Component Communication
```javascript
// Button onclick patterns:
PrimeFaces.onPost(); // Disabled state
PrimeFaces.bcn(this,event,...); // Behavior chain
PrimeFaces.ab({s:"form_id",...}); // AJAX behavior
```

## 🔐 Session Management

### ViewState Security
- Long encoded ViewState tokens (e.g., `4020454997303590642:-3928601112085208414`)
- Required for all form submissions
- Changes with each interaction
- Prevents CSRF attacks

### Conversation Scope
- `cid` parameter maintains conversation context
- Allows multi-step workflows
- Prevents concurrent modification

## 📊 Data Flow Observations

### Report Generation Lifecycle
1. **Configuration Phase**
   - Each field change triggers partial update
   - ViewState updates maintain form state
   - Validation happens server-side

2. **Execution Phase**
   - Submit creates background task
   - Task ID returned for tracking
   - Asynchronous processing begins

3. **Monitoring Phase**
   - Polling or page refresh shows status
   - Progress updates in task list
   - Error messages if generation fails

4. **Delivery Phase**
   - Successful tasks show download link
   - Export formats determined by report type
   - Files generated on-demand

## 🚨 Implementation Considerations

### For Replica Building
1. **Not REST-friendly** - Need JSF-compatible framework
2. **Stateful design** - ViewState management critical
3. **Component tree** - Server tracks UI component state
4. **AJAX patterns** - Partial updates, not full REST calls

### Security Implications
- ViewState prevents replay attacks
- Session-based security model
- No stateless JWT tokens observed
- Form tokens change per interaction

## 💡 Next Steps for API Research

### Priority Areas
1. **Export API Pattern** - How download URLs are generated
2. **Task Status API** - Polling mechanism for long-running reports
3. **Error Handling** - How validation errors are returned
4. **Bulk Operations** - Multiple report generation

### Recommended Approach
- Continue with R6 to capture export flow
- Use R2+R5 for request/approval APIs
- R7 for planning/template APIs
- Document JSF patterns vs REST expectations

## 🔍 Key Takeaway

**Argus uses JSF/PrimeFaces, NOT modern REST APIs**. This significantly impacts replica architecture decisions. The stateful, component-based approach requires different implementation strategies than typical REST/SPA architectures.

---

*Note: This is Phase 1 discovery. Additional patterns expected as more workflows are tested.*