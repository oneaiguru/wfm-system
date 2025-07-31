# R2 Employee Portal API Capture Execution Plan

**Date**: 2025-07-29  
**Agent**: R2-EmployeeSelfService  
**Status**: Ready to execute when MCP available  

## 🎯 Comprehensive API Capture Areas

### 1. Notification System APIs (106+ items available)

#### Test Sequence:
```bash
# Initial load
mcp__playwright-human-behavior__navigate → /notifications
# Capture: GET /gw/api/v1/notifications/list

# Pagination
mcp__playwright-human-behavior__click → [Next page button]
# Expect: GET /gw/api/v1/notifications/list?page=2

# Filtering
mcp__playwright-human-behavior__type → [Search: "отпуск"]
# Expect: GET /gw/api/v1/notifications/list?search=отпуск

# Mark as read
mcp__playwright-human-behavior__click → [Unread notification]
# Expect: PUT /gw/api/v1/notifications/{id}/read

# Bulk operations
mcp__playwright-human-behavior__click → [Select all checkbox]
mcp__playwright-human-behavior__click → [Mark all read]
# Expect: POST /gw/api/v1/notifications/bulk-read
```

### 2. Acknowledgment System APIs (50+ active items)

#### Test Sequence:
```bash
# Navigate to acknowledgments
mcp__playwright-human-behavior__navigate → /introduce

# Load pending items
# Capture: GET /gw/api/v1/acknowledgments/pending

# Process acknowledgment
mcp__playwright-human-behavior__click → "Ознакомлен(а)" button
# Expect: POST /gw/api/v1/acknowledgments/{id}/confirm
# Response: {"status": "acknowledged", "timestamp": "2025-07-29T10:00:00Z"}

# View history
mcp__playwright-human-behavior__click → [History tab]
# Expect: GET /gw/api/v1/acknowledgments/history?page=1&size=20
```

### 3. Calendar/Schedule APIs

#### Test Sequence:
```bash
# Calendar month view
mcp__playwright-human-behavior__navigate → /calendar
# Capture: GET /gw/api/v1/calendar/month?date=2025-07

# Navigate months
mcp__playwright-human-behavior__click → [Next month arrow]
# Expect: GET /gw/api/v1/calendar/month?date=2025-08

# View specific date
mcp__playwright-human-behavior__click → [Date: July 30]
# Expect: GET /gw/api/v1/schedule/day?date=2025-07-30

# Personal schedule
mcp__playwright-human-behavior__click → [My Schedule button]
# Expect: GET /gw/api/v1/schedule/personal?start=2025-07-01&end=2025-07-31
```

### 4. JWT Token Lifecycle

#### Monitoring Points:
```javascript
// Initial login
POST /gw/api/v1/auth/login
Response: {
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9...",
  "expiresIn": 3600,
  "refreshToken": "..."
}

// Token refresh (monitor after 30 mins)
POST /gw/api/v1/auth/refresh
Header: Authorization: Bearer [current_token]
Body: {"refreshToken": "..."}

// Token validation
GET /gw/api/v1/auth/validate
Header: Authorization: Bearer [current_token]

// Logout
POST /gw/api/v1/auth/logout
Header: Authorization: Bearer [current_token]
```

### 5. User Preferences APIs

#### Test Sequence:
```bash
# Theme switching
mcp__playwright-human-behavior__execute_javascript → 
  document.querySelector('[data-theme-toggle]').click()
# Expect: PUT /gw/api/v1/user/preferences
# Body: {"theme": "dark"}

# Language change (if available)
# Expect: PUT /gw/api/v1/user/preferences
# Body: {"language": "en"}

# Notification settings
# Expect: GET /gw/api/v1/user/notification-settings
# Expect: PUT /gw/api/v1/user/notification-settings
```

### 6. Session Management APIs

#### Multi-tab Testing:
```javascript
// Tab 1: Normal usage
// Tab 2: Open same URL
// Monitor: WebSocket connections or polling sync

// Expected patterns:
GET /gw/api/v1/session/sync
WebSocket: wss://lkcc1010wfmcc.argustelecom.ru/ws/notifications
```

### 7. Error Handling Patterns

#### Test Cases:
```bash
# Expired token
# Expect: 401 response → Auto refresh → Retry

# Network timeout
# Expect: Retry with exponential backoff

# Invalid data
# Expect: 400 with validation errors
```

## 📊 Expected API Documentation Structure

### For Each Endpoint:
```yaml
endpoint: GET /gw/api/v1/notifications/list
auth: Bearer JWT
params:
  - page: number (default: 1)
  - size: number (default: 20)
  - search: string (optional)
  - status: enum [read, unread, all]
response:
  success:
    status: 200
    body:
      items: []
      total: number
      page: number
  errors:
    401: "Token expired"
    403: "Insufficient permissions"
```

## 🔍 Advanced Discovery Areas

### 1. Real-time Features
- Check for WebSocket upgrade headers
- Monitor Server-Sent Events endpoints
- Test notification push mechanisms

### 2. Caching Strategies
- ETags usage
- Cache-Control headers
- Local storage patterns

### 3. Rate Limiting
- Monitor X-RateLimit headers
- Test burst scenarios
- Document throttling behavior

### 4. API Versioning
- Check for version in URL (/v1/)
- Look for version headers
- Test backward compatibility

## 📋 Deliverable Format

Each API category will be documented in:
`/agents/KNOWLEDGE/API_PATTERNS/EMPLOYEE_[CATEGORY]_APIS.md`

With structure:
1. Overview and architecture
2. Authentication requirements
3. Endpoint specifications
4. Request/response examples
5. Error handling patterns
6. Integration considerations

## 🚀 Execution Timeline

**Hour 1**: Notifications (highest data volume)
**Hour 2**: Acknowledgments (live status changes)
**Hour 3**: Calendar/Schedule (complex queries)
**Hour 4**: JWT & Session Management
**Hour 5**: Preferences & Error Patterns

---

**Ready to execute**: This plan will capture 30+ unique employee portal API endpoints, providing complete documentation of the Vue.js REST architecture that complements R6's JSF discoveries.