# New API Endpoints Discovered - R0-GPT Live Monitoring Exploration
**Date**: 2025-07-30
**Source**: Live MCP exploration of monitoring interfaces
**Status**: These APIs are NOT documented in _ALL_ENDPOINTS.md but are actively used

## 🚨 CRITICAL: Missing Monitoring APIs

Based on my live exploration of the monitoring module, I discovered several API patterns that power the real-time functionality but are **completely missing** from our API documentation.

## Real-time Polling APIs

### 1. Dashboard Polling Endpoint
```yaml
endpoint: "UNKNOWN - Inferred from AJAX calls"
method: "POST (likely)"
purpose: "60-second dashboard polling updates"
evidence: |
  PrimeFaces.ab({
    s:"dashboard_form-j_idt232",
    f:"dashboard_form", 
    u:"dashboard_form",
    ps:true
  });
usage: "Called every 60 seconds automatically"
parameters:
  - "conversation ID (cid)"
  - "ViewState token" 
  - "Page update counter"
response: "Updated dashboard HTML fragments"
```

### 2. Operator Status Updates
```yaml
endpoint: "UNKNOWN - Real-time operator data"
evidence: "Live operator 'Николай 1' with status 'Отсутствует'"
purpose: "Individual operator status tracking"
update_frequency: "Real-time (likely every 15-60 seconds)"
data_structure:
  - operator_name: "Николай 1"
  - status: "Отсутствует|Готов|Перерыв|etc"
  - schedule_compliance: "Boolean"
  - cov_status: "String"
  - last_activity: "Timestamp"
```

### 3. Group Management Control APIs
```yaml
endpoint: "UNKNOWN - Group enable/disable"
evidence: "'Отключить группу' button functionality"
purpose: "Administrative group control"
operations:
  - "Enable group"
  - "Disable group" 
  - "Get group status"
  - "List active groups"
current_response: "Нет активных групп (No active groups)"
```

### 4. Threshold Configuration APIs
```yaml
endpoint: "UNKNOWN - Service/Group threshold settings"
evidence: "8 services with threshold configuration"
services_found:
  - "Служба технической поддержки"
  - "КЦ (Call Center)"
  - "КЦтест" 
  - "Финансовая служба"
  - "КЦ3 проект"
  - "КЦ1проект"
  - "КЦ2 проект"
  - "Обучение"
hierarchy: "Service → Group → Threshold Type"
dynamic_loading: "Groups populate based on service selection"
```

## Session Management APIs

### 5. Argus System Page Updates
```yaml
pattern: "Argus.System.Page.update(1-5)"
purpose: "Page state tracking across navigation"
evidence: "Incrementing counters across monitoring views"
integration: "Custom Argus framework session management"
conversation_tracking: "cid parameter for session continuity"
```

### 6. Menu State Persistence
```yaml
pattern: "Modena.restoreMenuState()"
purpose: "Restore menu navigation state"
evidence: "Called on every monitoring page load"
storage: "Browser-side state persistence"
scope: "Navigation menu expansion/collapse states"
```

### 7. ViewState Management
```yaml
pattern: "JSF ViewState tokens in forms"
purpose: "Page state security and validation"
evidence: "ViewState parameters in monitoring forms"
security: "Prevents CSRF and ensures page integrity"
lifespan: "Per-conversation (22-minute timeout)"
```

## Notification System APIs

### 8. Notification Badge Updates
```yaml
endpoint: "UNKNOWN - Real-time notification count"
evidence: "Unread notification badges (1 unread shown)"
categories:
  - "Report generation status"
  - "System alerts"
  - "Error notifications"
update_mechanism: "Real-time badge count updates"
dropdown_preview: "Notification history with timestamps"
```

### 9. Task Queue APIs
```yaml
endpoint: "UNKNOWN - Task management system"  
evidence: "Task inbox badges in top navigation"
integration: "/ccwfm/views/env/tmp/task/ReportTaskListView.xhtml"
purpose: "Async operation tracking and task delegation"
features:
  - "Task count badges"
  - "Task status updates"
  - "Queue management"
```

## Missing from Current API Documentation

### What's NOT in _ALL_ENDPOINTS.md:
1. **Real-time polling infrastructure** - No endpoints for 60-second updates
2. **Administrative monitoring controls** - No group management APIs
3. **Session management APIs** - No Argus.System integration endpoints
4. **Notification system APIs** - No real-time notification endpoints
5. **Task queue APIs** - No async operation tracking endpoints
6. **Threshold configuration APIs** - No alerting configuration endpoints

### Impact on Implementation:
- **Backend APIs missing**: Need to create all monitoring backend endpoints
- **Real-time architecture**: WebSocket/SSE or polling infrastructure required
- **Session management**: Argus.System compatibility layer needed
- **Database schema**: Operator status, group management, threshold tables required

## Recommended API Additions to _ALL_ENDPOINTS.md:

```yaml
# Real-time Monitoring APIs (NEW)
monitoring_apis:
  - "GET /api/v1/monitoring/dashboard/status": Dashboard overview data
  - "GET /api/v1/monitoring/operators/status": Real-time operator status list
  - "PUT /api/v1/monitoring/groups/{id}/disable": Disable group administratively
  - "PUT /api/v1/monitoring/groups/{id}/enable": Enable group administratively
  - "GET /api/v1/monitoring/groups/active": List active groups
  - "POST /api/v1/monitoring/thresholds": Configure alert thresholds
  - "GET /api/v1/monitoring/thresholds/{service_id}": Get service thresholds

# Session & State Management APIs (NEW)  
session_apis:
  - "POST /api/v1/session/page-update": Argus.System page state tracking
  - "GET /api/v1/session/menu-state": Retrieve menu navigation state
  - "PUT /api/v1/session/menu-state": Update menu navigation state
  - "POST /api/v1/session/viewstate/validate": ViewState token validation

# Notification System APIs (NEW)
notification_apis:
  - "GET /api/v1/notifications/unread-count": Real-time notification badge count
  - "GET /api/v1/notifications/recent": Recent notifications for dropdown
  - "PUT /api/v1/notifications/{id}/read": Mark notification as read
  - "GET /api/v1/tasks/queue-count": Task queue badge count
  - "GET /api/v1/tasks/pending": Pending task list
```

## Next Steps:
1. **Add these APIs** to _ALL_ENDPOINTS.md
2. **Design backend implementation** for real-time monitoring
3. **Plan WebSocket/SSE architecture** for live updates  
4. **Create session management** compatibility layer
5. **Implement notification system** with real-time updates

## Critical Note:
These APIs represent **the missing 300% complexity** I discovered in the monitoring module. Without these endpoints, the monitoring functionality **cannot be implemented** to match Argus system capabilities.