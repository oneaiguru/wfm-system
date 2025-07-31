# JSF API Patterns Explained - For React Implementation Teams

**Date**: 2025-07-29  
**Purpose**: Help React frontend teams understand Argus admin API behavior patterns  
**Source**: Consolidated from R1, R6, R7 API discoveries  

## 🎯 Overview

Argus has **TWO SEPARATE PORTALS** with different architectures:

### **Admin Portal** (JSF/PrimeFaces)
- **URL**: `https://cc1010wfmcc.argustelecom.ru/ccwfm/`
- **Architecture**: JavaServer Faces (JSF) with PrimeFaces - NOT REST APIs
- **Scope**: User management, role assignment, reporting, system configuration
- **This document covers**: Admin portal JSF patterns only

### **Employee Portal** (Vue.js)  
- **URL**: `https://lkcc1010wfmcc.argustelecom.ru/`
- **Architecture**: Vue.js SPA with REST APIs and JWT tokens
- **Scope**: Employee self-service, time-off requests, personal schedules
- **Integration**: Database-only sync with admin portal (no cross-portal APIs)

⚠️ **CRITICAL**: These are completely separate systems. JSF patterns apply ONLY to admin portal APIs.

## 🔑 Critical JSF Concepts Affecting APIs

### 1. ViewState Tokens (REQUIRED for ALL API calls)

**What it is**: Server-generated token that must be included in every POST request
```javascript
// Example ViewState token
"4020454997303590642:-3928601112085208414"

// Required in EVERY API call
const apiCall = {
  method: 'POST',
  body: new URLSearchParams({
    'javax.faces.ViewState': viewStateToken,
    // ... other parameters
  })
}
```

**Why it matters for React**:
- ❌ No stateless JWT - every call needs current ViewState
- ❌ Cannot cache ViewState - changes with each interaction
- ✅ Must extract ViewState from each response for next call

### 2. Session-Based Architecture (Admin Portal Only)

**JSF Admin Portal Session Pattern**:
```javascript
// JSF maintains server-side session state (ADMIN PORTAL ONLY)
const adminSessionPattern = {
  authentication: 'JSESSIONID cookie (not JWT)',
  stateManagement: 'Server-side ViewState',
  conversation: 'cid parameter tracks workflow',
  timeout: 'ViewState expires, session becomes invalid',
  scope: 'Admin portal only - separate from employee portal'
}
```

**Portal Separation**:
- **Admin Portal**: JSF session with ViewState (this document)
- **Employee Portal**: JWT tokens with Vue.js (separate system)
- **No Shared Sessions**: Cannot use admin session for employee portal

**React Implementation Impact**:
- Must maintain session cookies across requests
- Cannot replay requests without valid session
- Need session timeout handling
- Load balancing requires sticky sessions

### 3. Component-Based API Calls (Admin Portal Only)

**JSF Admin Portal Pattern**:
```http
POST /ccwfm/views/env/personnel/WorkerListView.xhtml?cid=2
Content-Type: application/x-www-form-urlencoded

javax.faces.partial.ajax=true
javax.faces.source=worker_search_form-add_worker_button
javax.faces.partial.execute=worker_search_form-add_worker_button
javax.faces.ViewState=4020454997303590642:-3928601112085208414
worker_search_form-add_worker_button=worker_search_form-add_worker_button
```

**Admin Portal Characteristics**:
- No `/api/users` endpoints - URLs point to JSF views  
- Component IDs determine what action happens
- Form-encoded data, not JSON
- Must include JSF lifecycle parameters

**Portal Architecture Comparison**:
| Admin Portal (JSF) | Employee Portal (Vue.js) |
|-------------------|--------------------------|
| `/ccwfm/views/env/personnel/WorkerListView.xhtml` | `/api/employees` |
| Form-encoded requests | JSON requests |
| ViewState required | JWT tokens |
| Component-based calls | RESTful endpoints |

## 📊 API Call Patterns by Operation Type

### 1. CRUD Operations Pattern

**User Creation API Call**:
```javascript
// React must make this exact call structure
const createUser = async (viewState, sessionCookies) => {
  const response = await fetch('/ccwfm/views/env/personnel/WorkerListView.xhtml?cid=2', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': sessionCookies,
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: new URLSearchParams({
      'javax.faces.partial.ajax': 'true',
      'javax.faces.source': 'worker_search_form-add_worker_button',
      'javax.faces.partial.execute': 'worker_search_form-add_worker_button',
      'javax.faces.ViewState': viewState,
      'worker_search_form-add_worker_button': 'worker_search_form-add_worker_button',
      'worker_search_form': 'worker_search_form'
    }).toString()
  });
  
  // CRITICAL: Extract new ViewState from response for next call
  const newViewState = extractViewStateFromResponse(await response.text());
  return { response, newViewState };
};
```

**Key React Considerations**:
- Two-step process: Generate blank user, then save details
- Each step requires separate API call with updated ViewState
- Auto-generated User-ID returned in response HTML (not JSON)

### 2. Report Generation Pattern

**Report Configuration API Call**:
```javascript
// React must configure report parameters one by one
const configureReport = async (reportType, parameter, value, viewState) => {
  return await fetch(`/ccwfm/views/env/report/${reportType}ReportView.xhtml?cid=7`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': sessionCookies
    },
    body: new URLSearchParams({
      'javax.faces.partial.ajax': 'true',
      'javax.faces.source': `${reportType}_filter_form-${parameter}`,
      'javax.faces.partial.execute': `${reportType}_filter_form-${parameter}`,
      'javax.faces.behavior.event': 'valueChange',
      'javax.faces.partial.event': 'change',
      [`${reportType}_filter_form-${parameter}_input`]: value,
      'javax.faces.ViewState': viewState
    }).toString()
  });
};
```

**React Implementation Challenge**:
- Each parameter change is separate API call
- Background task creation returns task ID in HTML response
- Must poll for completion (no WebSocket notifications)

### 3. Data Selection Pattern

**Template Selection API Call**:
```javascript
// DataTable row selection requires specific JSF parameters
const selectTemplate = async (templateId, viewState) => {
  return await fetch('/ccwfm/views/env/planning/SchedulePlanningView.xhtml?cid=4', {
    method: 'POST',
    body: new URLSearchParams({
      'javax.faces.partial.ajax': 'true',
      'javax.faces.source': 'templates_form-templates',
      'javax.faces.partial.execute': 'templates_form-templates',
      'javax.faces.behavior.event': 'rowSelect',
      'javax.faces.partial.event': 'rowSelect',
      'templates_form-templates_instantSelectedRowKey': templateId,
      'templates_form-templates_selection': templateId,
      'templates_form-templates_scrollState': '0,0',
      'javax.faces.ViewState': viewState
    }).toString()
  });
};
```

## 🔄 ViewState Management for React

### ViewState Extraction from Responses

```javascript
// Method 1: Extract from XML response (AJAX calls)
function extractViewStateFromXML(responseText) {
  const match = responseText.match(/<update id="javax\.faces\.ViewState"[^>]*><!\[CDATA\[([^\]]+)\]\]><\/update>/);
  return match ? match[1] : null;
}

// Method 2: Extract from HTML response (full page loads)
function extractViewStateFromHTML(html) {
  const match = html.match(/<input[^>]*name="javax\.faces\.ViewState"[^>]*value="([^"]+)"/);
  return match ? match[1] : null;
}

// React hook for ViewState management
const useViewState = () => {
  const [viewState, setViewState] = useState(null);
  
  const updateViewState = (response) => {
    if (response.headers.get('content-type')?.includes('xml')) {
      const newViewState = extractViewStateFromXML(response);
      if (newViewState) setViewState(newViewState);
    }
  };
  
  return { viewState, setViewState, updateViewState };
};
```

### Session Management Pattern

```javascript
// React must handle JSF session requirements
const useJSFSession = () => {
  const [sessionValid, setSessionValid] = useState(false);
  
  const checkSession = async () => {
    try {
      const response = await fetch('/ccwfm/', { credentials: 'include' });
      const isValid = !response.url.includes('/login');
      setSessionValid(isValid);
      return isValid;
    } catch {
      setSessionValid(false);
      return false;
    }
  };
  
  const handleSessionTimeout = () => {
    // JSF session expired - need to re-authenticate
    window.location.href = '/ccwfm/login';
  };
  
  return { sessionValid, checkSession, handleSessionTimeout };
};
```

## 🚨 Error Patterns React Must Handle

### 1. ViewState Errors

```javascript
// Common ViewState errors in JSF responses
const handleJSFErrors = (responseText) => {
  if (responseText.includes('ViewState couldn\'t be restored')) {
    // ViewState expired - need fresh page load
    return 'VIEWSTATE_EXPIRED';
  }
  
  if (responseText.includes('MAC did not verify')) {
    // ViewState tampered - security error
    return 'VIEWSTATE_INVALID';
  }
  
  if (responseText.includes('Время жизни страницы истекло')) {
    // Session timeout
    return 'SESSION_TIMEOUT';
  }
  
  return 'SUCCESS';
};

// React error boundary for JSF errors
const JSFErrorHandler = ({ children }) => {
  const handleError = (error) => {
    if (error.message.includes('ViewState')) {
      // Refresh ViewState and retry
      window.location.reload();
    }
  };
  
  return (
    <ErrorBoundary onError={handleError}>
      {children}
    </ErrorBoundary>
  );
};
```

### 2. Business Logic Errors

```javascript
// JSF returns errors as HTML content, not HTTP status codes
const parseJSFResponse = (responseText) => {
  const errorCount = (responseText.match(/class="ui-messages-error"/g) || []).length;
  
  if (errorCount > 0) {
    // Extract error messages from HTML
    const errorMessages = responseText.match(/<span class="ui-messages-error-summary">([^<]+)</span>/g);
    return {
      success: false,
      errors: errorMessages?.map(msg => msg.replace(/<[^>]+>/g, '')) || ['Unknown error']
    };
  }
  
  return { success: true, errors: [] };
};
```

## ⚡ Performance Implications for React

### Response Characteristics

```javascript
// JSF responses are large - optimize parsing
const jsfPerformanceProfile = {
  responseSize: '200-300KB typical',
  processingTime: '2-8 seconds per operation', 
  contentType: 'text/xml or text/html',
  parsingStrategy: 'Extract only essential data'
};

// Optimized response handler
const handleJSFResponse = async (response) => {
  const text = await response.text();
  
  // Extract only what React needs
  return {
    viewState: extractViewStateFromXML(text),
    success: !text.includes('ui-messages-error'),
    data: extractBusinessData(text) // Extract only relevant business data
  };
};
```

### Batch Operations Strategy

```javascript
// No bulk APIs - React must batch individual operations
const useBatchOperations = () => {
  const processBatch = async (operations, delay = 100) => {
    const results = [];
    
    for (const operation of operations) {
      try {
        const result = await operation();
        results.push({ success: true, data: result });
        
        // Delay between operations to avoid overwhelming JSF server
        await new Promise(resolve => setTimeout(resolve, delay));
        
      } catch (error) {
        results.push({ success: false, error: error.message });
      }
    }
    
    return results;
  };
  
  return { processBatch };
};
```

## 🎯 Key Takeaways for React Teams

### 1. Architectural Differences

| REST API | JSF API |
|----------|---------|
| Stateless | Stateful (ViewState required) |
| JSON requests/responses | Form-encoded requests, HTML/XML responses |
| HTTP status codes for errors | Error messages in response content |
| Simple retry logic | Complex state recovery needed |

### 2. Implementation Strategy

```javascript
// Wrapper for JSF API calls in React
class JSFApiClient {
  constructor() {
    this.viewState = null;
    this.sessionCookies = null;
  }
  
  async callJSFEndpoint(url, componentId, parameters = {}) {
    const formData = new URLSearchParams({
      'javax.faces.partial.ajax': 'true',
      'javax.faces.source': componentId,
      'javax.faces.partial.execute': componentId,
      'javax.faces.ViewState': this.viewState,
      ...parameters
    });
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'include',
      body: formData.toString()
    });
    
    // Always update ViewState from response
    this.updateViewStateFromResponse(response);
    
    return response;
  }
}
```

### 3. Testing Considerations

- Cannot mock JSF APIs easily - need actual server responses
- ViewState tokens must be extracted from real responses
- Session management requires browser-like behavior
- Error scenarios need full JSF error response simulation

## 🏗️ Dual Portal Architecture - Database-Only Integration

### Portal Separation Reality
```javascript
// CRITICAL: No cross-portal APIs exist
const portalArchitecture = {
  adminPortal: {
    url: 'https://cc1010wfmcc.argustelecom.ru/ccwfm/',
    technology: 'JSF/PrimeFaces',
    authentication: 'JSESSIONID + ViewState',
    databaseAccess: 'Direct via JSF lifecycle',
    scope: 'User management, roles, reports, system config'
  },
  employeePortal: {
    url: 'https://lkcc1010wfmcc.argustelecom.ru/',
    technology: 'Vue.js SPA',
    authentication: 'JWT tokens',
    databaseAccess: 'REST APIs',
    scope: 'Self-service, requests, personal schedules'
  },
  integration: {
    crossPortalAPIs: false, // NO APIS between portals
    syncMechanism: 'Database triggers/procedures only',
    dataFlow: 'Admin JSF → Database → Employee REST APIs'
  }
};
```

### Session Pattern Clarification
```javascript
// Different session patterns per portal
const sessionPatterns = {
  adminPortal: {
    type: 'JSF ViewState sessions',
    timeout: 'ViewState expiration (server-controlled)',
    persistence: 'Server-side component tree',
    scope: 'Admin portal only'
  },
  employeePortal: {
    type: 'JWT token sessions', 
    timeout: '1 hour token expiry',
    persistence: 'Stateless token validation',
    scope: 'Employee portal only'
  },
  crossover: 'NO SESSION SHARING between portals'
};
```

### React Implementation Implications
- **Admin features**: Must use JSF patterns (this document)
- **Employee features**: Use standard REST/JWT patterns
- **No unified auth**: Separate login for each portal
- **Data sync**: Via database only, not direct API calls

---

**Implementation Guide for React Teams**  
*Understanding JSF patterns to build modern frontend*  
*ViewState management is the key to successful API integration*