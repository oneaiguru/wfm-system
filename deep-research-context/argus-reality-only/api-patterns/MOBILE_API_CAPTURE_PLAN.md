# Mobile API Capture Plan - R8 Domain

**Date**: 2025-07-29  
**Agent**: R8-UXMobileEnhancements  
**Status**: MCP browser tools not available - manual capture needed

## 🎯 Mobile-Specific API Patterns to Capture

### 1. Mobile Authentication Flow
```http
# Expected patterns:
POST /gw/api/v1/auth/login
Request: {
  "username": "test",
  "password": "test",
  "deviceInfo": {
    "platform": "mobile",
    "viewport": "375x667"
  }
}
Response: {
  "token": "JWT...",
  "refreshToken": "...",
  "userPreferences": {
    "theme": "Основная",
    "locale": "ru"
  }
}

# Token refresh
POST /gw/api/v1/auth/refresh
Headers: Authorization: Bearer [refreshToken]
```

### 2. Mobile-Optimized Data Loading
```http
# Calendar with mobile pagination
GET /gw/api/v1/calendar/mobile?view=week&date=2025-07-29
Response: {
  "events": [...], // Limited to viewport
  "hasMore": true,
  "nextPage": "/calendar/mobile?page=2"
}

# Notification badge count
GET /gw/api/v1/notifications/badge
Response: {
  "unread": 15,
  "lastUpdate": "2025-07-29T10:00:00Z"
}
```

### 3. Touch Gesture APIs
```http
# Swipe to change shift
POST /gw/api/v1/shift/quick-swap
Request: {
  "shiftId": "12345",
  "action": "swipeRight",
  "timestamp": "2025-07-29T10:00:00Z"
}

# Long press for quick actions
POST /gw/api/v1/request/quick-approve
Request: {
  "requestId": "67890",
  "gesture": "longPress",
  "duration": 800
}
```

### 4. PWA/Offline Queue
```http
# Sync offline changes
POST /gw/api/v1/sync/offline-queue
Request: {
  "actions": [
    {
      "type": "createRequest",
      "data": {...},
      "localId": "offline-123",
      "timestamp": "2025-07-29T09:00:00Z"
    }
  ]
}
Response: {
  "synced": ["offline-123"],
  "conflicts": [],
  "serverTime": "2025-07-29T10:00:00Z"
}

# Check for updates since last sync
GET /gw/api/v1/sync/updates?lastSync=2025-07-29T09:00:00Z
```

### 5. Mobile Performance APIs
```http
# Lazy load components
GET /gw/api/v1/components/calendar/data?lazy=true
GET /gw/api/v1/components/notifications/data?limit=20

# Prefetch critical data
GET /gw/api/v1/mobile/prefetch
Response: {
  "criticalData": {
    "upcomingShifts": [...],
    "pendingRequests": [...],
    "unreadNotifications": 15
  }
}
```

## 📝 Manual Testing Instructions

### Step 1: Open Developer Tools
1. Navigate to https://lkcc1010wfmcc.argustelecom.ru/
2. Open Chrome DevTools (F12)
3. Go to Network tab
4. Enable "Preserve log"
5. Filter by "XHR" or "Fetch"

### Step 2: Install Universal API Monitor
1. Go to Console tab
2. Paste the Universal API Monitor script
3. Add R8 mobile enhancements:

```javascript
// Add after Universal API Monitor
window.R8_MOBILE_METRICS = {
  mobileAPIs: [],
  touchEvents: [],
  viewportChanges: [],
  offlineQueue: []
};

// Monitor mobile-specific patterns
const originalFetch = window.fetch;
window.fetch = async function(url, options = {}) {
  // Check for mobile-specific endpoints
  if (url.includes('/mobile') || 
      url.includes('/sync') || 
      url.includes('/badge') ||
      options.headers?.['X-Mobile-Client']) {
    window.R8_MOBILE_METRICS.mobileAPIs.push({
      url: url.replace(window.location.origin, ''),
      method: options.method || 'GET',
      timestamp: Date.now(),
      viewport: window.innerWidth + 'x' + window.innerHeight
    });
  }
  return originalFetch.apply(this, arguments);
};
```

### Step 3: Test Mobile Scenarios
1. **Switch to mobile viewport**: 
   - DevTools → Toggle device toolbar
   - Select iPhone 12 or similar
   
2. **Test key flows**:
   - Login with test/test
   - Navigate calendar
   - Open notifications
   - Try request creation
   - Test offline (DevTools → Network → Offline)

### Step 4: Export Data
```javascript
// After testing, in console:
const mobileReport = {
  apiMonitor: window.getAPIReport(),
  mobileMetrics: window.R8_MOBILE_METRICS,
  timestamp: new Date().toISOString()
};
console.log(JSON.stringify(mobileReport, null, 2));
// Copy output to file
```

## 🎯 Expected Mobile API Discoveries

### Authentication
- Mobile-specific login parameters
- Device registration APIs
- Token refresh patterns

### Data Optimization
- Paginated endpoints for mobile
- Compressed responses
- Lazy loading patterns

### Offline Support
- Service worker registration
- Cache API patterns
- Sync queue endpoints

### Mobile UX
- Touch gesture APIs
- Quick action endpoints
- Badge/notification APIs

## 📊 Deliverables

Once captured, create:
1. `/agents/KNOWLEDGE/API_PATTERNS/MOBILE_AUTHENTICATION_APIS.md`
2. `/agents/KNOWLEDGE/API_PATTERNS/MOBILE_DATA_OPTIMIZATION.md`
3. `/agents/KNOWLEDGE/API_PATTERNS/PWA_OFFLINE_APIS.md`
4. `/agents/KNOWLEDGE/API_PATTERNS/MOBILE_UX_GESTURE_APIS.md`

## 🔗 Cross-Agent Dependencies

### From R2:
- Base employee portal endpoints
- Vue.js routing patterns
- Form validation APIs

### To provide:
- Mobile-specific optimizations
- Touch interaction patterns
- PWA implementation guide