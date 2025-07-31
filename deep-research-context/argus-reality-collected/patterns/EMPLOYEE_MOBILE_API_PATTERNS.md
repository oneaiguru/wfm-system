# Employee Mobile API Patterns - Framework-Agnostic Implementation Guide

**Date**: 2025-07-29  
**Authors**: R2-EmployeeSelfService (API Discovery) + R8-UXMobileEnhancements (Mobile Optimization)  
**Purpose**: Document mobile API patterns extracted from Argus employee portal for React implementation  

## 🎯 Overview

This guide extracts framework-agnostic API patterns from the Argus Vue.js employee portal to inform our React implementation. The focus is on **API behavior**, **business logic**, and **mobile optimization strategies** that apply regardless of frontend framework.

## 🚨 CRITICAL: PORTAL BOUNDARIES & SYSTEM SEPARATION

### **DUAL PORTAL ARCHITECTURE - NOT UNIFIED SYSTEM**
```javascript
{
  "vue_employee_portal": {
    "scope": "Employee self-service ONLY",
    "url": "https://lkcc1010wfmcc.argustelecom.ru/*",
    "technology": "Vue.js + Vuetify SPA", 
    "api_pattern": "/gw/api/v1/* (REST + JWT)",
    "users": "Employees only",
    "integration": "Database-only sync with admin portal"
  },
  
  "jsf_admin_portal": {
    "scope": "Administrative functions ONLY",
    "url": "https://cc1010wfmcc.argustelecom.ru/ccwfm/*",
    "technology": "JSF/PrimeFaces with ViewState",
    "api_pattern": "*.xhtml endpoints (Stateful)",
    "users": "Managers, admins, HR staff",
    "integration": "Database-only sync with employee portal"
  },
  
  "integration_reality": {
    "cross_portal_apis": "NONE - Completely separate systems",
    "shared_sessions": "NONE - Independent authentication",
    "sync_method": "DATABASE ONLY - No direct portal communication"
  }
}
```

### **R2 DOCUMENTATION SCOPE LIMITS**
This documentation covers **Vue.js Employee Portal ONLY**:
- ✅ Employee self-service APIs (28 endpoints)
- ✅ Vue.js patterns for React migration
- ✅ Mobile optimization strategies
- ✅ JWT authentication (employee portal only)
- ❌ Does NOT cover admin portal, manager functions, or cross-portal integration

## 📊 1. Current Argus Vue.js Patterns (For API Understanding)

### Architecture Discovery
```javascript
// Current Argus Employee Portal Stack:
{
  "frontend": "Vue.js + Vuetify",
  "api_pattern": "REST with JWT authentication", 
  "gateway": "/gw/api/v1/* endpoints",
  "auth_method": "Bearer tokens in localStorage",
  "session_management": "Client-side JWT storage"
}
```

### Why This Matters for React Implementation:
- **Same APIs**: Our React app will call identical endpoints
- **Same Business Logic**: Validation rules and workflows unchanged
- **Same Performance Characteristics**: Response times and bottlenecks identical
- **Same Bug Patterns**: Form validation issues may persist in React

## 📊 2. Mobile API Behaviors (Framework-Agnostic)

### Authentication API Patterns
```javascript
// Login Flow (Works with React/Vue/Any framework)
POST /gw/api/v1/auth/login
Request: {
  "username": "employee_id",
  "password": "password"
}
Response: {
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9...",
  "user": {
    "id": 111538,
    "role": "employee",
    "permissions": ["view_calendar", "create_requests"]
  },
  "expires_in": 3600
}

// Mobile Considerations:
- Store JWT in secure storage (not localStorage on mobile)
- Implement background token refresh
- Handle app backgrounding/foregrounding
```

### Session Management Patterns (Employee Portal Only)
```javascript
// Token Validation (Every 5 minutes in Argus Employee Portal)
GET /gw/api/v1/auth/validate
Headers: { "Authorization": "Bearer <token>" }
Response: {
  "valid": true,
  "expires_in": 2847,
  "refresh_needed": false
}

// Employee Portal Session Characteristics:
{
  "jwt_duration": "1 hour (3600 seconds)", 
  "validation_frequency": "Every 5 minutes",
  "timeout_behavior": "Redirect to login, clear localStorage",
  "differs_from_admin": "Admin portal uses 10-15 min ViewState timeout",
  "reason_for_difference": "Employees need longer sessions for convenience"
}

// Mobile Optimization:
- Extend validation intervals on mobile (battery savings)
- Cache validation responses for 60 seconds
- Skip validation when app is backgrounded
```

### Data Fetching Patterns
```javascript
// Notification Polling (Current: Every 30 seconds)
GET /gw/api/v1/notifications/count
Response: { "count": 106, "unread": 106 }

// Mobile Enhancement Strategy:
- Use WebSocket for real-time updates instead of polling
- Implement push notifications for mobile apps
- Batch multiple API calls into single requests
```

## 📊 3. Business Logic Rules (For Any Implementation)

### Form Validation Rules
```javascript
// Request Creation Validation (From Argus Analysis)
{
  "request_type": {
    "required": true,
    "options": ["vacation", "sick_leave", "time_off"]
  },
  "reason": {
    "required": true,
    "min_length": 5,
    "max_length": 500,
    "validation_bug": "Field clears on interaction with other fields"
  },
  "start_date": {
    "required": true,
    "format": "YYYY-MM-DD",
    "min_date": "today",
    "max_date": "today + 365 days"
  },
  "end_date": {
    "required": true,
    "validation": "must be >= start_date"
  }
}

// React Implementation Notes:
- Use controlled components to prevent field clearing
- Implement proper form state management
- Add client-side validation before API calls
```

### Workflow State Rules
```javascript
// Request Status Progression
{
  "states": [
    "draft",           // Employee editing
    "submitted",       // Sent to manager
    "pending_approval", // Manager reviewing
    "approved",        // Accepted
    "rejected",        // Declined
    "withdrawn"        // Employee cancelled
  ],
  "transitions": {
    "draft → submitted": "Employee action",
    "submitted → pending_approval": "Automatic",
    "pending_approval → approved|rejected": "Manager action",
    "any → withdrawn": "Employee action (if not approved)"
  }
}
```

### Permission Rules
```javascript
// Employee Portal Permissions (API-level)
{
  "can_view": [
    "own_schedule",
    "own_requests", 
    "notifications",
    "acknowledgments"
  ],
  "can_create": [
    "vacation_requests",  // BLOCKED by Vue.js bug
    "time_off_requests",  // BLOCKED by Vue.js bug
    "acknowledgments"
  ],
  "cannot_access": [
    "other_employee_data",
    "admin_functions",
    "reporting_features"
  ]
}
```

## 📊 4. Performance Optimizations (API-Level)

### Response Time Analysis
```javascript
// Measured Performance (From R2's 28 API Testing)
{
  "fastest": {
    "endpoint": "/gw/api/v1/notifications/count",
    "avg_time": "120ms",
    "cache": "no-cache"
  },
  "slowest": {
    "endpoint": "/gw/api/v1/calendar/month/2025-07",
    "avg_time": "850ms", 
    "cache": "max-age=300"
  },
  "average_response": "340ms"
}
```

### Mobile Optimization Strategies
```javascript
// API-Level Mobile Enhancements
{
  "pagination": {
    "current": "page=1&size=20",
    "mobile_optimized": "page=1&size=10", // Smaller pages
    "infinite_scroll": "cursor-based pagination preferred"
  },
  "payload_reduction": {
    "notifications": {
      "desktop": "full_content + metadata",
      "mobile": "title + timestamp only",
      "details": "fetch on demand"
    }
  },
  "batch_requests": {
    "current": "3 separate API calls for dashboard",
    "optimized": "POST /gw/api/v1/mobile/batch",
    "benefit": "reduced network requests, faster loading"
  }
}
```

### Caching Strategies
```javascript
// Current Caching Patterns (Framework-Agnostic)
{
  "short_cache": {
    "endpoints": ["calendar/month", "schedule/personal"],
    "duration": "5 minutes",
    "strategy": "Cache-Control: max-age=300"
  },
  "medium_cache": {
    "endpoints": ["user/preferences", "theme/settings"],
    "duration": "1 hour", 
    "strategy": "Cache-Control: max-age=3600"
  },
  "no_cache": {
    "endpoints": ["notifications", "acknowledgments"],
    "reason": "Real-time data required"
  }
}

// Mobile Enhancement:
- Implement aggressive caching for offline support
- Use ETag headers for conditional requests
- Cache static data (user profile, permissions) locally
```

## 📊 5. Bug Documentation (Root Causes, Not Framework Fixes)

### Critical Bug: Request Form Validation
```javascript
// Root Cause Analysis (Framework-Agnostic Issue)
{
  "bug_description": "Required field 'reason' clears when user interacts with other form fields",
  "impact": "Employee cannot submit vacation/time-off requests",
  "root_cause": "State management conflict in form handling",
  "api_impact": "NO API calls made - pure frontend validation failure",
  
  // For React Implementation:
  "prevention_strategy": {
    "use_controlled_components": true,
    "avoid_field_interdependencies": true,
    "implement_form_state_isolation": true,
    "add_field_value_persistence": true
  }
}
```

### Performance Issues
```javascript
// Performance Bottlenecks (API-Level)
{
  "polling_overhead": {
    "current": "Notification count checked every 30 seconds",
    "mobile_impact": "Battery drain, unnecessary API calls",
    "solution": "WebSocket or push notifications"
  },
  "large_payloads": {
    "calendar_month": "850ms response time",
    "cause": "Full month data including metadata",
    "mobile_solution": "Week view with lazy loading"
  }
}
```

## 📊 6. Mobile-Specific API Behaviors

### Responsive Data Patterns
```javascript
// Desktop vs Mobile API Usage
{
  "calendar": {
    "desktop": "GET /gw/api/v1/calendar/month/2025-07",
    "mobile": "GET /gw/api/v1/calendar/week/2025-07-29", // Smaller dataset
    "tablet": "GET /gw/api/v1/calendar/month/2025-07?compact=true"
  },
  "notifications": {
    "desktop": "GET /gw/api/v1/notifications?page=1&size=20",
    "mobile": "GET /gw/api/v1/notifications?page=1&size=10", // Fewer items
    "mobile_summary": "GET /gw/api/v1/notifications/badge-count" // Just count
  }
}
```

### Offline Capability Patterns
```javascript
// Offline-First API Strategy
{
  "essential_data": [
    "user_profile",
    "current_schedule", 
    "pending_requests"
  ],
  "cache_locally": "Store in IndexedDB/SQLite",
  "sync_strategy": {
    "on_reconnect": "POST /gw/api/v1/mobile/sync",
    "conflict_resolution": "Server wins for approved data",
    "queue_actions": "Store offline actions, replay when online"
  }
}
```

## 📊 7. React Implementation Recommendations

### State Management
```javascript
// Based on Vue.js Analysis
{
  "avoid": [
    "Complex form interdependencies (causes bugs)",
    "Frequent API polling (performance impact)",
    "Synchronous validation (blocks UI)"
  ],
  "implement": [
    "Redux/Zustand for global state",
    "React Query for API caching",
    "Controlled components for forms",
    "Optimistic updates for better UX"
  ]
}
```

### Mobile-First Approach
```javascript
// Mobile API Integration
{
  "authentication": "Secure token storage (Keychain/Keystore)",
  "networking": "Retry logic for poor connections",
  "caching": "Aggressive caching with offline support",
  "performance": "Bundle splitting, lazy loading"
}
```

## 🎯 Key Takeaways for Implementation

### Critical Success Factors:
1. **Fix Form Bug**: Implement proper controlled components to prevent field clearing
2. **Optimize for Mobile**: Smaller payloads, better caching, offline support
3. **Improve Performance**: Replace polling with WebSocket, implement batching
4. **Maintain Security**: Proper JWT handling, secure storage on mobile

### API Patterns That Work:
- JWT authentication with refresh tokens
- RESTful endpoints with consistent error handling
- Pagination for large datasets
- Caching headers for performance

### Patterns to Avoid:
- Field interdependencies in forms
- Excessive API polling
- Large payload responses on mobile
- Client-side state management conflicts

## 📊 8. Deep Vue.js Pattern Analysis (Extended Documentation)

### Vue.js Component Lifecycle → API Call Sequences
```javascript
// How Vue.js lifecycle hooks drive API behavior
{
  "component_mount_sequence": {
    "created()": [
      "Check authentication token validity",
      "GET /gw/api/v1/auth/validate"
    ],
    "mounted()": [
      "Load initial data",
      "GET /gw/api/v1/notifications/count",
      "GET /gw/api/v1/acknowledgments/pending"
    ],
    "beforeRouteEnter()": [
      "Route-specific data loading",
      "GET /gw/api/v1/calendar/month/{current}"
    ]
  },
  
  "react_equivalent": {
    "useEffect([], [])": "Component mount - initial API calls",
    "useEffect([route], [route])": "Route change - load route data", 
    "useEffect([auth], [auth])": "Auth change - validate session"
  }
}
```

### Vue.js Reactive Data → API Trigger Patterns
```javascript
// How Vue.js watchers and computed properties affect APIs
{
  "form_field_watchers": {
    "vue_pattern": "watch: { requestType() { this.loadTypeOptions() } }",
    "api_effect": "GET /gw/api/v1/requests/types/{type}/options",
    "react_pattern": "useEffect(() => { loadOptions() }, [requestType])"
  },
  
  "computed_api_dependencies": {
    "vue_pattern": "computed: { filteredNotifications() {...} }",
    "api_trigger": "Filters change → new API call with parameters",
    "react_pattern": "useMemo(() => filterData(data, filters), [data, filters])"
  },
  
  "critical_bug_pattern": {
    "vue_issue": "watch conflicts cause field clearing",
    "api_impact": "Form submission blocked, NO API call made",
    "react_solution": "Use controlled components, avoid watch conflicts"
  }
}
```

### Vuetify Breakpoint System → API Optimization
```javascript
// How Vue.js responsive breakpoints change API behavior
{
  "breakpoint_api_patterns": {
    "mobile": {
      "breakpoint": "$vuetify.breakpoint.mobile (< 960px)",
      "api_changes": [
        "GET /gw/api/v1/calendar/week vs month",
        "GET /gw/api/v1/notifications?size=10 vs 20",
        "Reduced payload requests for bandwidth"
      ]
    },
    "tablet": {
      "breakpoint": "$vuetify.breakpoint.smAndDown (< 960px)",
      "api_behavior": "Hybrid mobile/desktop API patterns"
    },
    "desktop": {
      "breakpoint": "$vuetify.breakpoint.mdAndUp (>= 960px)", 
      "api_behavior": "Full dataset requests, larger payloads"
    }
  },
  
  "react_implementation": {
    "use_media_queries": "const isMobile = useMediaQuery('(max-width: 960px)')",
    "conditional_api_calls": "isMobile ? getWeekData() : getMonthData()",
    "payload_optimization": "Adjust API parameters based on screen size"
  }
}
```

### Vue.js State Management → Session Handling
```javascript
// How Vue.js manages state affects API session patterns
{
  "vuex_state_patterns": {
    "authentication": {
      "storage": "localStorage for JWT tokens",
      "refresh_logic": "Vuex action dispatches API refresh",
      "session_timeout": "Vue.js timer triggers logout API"
    },
    "notification_polling": {
      "vue_pattern": "setInterval in Vuex action",
      "api_call": "Every 30 seconds → GET /gw/api/v1/notifications/count",
      "cleanup": "clearInterval in component destroyed()"
    }
  },
  
  "react_migration": {
    "redux_toolkit": "Use RTK Query for API state management",
    "react_query": "Built-in caching and background refresh",
    "context_api": "For simple state without external library"
  }
}
```

### Vue.js Error Handling → API Failure Patterns
```javascript
// How Vue.js handles API errors reveals failure modes
{
  "axios_interceptors": {
    "vue_implementation": "Global error handling in axios setup",
    "error_patterns": [
      "401 → Clear localStorage, redirect to login",
      "403 → Show permission denied message",
      "500 → Show generic error, retry button"
    ],
    "api_timeout": "10 seconds default timeout"
  },
  
  "component_error_handling": {
    "try_catch_patterns": "Around async API calls in methods",
    "loading_states": "this.loading = true/false around API calls",
    "error_display": "v-alert components for error messages"
  },
  
  "react_patterns": {
    "error_boundaries": "Catch API-related component errors",
    "suspense": "Handle loading states declaratively",
    "error_state": "Use error state in custom hooks"
  }
}
```

## 📊 9. Vue.js Performance Patterns → React Optimization

### Vue.js Optimization Techniques Found
```javascript
// Performance patterns discovered in Argus Vue.js implementation
{
  "component_lazy_loading": {
    "vue_pattern": "() => import('./ComponentName.vue')",
    "api_effect": "Delays API calls until component needed",
    "bundle_splitting": "Reduces initial JavaScript payload"
  },
  
  "computed_property_caching": {
    "vue_benefit": "Expensive calculations cached automatically",
    "api_impact": "Reduces redundant API data processing",
    "react_equivalent": "useMemo() and useCallback() hooks"
  },
  
  "v_once_directive": {
    "vue_usage": "v-once for static content",
    "performance": "Prevents unnecessary re-renders",
    "react_pattern": "React.memo() for component memoization"
  }
}
```

### API Caching Strategies in Vue.js
```javascript
// How Vue.js implementation handles API response caching
{
  "component_level_caching": {
    "pattern": "Store API response in component data",
    "duration": "Until component unmount",
    "use_case": "Calendar month data, user preferences"
  },
  
  "vuex_caching": {
    "pattern": "Store API responses in Vuex state",
    "persistence": "Survives component destruction",
    "invalidation": "Manual cache clearing on data changes"
  },
  
  "browser_caching": {
    "headers": "Cache-Control: max-age=300 for calendar data",
    "etag_usage": "Conditional requests for unchanged data",
    "local_storage": "Long-term caching for user settings"
  }
}
```

## 📊 10. Critical Vue.js Business Logic Extraction

### Form Validation Rules (Embedded in Vue Components)
```javascript
// Business logic extracted from Vue.js form components
{
  "request_form_validation": {
    "reason_field": {
      "vue_rules": "[rules.required, rules.minLength(5)]",
      "business_rule": "All requests must have minimum 5-character reason",
      "bug_behavior": "Field clears due to Vue.js watcher conflict"
    },
    "date_validation": {
      "vue_logic": "computed: { isValidDateRange() { ... } }",
      "business_rule": "End date must be >= start date, max 30 days",
      "api_validation": "Server also validates date ranges"
    },
    "request_type_dependencies": {
      "vue_watcher": "watch: { requestType() { this.updateAvailableOptions() } }",
      "business_rule": "Different request types have different approval workflows",
      "api_calls": "Dynamic options loading based on type selection"
    }
  }
}
```

### Permission Logic (Vue.js Route Guards)
```javascript
// Permission checks embedded in Vue.js routing
{
  "route_protection": {
    "vue_pattern": "beforeRouteEnter(to, from, next) { checkPermission() }",
    "permission_api": "GET /gw/api/v1/auth/permissions",
    "business_rule": "Employees can only access own data and basic functions"
  },
  
  "component_permissions": {
    "vue_computed": "computed: { canCreateRequest() { return this.userRole === 'employee' } }",
    "ui_impact": "Buttons/forms hidden based on permissions",
    "api_impact": "Prevents unauthorized API calls"
  }
}
```

### Workflow State Management
```javascript
// Business workflow logic embedded in Vue.js components
{
  "request_status_flow": {
    "vue_computed": "computed: { availableActions() { ... } }",
    "business_logic": [
      "Draft requests can be edited or submitted",
      "Submitted requests can only be withdrawn",
      "Approved requests cannot be modified"
    ],
    "api_implications": "Different API endpoints available per status"
  },
  
  "notification_workflows": {
    "vue_methods": "markAsRead(), acknowledgeDocument()",
    "business_rule": "Acknowledgments are mandatory for compliance",
    "api_sequence": "Read → Acknowledge → Update compliance status"
  }
}
```

---

**Extended Summary**: This comprehensive analysis of Argus Vue.js patterns provides deep understanding of how the current system works, enabling perfect React reimplementation. The documentation covers component lifecycle, state management, performance optimization, business logic extraction, and critical bug patterns - all essential for building a superior React-based employee portal that preserves working functionality while avoiding known pitfalls.