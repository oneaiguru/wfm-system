# Comprehensive API Capture Plan - Building on Discoveries

**Date**: 2025-07-29
**Based on**: R6 JSF discovery + R2 Vue.js/REST discovery
**Purpose**: Systematic API documentation for BDD implementation

## 🏗️ Confirmed Dual Architecture

### Admin Portal (JSF/PrimeFaces)
- **URL Pattern**: `/ccwfm/views/env/*`
- **Framework**: JavaServer Faces + PrimeFaces
- **API Style**: Stateful ViewState-based
- **Auth**: Session cookies
- **Users**: Konstantin, managers, admins

### Employee Portal (Vue.js)
- **URL Pattern**: `/gw/api/v1/*`
- **Framework**: Vue.js + Vuetify SPA
- **API Style**: REST with JSON
- **Auth**: JWT Bearer tokens
- **Users**: test, employees

## 🎯 Priority API Discovery Areas

### 1. Report Generation Complete Lifecycle (R6 Domain)

#### What We Know:
- JSF ViewState submission for config
- Task-based async execution
- Missing: polling mechanism, export APIs

#### Discovery Plan:
```javascript
// Enhanced monitoring for report lifecycle
window.REPORT_LIFECYCLE_MONITOR = {
  taskCreation: [],      // POST that creates task
  statusPolling: [],     // GET/POST checking status
  exportGeneration: [],  // File creation trigger
  downloadUrls: []       // Final download links
};

// Capture sequence:
1. Configure report → Capture form submission
2. Monitor for task ID response
3. Track polling requests (likely every 5-30 seconds)
4. Capture completion notification
5. Track export/download URL generation
```

#### Expected APIs:
```http
// Task creation
POST /ccwfm/views/env/report/generateReport.xhtml
Response: { taskId: "12345", status: "PENDING" }

// Status polling  
POST /ccwfm/views/env/task/checkStatus.xhtml
Payload: javax.faces.ViewState=...&taskId=12345

// Export trigger
GET /ccwfm/export/report/12345.xlsx
```

### 2. Real-time Monitoring & Thresholds (R6 Domain)

#### What We Need:
- Dashboard auto-refresh mechanism
- Threshold checking frequency
- Alert propagation

#### Discovery Plan:
```javascript
// Monitor dashboard refresh patterns
1. Open Operational Control dashboard
2. Wait 60+ seconds (documented refresh interval)
3. Capture:
   - PrimeFaces Poll requests
   - Data update payloads
   - Threshold violation alerts
```

#### Expected Pattern:
```javascript
// PrimeFaces Poll
setInterval(() => {
  POST /ccwfm/views/env/monitoring/refreshDashboard.xhtml
  javax.faces.source=poll_widget
}, 60000);
```

### 3. Reference Data Complete CRUD (R6 Domain)

#### Discovery Plan:
```javascript
// Test with simple reference data (e.g., Absence Reasons)
1. CREATE: Add new absence reason
   - Capture validation API
   - Capture save endpoint
   
2. READ: Already captured (list views)

3. UPDATE: Edit existing reason
   - Capture field validation
   - Capture update endpoint
   
4. DELETE: Remove reason
   - Capture dependency check
   - Capture soft/hard delete pattern
```

### 4. Request/Approval Flow (R2+R5 Collaboration)

#### Current Blocker:
- R2 found Vue.js bug prevents request creation
- Need alternative approach

#### Modified Plan:
```javascript
// Option A: Fix Vue.js bug first
1. Debug why reason field clears
2. Create working request
3. Capture: POST /gw/api/v1/requests/create

// Option B: Create via Admin Portal
1. R5 creates request FOR employee
2. Capture JSF request creation
3. R2 monitors employee notification
4. Capture cross-portal sync APIs
```

### 5. Integration & Sync Patterns

#### Critical to Discover:
- How JSF admin actions reflect in Vue.js employee portal
- Event propagation mechanism
- Data consistency approach

#### Discovery Plan:
```javascript
// Cross-portal monitoring
1. R5 performs action in admin (JSF)
2. R2 monitors employee portal for updates
3. Capture:
   - Push notifications?
   - Polling intervals?
   - WebSocket connections?
   - Event bus pattern?
```

## 🔧 Universal Monitoring Script V2

```javascript
// Enhanced for complete capture
// Add pattern-specific collectors

window.API_PATTERNS = {
  // JSF Patterns
  viewStateChanges: [],
  partialAjaxCalls: [],
  conversationTracking: new Map(),
  
  // REST Patterns  
  jwtRefreshes: [],
  restEndpoints: new Set(),
  
  // Report Patterns
  taskLifecycle: new Map(), // taskId -> [creation, polls, completion]
  exportRequests: [],
  
  // Real-time Patterns
  pollingIntervals: new Map(), // endpoint -> intervals
  pushNotifications: [],
  
  // CRUD Patterns
  createOperations: [],
  updateOperations: [],
  deleteOperations: [],
  validationCalls: []
};

// Enhance XMLHttpRequest to categorize
const enhanceXHR = (xhr, method, url) => {
  // Categorize by pattern
  if (url.includes('task')) {
    xhr._category = 'task_management';
  } else if (url.includes('export') || url.includes('download')) {
    xhr._category = 'file_operations';
  } else if (method === 'DELETE' || url.includes('delete')) {
    xhr._category = 'crud_delete';
  } else if (url.includes('validate')) {
    xhr._category = 'validation';
  }
  // ... more categories
};
```

## 📊 Structured Deliverables

### Per Discovery Area:
```yaml
REPORT_LIFECYCLE_COMPLETE.md:
  - Task creation API with payload structure
  - Polling mechanism (interval, endpoint, response)
  - Completion detection pattern
  - Export URL generation
  - File cleanup timing

MONITORING_REALTIME.md:
  - PrimeFaces Poll configuration
  - Data refresh payloads
  - Threshold checking logic
  - Alert propagation flow
  - Performance implications

REFERENCE_CRUD_PATTERNS.md:
  - Create with validation flow
  - Update with optimistic locking
  - Delete with dependency checking
  - Bulk operations support
  - Audit trail integration

DUAL_PORTAL_SYNC.md:
  - JSF → Vue.js data flow
  - Event propagation mechanism
  - Consistency guarantees
  - Latency characteristics
  - Conflict resolution

AUTHENTICATION_COMPARISON.md:
  - JSF session management
  - JWT token lifecycle
  - Cross-portal SSO (if any)
  - Permission synchronization
  - Timeout handling
```

## 🚀 Execution Strategy

### Phase 1: Complete R6 Domain (Reports, Monitoring, References)
- Use existing Konstantin session
- Systematic CRUD testing
- Full report lifecycle capture
- Dashboard monitoring patterns

### Phase 2: Cross-Portal Integration
- R5 creates on behalf of employee (workaround)
- R2 monitors employee portal updates
- Document sync mechanisms
- Capture notification patterns

### Phase 3: Architecture Documentation
- Consolidate all findings
- Create implementation guide
- Document framework differences
- Provide migration strategies

## 💡 Key Success Factors

1. **Systematic Approach**: Test each CRUD operation completely
2. **Timing Awareness**: Wait for async operations, polling intervals
3. **Error Scenarios**: Trigger validation failures, dependencies
4. **Cross-Portal**: Always check both portals for changes
5. **Framework Specific**: JSF ViewState vs REST JSON patterns

## 🎯 Ultimate Goal

Create documentation so detailed that developers can:
1. Understand exact API contracts
2. Replicate the dual architecture
3. Implement proper state management
4. Handle all edge cases
5. Maintain data consistency across portals

This plan leverages our discoveries (JSF admin + Vue.js employee) to systematically document every API interaction needed for BDD implementation!