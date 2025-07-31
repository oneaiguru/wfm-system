# R2 Employee Portal API Capture - Detailed Execution Plan

**Agent**: R2-EmployeeSelfService  
**Duration**: 5 hours (300 minutes)  
**Method**: Universal API Monitor + MCP Browser Automation  
**Target**: 30+ Employee Portal REST APIs  

## 🎯 Objectives
1. Document complete JWT authentication lifecycle
2. Capture all working employee portal endpoints
3. Map Vue.js performance patterns
4. Document API request/response structures
5. Identify integration points with admin portal

## 📋 Phase-by-Phase Execution Plan

### Phase 1: JWT Authentication Lifecycle (30 min)
**Goal**: Understand complete auth flow from login to token refresh

#### 1.1 Initial Login Capture
```bash
# Navigate to portal
mcp__playwright-human-behavior__navigate → https://lkcc1010wfmcc.argustelecom.ru/

# Inject monitor BEFORE login
mcp__playwright-human-behavior__execute_javascript → [UNIVERSAL_API_MONITOR]

# Perform login
mcp__playwright-human-behavior__type → test/test

# Capture login API
Expected: POST /gw/api/v1/auth/login
Response: JWT token, user details, permissions
```

#### 1.2 Token Storage Analysis
```javascript
// Check localStorage
localStorage.getItem('auth_token')
localStorage.getItem('user_data')
sessionStorage analysis
```

#### 1.3 Token Refresh Monitoring
```bash
# Wait for token refresh (if exists)
# Monitor for 401 → refresh → retry pattern
# Document refresh endpoint
Expected: POST /gw/api/v1/auth/refresh
```

### Phase 2: Notification System APIs (45 min)
**Goal**: Complete notification lifecycle documentation

#### 2.1 Notification List & Filtering
```bash
# Navigate to notifications
mcp__playwright-human-behavior__click → "Оповещения"

# Capture list API
GET /gw/api/v1/notifications?page=1&size=20
GET /gw/api/v1/notifications/count

# Test filtering
mcp__playwright-human-behavior__type → [filter text]
Capture: GET /gw/api/v1/notifications?filter=X
```

#### 2.2 Notification Actions
```bash
# Mark as read
mcp__playwright-human-behavior__click → [notification item]
Expected: PUT /gw/api/v1/notifications/{id}/read

# Bulk actions
Select multiple → Mark all read
Expected: POST /gw/api/v1/notifications/bulk-read
```

#### 2.3 Real-time Updates
```bash
# Monitor polling pattern
Document: Polling interval (30s observed)
Check for: WebSocket upgrade attempts
Long polling patterns
```

### Phase 3: Acknowledgment Processing APIs (30 min)
**Goal**: Document compliance workflow APIs

#### 3.1 Acknowledgment List
```bash
mcp__playwright-human-behavior__navigate → /introduce

# Capture list API
GET /gw/api/v1/acknowledgments/pending
GET /gw/api/v1/acknowledgments/history
```

#### 3.2 Acknowledgment Actions
```bash
# Click acknowledge button
mcp__playwright-human-behavior__click → "Ознакомлен(а)"

# Capture status change API
Expected: POST /gw/api/v1/acknowledgments/{id}/acknowledge
Payload: {timestamp, user_id, signature?}
```

### Phase 4: Calendar/Schedule APIs (45 min)
**Goal**: Map schedule viewing and navigation

#### 4.1 Calendar Data Loading
```bash
mcp__playwright-human-behavior__navigate → /calendar

# Month view API
GET /gw/api/v1/calendar/month/2025-07
GET /gw/api/v1/schedule/personal/2025-07

# Navigate months
Click next/prev → capture date range APIs
```

#### 4.2 Schedule Details
```bash
# Click specific date
mcp__playwright-human-behavior__click → [date cell]

# Capture day details
GET /gw/api/v1/schedule/day/2025-07-30
GET /gw/api/v1/shifts/{date}
```

#### 4.3 Request Creation Attempt
```bash
# Even though form is buggy, capture what SHOULD happen
mcp__playwright-human-behavior__click → "Создать"

# Monitor for any API attempts
# Document expected endpoint structure
Expected: POST /gw/api/v1/requests/create
```

### Phase 5: Profile & Settings APIs (30 min)
**Goal**: User preferences and profile management

#### 5.1 Profile Access (Even if 404)
```bash
mcp__playwright-human-behavior__navigate → /profile

# Capture attempted API calls
Expected: GET /gw/api/v1/users/profile
GET /gw/api/v1/users/{id}/settings
```

#### 5.2 Theme & Preferences
```bash
# Toggle theme
mcp__playwright-human-behavior__click → [theme toggle]

# Capture preference API
Expected: PUT /gw/api/v1/users/preferences
Payload: {theme: 'dark', language: 'ru'}
```

### Phase 6: Exchange System APIs (30 min)
**Goal**: Shift exchange marketplace

#### 6.1 Exchange Lists
```bash
mcp__playwright-human-behavior__navigate → /exchange

# My exchanges tab
GET /gw/api/v1/exchanges/my

# Available exchanges tab
mcp__playwright-human-behavior__click → "Доступные"
GET /gw/api/v1/exchanges/available
```

#### 6.2 Exchange Actions
```bash
# If create button exists
Document exchange creation flow
Expected: POST /gw/api/v1/exchanges/create

# Exchange acceptance
Expected: POST /gw/api/v1/exchanges/{id}/accept
```

### Phase 7: Session Management APIs (30 min)
**Goal**: Login/logout and session lifecycle

#### 7.1 Logout Flow
```bash
# Attempt logout (even if 404)
mcp__playwright-human-behavior__navigate → /logout

# Capture logout API
Expected: POST /gw/api/v1/auth/logout
Clear localStorage/cookies
```

#### 7.2 Session Validation
```bash
# Open new tab → check session restore
# Document session check APIs
Expected: GET /gw/api/v1/auth/validate
GET /gw/api/v1/users/current
```

### Phase 8: Performance & Polling Patterns (20 min)
**Goal**: Document API performance characteristics

#### 8.1 API Response Times
```javascript
// Analyze from monitor data
{
  fastest_endpoint: "/notifications/count",
  slowest_endpoint: "/schedule/month",
  average_response_time: "XXXms",
  polling_intervals: {
    notifications: "30s",
    session_check: "5m"
  }
}
```

#### 8.2 Caching Patterns
```bash
# Check for cache headers
# Document ETags, Last-Modified
# Client-side caching strategies
```

### Phase 9: Error Handling & Recovery (20 min)
**Goal**: Document error responses and recovery

#### 9.1 Network Failure
```bash
# Disconnect network briefly
# Document offline handling
# Retry mechanisms
```

#### 9.2 API Error Responses
```javascript
// Collect all error formats
{
  401: "Unauthorized - token expired",
  403: "Forbidden - insufficient permissions",
  404: "Not found responses",
  422: "Validation errors",
  500: "Server errors"
}
```

### Phase 10: Documentation & Handoff (40 min)
**Goal**: Create comprehensive API documentation

#### 10.1 API Catalog Creation
- Endpoint documentation
- Request/response examples
- Authentication requirements
- Error scenarios

#### 10.2 Integration Guide
- How employee APIs integrate with admin
- Shared data models
- Permission boundaries
- Architecture recommendations

## 🔧 Technical Setup

### Monitor Configuration
```javascript
// Enhanced monitoring for Vue.js
window.monitorConfig = {
  captureHeaders: true,
  capturePayload: true,
  captureResponse: true,
  filterPattern: /^\/gw\/api/,
  excludePolling: false  // Keep polling to understand patterns
};
```

### Expected Discoveries
1. **30+ REST endpoints** documented
2. **JWT token lifecycle** fully mapped
3. **Vue.js state management** patterns identified
4. **Performance bottlenecks** discovered
5. **Integration points** with admin portal clarified

## 📊 Success Metrics
- All working features have APIs documented
- Request/response structures captured
- Authentication flow completely understood
- Error handling patterns documented
- Performance characteristics analyzed

## 🚀 Execution Notes
- Work systematically through each phase
- Don't skip "broken" features - document attempt
- Capture both successful and failed API calls
- Note any WebSocket upgrade attempts
- Document all polling intervals

---

**Total Time**: 5 hours (300 minutes)  
**Expected Output**: Complete employee portal API architecture documentation