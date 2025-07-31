# Monitoring Dashboard Real-time API Patterns - R6 Discovery

**Source**: R6-ReportingCompliance API Research
**Date**: 2025-07-29
**Method**: MCP browser monitoring of live dashboard

## 🔄 Dashboard Auto-Refresh Pattern

### PrimeFaces Poll Mechanism
```javascript
// Configuration discovered:
{
  widgetId: "widget_dashboard_form_j_idt232",
  frequency: 60,  // seconds
  autoStart: true
}
```

### API Pattern Captured
```http
POST /ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml?cid=7
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=dashboard_form-j_idt232
javax.faces.partial.execute=@all
javax.faces.partial.render=dashboard_form
dashboard_form-j_idt232=dashboard_form-j_idt232
javax.faces.ViewState=[ViewState Token]
```

### Key Characteristics
1. **Interval**: Exactly 60 seconds between polls
2. **Mechanism**: JSF AJAX partial page update
3. **Scope**: Updates entire dashboard form (`@all` execution)
4. **Stateful**: Requires ViewState token for each request
5. **Session**: Uses conversation ID (cid) parameter

## 🏗️ Implementation Pattern

### JSF/PrimeFaces Poll Widget
```xml
<p:poll interval="60" 
        listener="#{monitoringDashboardBean.refresh}"
        update="dashboard_form"
        autoStart="true" />
```

### Server-Side Pattern
- Bean method called every 60 seconds
- Returns updated dashboard data
- JSF automatically handles partial rendering
- No REST endpoints - pure JSF lifecycle

## 📊 Data Update Flow

1. **Client Poll**: JavaScript timer triggers after 60s
2. **AJAX Request**: Sends form data with ViewState
3. **Server Processing**: 
   - Validates ViewState
   - Calls bean refresh method
   - Queries current operator status
   - Prepares response
4. **Partial Response**: 
   - Only updated components sent
   - ~2KB response size (efficient)
5. **DOM Update**: PrimeFaces updates dashboard

## 🔍 Monitoring Other Components

### Operator Status View
- Same pattern but potentially different interval
- URL: `/ccwfm/views/env/monitoring/OperatorStatusView.xhtml`

### Group Management Monitoring  
- URL: `/ccwfm/views/env/monitoring/GroupManagementView.xhtml`
- Likely uses same PrimeFaces Poll pattern

## 💡 Implications for Replica

### Architecture Requirements
1. **Stateful Framework**: Need JSF or equivalent stateful framework
2. **WebSocket Alternative**: Could modernize with WebSocket for efficiency
3. **Polling Library**: Or use polling library that mimics PrimeFaces behavior
4. **Session Management**: Must maintain conversation state

### Performance Considerations
- 60-second interval is reasonable for WFM
- Full form execution (`@all`) might be optimized
- Consider differential updates for large dashboards
- ViewState size impacts bandwidth

## 🚀 Modern Alternative

### WebSocket Implementation
```javascript
// Modern real-time approach
const ws = new WebSocket('wss://server/monitoring');
ws.onmessage = (event) => {
  updateDashboard(JSON.parse(event.data));
};
```

### Server-Sent Events (SSE)
```javascript
// One-way real-time updates
const eventSource = new EventSource('/api/monitoring/stream');
eventSource.onmessage = (event) => {
  updateDashboard(JSON.parse(event.data));
};
```

## 📝 Summary

Argus uses classic JSF/PrimeFaces polling for real-time monitoring:
- ✅ Simple and reliable
- ✅ Works through firewalls
- ✅ Automatic reconnection
- ❌ Higher bandwidth usage
- ❌ 60-second delay for updates
- ❌ Stateful (ViewState required)

For a modern replica, consider WebSocket or SSE for true real-time updates while maintaining compatibility with JSF polling pattern for gradual migration.