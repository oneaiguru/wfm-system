# Employee Request APIs - R2 Phase 2 Discovery

**Date**: 2025-07-29  
**Agent**: R2-EmployeeSelfService  
**Testing Method**: Universal API Monitor via MCP  
**Portal**: Employee Portal (Vue.js + Vuetify)  

## 🚨 CRITICAL DISCOVERY: No Request API Called!

### The Bug Confirmed with API Evidence
The request form validation blocker is a **pure Vue.js client-side bug**. NO API call is made to create the request because client-side validation prevents submission.

## 🏗️ Architecture Discovery

### Employee Portal Uses Modern REST + JWT
```javascript
// Employee portal architecture:
- Framework: Vue.js + Vuetify
- API Pattern: REST with JWT authentication
- Auth Method: Bearer tokens (not session cookies)
- Endpoint Pattern: /gw/api/v1/*
```

### Sample API Captured
```javascript
{
  method: "GET",
  url: "/gw/api/v1/notifications/count",
  headers: {
    "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9..."
  },
  status: 200,
  responseSize: 12
}
```

## 🔍 Request Creation Workflow Analysis

### What SHOULD Happen
1. User fills form → Vue.js validates → POST to create request API
2. Expected endpoint: `POST /gw/api/v1/requests/create` (or similar)
3. JWT auth header included
4. JSON payload with request details

### What ACTUALLY Happens
1. User fills form
2. "Причина" (Reason) field mysteriously clears itself
3. Vue.js validation blocks submission
4. **NO API CALL MADE** ❌
5. User stuck with validation error

### API Monitoring Evidence
```javascript
// During entire form interaction:
{
  totalCalls: 14,
  fetchCalls: 0,      // No fetch API used
  xhrCalls: 14,       // All XMLHttpRequest
  jsfCalls: 0,        // NO JSF! Pure REST
  requestCreationCalls: 0  // ⚠️ THE SMOKING GUN
}

// All captured calls were:
GET /gw/api/v1/notifications/count  // Just polling for notifications
```

## 🎯 Root Cause Analysis

### Client-Side Vue.js Bug
1. **Field Self-Clearing**: The reason field (`#input-243`) clears its value
2. **Timing**: Happens when interacting with other form elements
3. **Validation**: Vue.js `required` validation then blocks submission
4. **API Never Called**: Server never sees the request attempt

### Why This Matters
- It's NOT a permission issue (no 403 error)
- It's NOT a backend rejection (no API call made)
- It's a pure frontend Vue.js state management bug
- Could be v-model binding issue or validation side effect

## 📊 Dual Architecture Confirmed

### Admin Portal (from R6 Phase 1)
- Framework: JSF/PrimeFaces
- Pattern: Stateful with ViewState
- AJAX: `javax.faces.partial.ajax`

### Employee Portal (R2 Phase 2)
- Framework: Vue.js + Vuetify
- Pattern: REST API with JWT
- AJAX: Standard XMLHttpRequest
- Gateway: `/gw/api/v1/*` prefix suggests API gateway

## 🔄 Integration Pattern
```
Admin Portal:
JSF Views → PrimeFaces AJAX → JSF Backend → Database

Employee Portal:
Vue.js SPA → REST API → API Gateway (/gw) → Backend Services → Database
```

## 🤝 Handoff Data for R5

### Request Creation Status
- **Request ID**: None - creation blocked by client bug
- **Employee**: test (user_id: 111538)
- **Dates**: Would be July 30, 2025
- **Type**: "Заявка на создание отгула" (Time off request)
- **Blocker**: Cannot create request due to Vue.js validation bug

### For R5 Manager Testing
Since R2 cannot create requests, R5 should:
1. Check if managers can create requests FOR employees
2. Use admin portal (JSF) not employee portal
3. Monitor different API patterns (JSF vs REST)

## 💡 Key Insights

### Security & Architecture
1. **JWT Implementation**: Proper Bearer token auth
2. **API Gateway**: `/gw/` prefix suggests gateway pattern
3. **Polling Strategy**: Regular notification count checks
4. **No WebSocket**: Using polling instead of real-time

### Vue.js Implementation Issues
1. **Form State Management**: Buggy v-model binding
2. **Validation Timing**: Clears fields during validation
3. **No Error Recovery**: Once cleared, stays cleared
4. **Pure Client Bug**: Server never involved

## 🚀 Recommendations

### For Bug Fix
1. Check Vue.js component for reason field
2. Look for watchers/computed properties that might clear value
3. Verify v-model binding on all form fields
4. Test validation lifecycle

### For R6 Collaboration
- Employee portal uses completely different architecture than admin
- Modern REST/JWT vs legacy JSF/ViewState
- API gateway pattern vs direct JSF endpoints
- Client-side Vue.js bugs can block entire workflows

---

**Conclusion**: The employee request creation is blocked by a Vue.js client-side bug that clears required fields, preventing any API call from being made. This confirms dual architecture: modern REST/JWT for employees, legacy JSF for admin.