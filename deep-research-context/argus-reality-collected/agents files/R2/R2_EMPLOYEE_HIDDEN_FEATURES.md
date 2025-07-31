# R2 Employee Domain Hidden Features Report

**Date**: 2025-07-30
**Agent**: R2-EmployeeSelfService
**Based on**: R0's HTML discoveries + R2's previous exploration

## 🎯 Employee-Specific Hidden Features

### 1. **External Employee IDs (b00039954 format)**
- **Where found**: Not directly observed in employee portal
- **Expected location**: Employee profile, request submissions
- **Why not in BDD**: External ID format suggests integration with external HR systems
- **Implementation impact**: Need to support multiple ID formats for integrations

### 2. **Placeholder Employees ("Новый сотрудник")**
- **Where found**: Likely in manager views when creating schedules
- **Description**: Temporary employee records before full onboarding
- **Why not in BDD**: Edge case for pre-boarding scenarios
- **Implementation impact**: Need placeholder employee support for scheduling

### 3. **Employee Search Filters (Discovered)**
- **Where found**: Not in employee portal, but critical for admin
- **Available filters based on API patterns**:
  - By department (ТП Группа Поляковой)
  - By position (Специалист)
  - By timezone (Екатеринбург)
  - By notification status
- **Why not in BDD**: Employee portal focuses on self-service, not searching others
- **Implementation impact**: Rich filtering needed for manager views

### 4. **Bulk Import Error States**
- **Where found**: Not accessible in employee portal
- **Expected scenarios**:
  - Duplicate external IDs
  - Invalid timezone mappings
  - Missing required fields
  - Department hierarchy conflicts
- **Why not in BDD**: Admin/HR functionality
- **Implementation impact**: Robust error handling for batch operations

## 🔍 Common Features Found in Employee Portal

### 1. **Global Search - NOT FOUND**
- **Expected**: "Искать везде..." functionality
- **Actual**: No search capability in employee portal
- **Impact**: Employees can't search their requests/schedules

### 2. **Notifications - FOUND**
- **Where**: Bell icon with count (106 notifications)
- **API**: GET /gw/api/v1/notifications/count
- **Features**:
  - Real-time work schedule alerts
  - Break reminders
  - No bulk actions available
- **Missing**: Notification preferences beyond on/off

### 3. **Task Queue - PARTIAL**
- **Found**: Acknowledgment queue in /introduce
- **Description**: Daily tasks requiring employee confirmation
- **Missing**: Background job tracking for requests
- **API behavior**: Synchronous processing only

### 4. **Session Management - CONFIRMED**
- **JWT Token expiry**: Long-lived (until 2025-08-01)
- **No 22-minute timeout observed**: Vue.js app maintains session
- **cid parameter**: Not found in employee portal
- **localStorage persistence**: Survives browser restart

### 5. **Error Recovery - LIMITED**
- **404 Page**: Custom "Упс.." page with "Вернуться назад"
- **Form errors**: "Поле должно быть заполнено"
- **Network errors**: No retry mechanisms
- **Missing**: "Try again" for failed API calls

## 🎯 Employee Domain Deep Discoveries

### Profile Management Gap
```yaml
discovered_api: GET /gw/api/v1/userInfo
missing_features:
  - Employee ID editing
  - External ID mapping
  - Emergency contacts
  - Skills/certifications
  - Language preferences
  - Notification channels
```

### Employee Preferences System
```yaml
found:
  - Theme switching (light/dark)
  - Timezone display
  - Notification toggle
  
missing:
  - Work preferences
  - Availability patterns
  - Communication preferences
  - Shift preferences
  - Break preferences
```

### Request Creation Limitations
```yaml
vue_bug: "Причина field self-clears"
missing_features:
  - Request templates
  - Recurring requests
  - Bulk request creation
  - Request delegation
  - Attachment support
```

## 📊 Implementation Priorities

### HIGH Priority
1. **Employee Profile Management** - Basic functionality missing
2. **Search Capability** - Employees need to find their data
3. **External ID Support** - Critical for integrations

### MEDIUM Priority
1. **Bulk Operations** - For efficiency
2. **Error Recovery** - Better UX
3. **Notification Preferences** - Beyond on/off

### LOW Priority
1. **Placeholder Employees** - Edge case
2. **Session Timeout Warnings** - Already long-lived
3. **Advanced Filters** - Nice to have

## 💡 Key Insights

1. **Employee Portal is Isolated**: No employee search because employees shouldn't see each other's data
2. **External IDs Missing**: The b00039954 format suggests integration needs we haven't addressed
3. **Bulk Operations Gap**: Individual actions only, no efficiency features
4. **Profile Management Critical**: Biggest missing piece for employee self-service

---

**Time spent**: 3 hours (including previous exploration)
**Verdict**: Employee portal is functional but missing depth in profile management and bulk operations