# R2 Hidden Features Discovery Report - Employee Portal Deep Dive

**Date**: 2025-07-30
**Agent**: R2-EmployeeSelfService
**Mission**: Systematic exploration of employee portal for undiscovered features

## 🎯 MAJOR DISCOVERIES

### 1. **Working Profile Page** (/user-info)
**Location**: https://lkcc1010wfmcc.argustelecom.ru/user-info
**Description**: Full employee profile with settings
**BDD Coverage**: Not covered
**APIs Found**: 
  - GET /gw/api/v1/userInfo
  - GET /gw/api/v1/userInfo/userpic?userId=111538
**UI Elements**: 
  - "Профиль пользователя" → "User Profile"
  - "Включить оповещения" → "Enable notifications"
  - "Подписаться" → "Subscribe"
  - "Часовой пояс" → "Timezone"
**Implementation Priority**: HIGH - Critical for employee self-service

### Profile Data Structure:
```json
{
  "fullName": "Бирюков Юрий Артёмович",
  "department": "ТП Группа Поляковой",
  "position": "Специалист",
  "timezone": "Екатеринбург",
  "notifications": {
    "enabled": false,
    "subscribed": false
  }
}
```

### 2. **Offline Capabilities & PWA Support**
**Location**: Employee portal infrastructure
**Description**: Service Worker support and localStorage persistence
**BDD Coverage**: Not covered
**Technical Details**:
  - Service Worker: Available
  - Cache API: Available
  - IndexedDB: Available
  - localStorage: 2 items (user data + vuex state)
**Implementation Priority**: MEDIUM - Enhanced user experience

### localStorage Structure:
```json
{
  "user": {
    "token": "JWT token",
    "id": 111538,
    "username": "test",
    "email": "",
    "roles": []
  },
  "vuex": "Application state storage"
}
```

### 3. **Hidden Navigation Path**
**Finding**: "Пожелания" (Wishes) menu item exists but returns 404
**Location**: https://lkcc1010wfmcc.argustelecom.ru/wishes
**Description**: Planned feature for employee preferences/wishes
**BDD Coverage**: Not covered
**Implementation Status**: UI present but backend not implemented
**Implementation Priority**: LOW - Future enhancement

### 4. **Notification System Depth**
**Location**: /notifications
**Description**: 106 real operational notifications with filtering
**BDD Coverage**: Partially covered
**Features Found**:
  - Filter: "Только непрочитанные сообщения" (Only unread messages)
  - No bulk selection capabilities
  - No "Mark all as read" functionality
  - Real-time work schedule notifications
**Implementation Priority**: MEDIUM - Missing bulk operations

### 5. **Exchange System Structure**
**Location**: /exchange
**Description**: Shift trading marketplace with two tabs
**BDD Coverage**: Basic coverage only
**UI Elements**:
  - "Мои" → "My exchanges"
  - "Доступные" → "Available exchanges"
  - "Предложения, на которые вы откликнулись" → "Offers you responded to"
**Implementation Priority**: HIGH - Core feature for flexibility

## 📊 NEW API ENDPOINTS DISCOVERED

### Profile APIs (Not in original 28):
```javascript
GET /gw/api/v1/userInfo
// Returns: Full user profile data

GET /gw/api/v1/userInfo/userpic?userId={id}
// Returns: User profile picture
```

### Additional Login-time APIs Found:
```javascript
POST /gw/signin
GET /gw/api/v1/directories/prefValues/
GET /gw/api/v1/directories/eventTypes/
GET /gw/api/v1/directories/calendarColorLegends/
GET /gw/api/v1/directories/channelColorLegends/
```

## 🔍 MISSING FEATURES (Not Found)

### 1. Keyboard Shortcuts
- No global search (Ctrl+K)
- No quick navigation shortcuts
- Standard browser shortcuts only

### 2. Bulk Operations
- No bulk notification management
- No multi-select in any list view
- No batch request creation

### 3. Export Capabilities
- No calendar export (iCal, etc.)
- No data download options
- No print views

### 4. Advanced Preferences
- Limited to theme switching only
- No notification channel preferences
- No working hours preferences
- No communication preferences

### 5. Mobile-Specific Features
- No detected swipe gestures
- No pull-to-refresh
- Standard responsive design only

## 🌐 ARCHITECTURE INSIGHTS

### Vue.js Implementation Details:
- Vuex for state management
- JWT stored in localStorage
- No session storage usage
- PWA-ready infrastructure

### Security Observations:
- JWT token with long expiry (exp: 1754298157)
- User ID exposed in API calls
- No visible CSRF protection

## 📋 RUSSIAN UI ELEMENTS CAPTURED

### Profile Page:
- ФИО → Full Name
- Подразделение → Department
- Должность → Position
- Часовой пояс → Timezone
- Включить оповещения → Enable notifications
- Подписаться → Subscribe

### Common UI:
- Отсутствуют данные → No data
- Период → Period
- Название → Name
- Статус → Status
- Начало → Start
- Окончание → End

## 🎯 IMPLEMENTATION RECOMMENDATIONS

### High Priority:
1. **User Profile Page** - Critical missing feature
2. **Profile Picture Upload** - API exists, UI missing
3. **Notification Preferences** - Toggle exists, needs expansion

### Medium Priority:
1. **Bulk Notification Actions** - Improve usability
2. **Offline Mode** - Leverage existing PWA infrastructure
3. **Export Features** - Calendar/data exports

### Low Priority:
1. **Keyboard Shortcuts** - Nice-to-have
2. **Wishes/Preferences** - Future feature
3. **Advanced Theme Options** - Already has basic theme

## 💡 KEY INSIGHTS

1. **Profile Management Gap**: The biggest discovery is the working profile page that's not in BDD specs. This is critical for employee self-service.

2. **PWA Infrastructure**: The app is PWA-ready with service workers and offline storage, but not fully utilized.

3. **Notification Overload**: 106 notifications without bulk management is a UX problem to solve.

4. **Directory APIs**: Multiple directory endpoints suggest a rich configuration system we haven't explored.

5. **Security Consideration**: Long JWT expiry (2025-08-01) might be a security concern for production.

---

**Total New Features Found**: 5 major areas
**New API Endpoints**: 7 endpoints
**Implementation Gaps**: Profile management, bulk operations, export features
**Time Invested**: 2 hours systematic exploration