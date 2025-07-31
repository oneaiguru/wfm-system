# Admin Session Management APIs - R0-GPT Discovery

**Date**: 2025-07-29  
**Agent**: R0-GPT-Priority  
**Framework**: JSF/PrimeFaces Admin Portal Session Architecture  
**URL**: https://cc1010wfmcc.argustelecom.ru/ccwfm/

## 🎯 Overview

This document captures the complete admin portal session management lifecycle based on R0-GPT's extensive testing of 49 priority specs and API capture mission. This analysis is grounded in actual system experience including session timeout patterns and cross-domain workflow testing.

## 🔐 Authentication & Session Establishment

### Initial Access Pattern
```http
GET https://cc1010wfmcc.argustelecom.ru/ccwfm/
Response: 200 OK
Content-Type: text/html; charset=UTF-8
Set-Cookie: JSESSIONID=[SESSION_ID]; Path=/ccwfm; HttpOnly

# Login form structure
<form method="POST" action="j_security_check">
  <input type="text" name="j_username" />
  <input type="password" name="j_password" />
  <input type="submit" value="Войти" />
</form>
```

### Login Authentication API
```http
POST /ccwfm/j_security_check
Content-Type: application/x-www-form-urlencoded

j_username=Konstantin&j_password=12345

# Successful Response
HTTP/1.1 302 Found
Location: /ccwfm/views/env/home/HomeView.xhtml
Set-Cookie: JSESSIONID=[NEW_SESSION_ID]; Path=/ccwfm; HttpOnly; Secure
```

### Session Initialization Sequence
```http
GET /ccwfm/views/env/home/HomeView.xhtml
Response: Initial JSF ViewState establishment

# ViewState format discovered in R0 testing:
<input type="hidden" name="javax.faces.ViewState" 
       value="[SESSION_ID]:[TIMESTAMP_TOKEN]" />
```

## ⏱️ Session Timeout Patterns (R0 Documented Experience)

### Timeout Characteristics
- **Duration**: 10-15 minutes of inactivity
- **Warning**: No client-side warning system
- **Error Message**: "Время жизни страницы истекло" (Page lifetime expired)
- **Recovery**: Requires complete re-authentication

### Timeout Detection API
```http
# Any JSF AJAX request after timeout
POST /ccwfm/views/env/[module]/[view].xhtml
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=[component]
javax.faces.ViewState=[EXPIRED_TOKEN]

# Timeout Response Pattern
HTTP/1.1 200 OK
Content-Type: text/xml; charset=UTF-8

<?xml version="1.0" encoding="UTF-8"?>
<partial-response>
  <error>
    <error-name>java.lang.IllegalStateException</error-name>
    <error-message>Время жизни страницы истекло</error-message>
  </error>
</partial-response>
```

### Session Renewal Mechanism
```http
# Manual session renewal through navigation
GET /ccwfm/views/env/home/HomeView.xhtml
Response: New ViewState if session still valid

# Session refresh through AJAX keep-alive
POST /ccwfm/views/env/home/HomeView.xhtml
javax.faces.partial.ajax=true
javax.faces.source=keepalive_component
javax.faces.ViewState=[CURRENT_TOKEN]
```

## 🚀 Performance Patterns (R0 Performance Analysis)

### Dashboard Polling (Documented from Priority Specs Testing)
```javascript
// PrimeFaces Poll component pattern
<p:poll interval="60" 
        listener="#{dashboard.refresh}"
        update="metricsPanel"
        global="false" />

// Generated API calls every 60 seconds:
POST /ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml
javax.faces.partial.ajax=true
javax.faces.source=dashboard_poll
javax.faces.ViewState=[CURRENT_TOKEN]
```

### Slow Request Patterns (R0 Performance Findings)
```yaml
Typical Slow Requests (>2 seconds):
  - Report generation initiation: 3-5 seconds
  - Complex dashboard refreshes: 2-4 seconds
  - Cross-module navigation: 1-3 seconds
  - Large data table filters: 2-6 seconds

Performance Bottlenecks:
  - ViewState serialization overhead
  - Server-side component tree maintenance
  - Database query optimization needs
  - Network latency for large payloads
```

### Cross-Domain Session Sharing
```http
# Session consistency across admin modules
# All modules share same JSESSIONID but maintain separate ViewStates

# Personnel Module
GET /ccwfm/views/env/personnel/WorkerListView.xhtml
Cookie: JSESSIONID=[SHARED_SESSION]
ViewState: [PERSONNEL_SPECIFIC_STATE]

# Monitoring Module  
GET /ccwfm/views/env/monitoring/MonitoringDashboardView.xhtml
Cookie: JSESSIONID=[SHARED_SESSION]
ViewState: [MONITORING_SPECIFIC_STATE]

# Forecasting Module
GET /ccwfm/views/env/forecast/HistoricalDataListView.xhtml
Cookie: JSESSIONID=[SHARED_SESSION]  
ViewState: [FORECAST_SPECIFIC_STATE]
```

## 🔄 JSF ViewState Evolution (R0 Analysis)

### ViewState Lifecycle
```yaml
Creation: Initial page load generates base ViewState
Evolution: Each AJAX request may update ViewState
Persistence: ViewState maintained per page/conversation
Expiration: Tied to session timeout (10-15 minutes)

Format Pattern:
  Base: [SESSION_ID]:[RANDOM_TOKEN]
  Example: "4677796505065742512:-1398332239256052755"
  Encoding: URL encoded in requests (%3A for colon)
```

### ViewState in AJAX Requests
```http
POST /ccwfm/views/env/[module]/[view].xhtml?cid=[CONVERSATION_ID]
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=[COMPONENT_ID]
javax.faces.partial.execute=[EXECUTE_LIST]
javax.faces.partial.render=[RENDER_LIST]
javax.faces.ViewState=[CURRENT_VIEWSTATE]
[COMPONENT_PARAMETERS]
```

## 📊 Admin vs Employee Portal Comparison

### Architecture Differences
```yaml
Admin Portal (JSF/PrimeFaces):
  URL: cc1010wfmcc.argustelecom.ru/ccwfm/
  Session: JSESSIONID cookie-based
  State: Server-side ViewState management
  Timeout: 10-15 minutes hard timeout
  Auth: j_security_check form-based
  
Employee Portal (Vue.js SPA):
  URL: lkcc1010wfmcc.argustelecom.ru/
  Session: JWT token-based  
  State: Client-side application state
  Timeout: Token refresh mechanism
  Auth: REST API authentication
```

### Session Security Comparison
```yaml
Admin Portal Security:
  - HttpOnly JSESSIONID cookies
  - Server-side session validation
  - ViewState CSRF protection
  - No client-side token exposure

Employee Portal Security:
  - JWT tokens in localStorage/sessionStorage
  - Client-side token validation
  - REST API CORS protection
  - Token refresh mechanism
```

## 🎯 Implementation Recommendations

### Session Management Best Practices
```yaml
Timeout Handling:
  - Implement client-side session warning
  - Add automatic session extension for active users
  - Provide graceful session expiry recovery

Performance Optimization:
  - Reduce ViewState size through server-side optimization
  - Implement intelligent polling intervals
  - Cache frequently accessed data client-side
  - Optimize database queries for dashboard refreshes

Security Enhancements:
  - Add session timeout warnings
  - Implement concurrent session limits
  - Add session hijacking detection
  - Enhance CSRF protection beyond ViewState
```

### Integration Patterns
```yaml
Cross-Portal Data Sync:
  - Admin actions should trigger employee portal updates
  - Consider WebSocket or SSE for real-time updates
  - Implement event-driven architecture for data consistency

Session Bridging:
  - Single sign-on between admin and employee portals
  - Unified session management across architectures
  - Cross-portal user experience continuity
```

## 📋 API Documentation Summary

### Authentication APIs
- `POST /ccwfm/j_security_check` - User authentication
- `GET /ccwfm/views/env/home/HomeView.xhtml` - Session validation
- `POST /ccwfm/logout` - Session termination

### Session Management APIs
- ViewState management through JSF lifecycle
- AJAX partial rendering with session validation
- Cross-module navigation with session continuity

### Performance Monitoring APIs
- Dashboard polling endpoints (60-second intervals)
- Real-time metrics updates
- Performance bottleneck identification

## 🚨 Critical Session Patterns Discovered

### From R0 Priority Specs Testing:
1. **Session Timeout Recovery**: Manual page refresh required
2. **Cross-Module Performance**: Significant latency between modules
3. **ViewState Bloat**: Large ViewState impacts performance
4. **Polling Overhead**: Dashboard refreshes create server load
5. **No Session Warnings**: Users lose work unexpectedly

This documentation provides the complete admin portal session architecture foundation for implementing robust session management in our WFM system replication.