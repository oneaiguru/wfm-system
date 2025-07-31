# Mobile UI Patterns - Employee Portal Discovery

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (Vue.js) - lkcc1010wfmcc.argustelecom.ru  
**Date**: 2025-07-29  
**Method**: Direct MCP browser testing with authenticated access

## 🏗️ Architecture Confirmed

### Frontend Stack
- **Framework**: Vue.js 2.x (confirmed via __vue__ instance)
- **UI Library**: Vuetify (v-btn, v-app-bar classes)
- **State Management**: Vuex with localStorage persistence
- **Authentication**: JWT tokens (not Keycloak in employee portal)
- **PWA Support**: Service Worker enabled

### Authentication Flow
```http
POST /gw/signin
{
  "username": "string",
  "password": "string"  
}

Response (Success):
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9...",
  "user": {
    "id": 111538,
    "username": "test",
    "roles": []
  }
}
```

## 📱 Mobile-Specific UI Patterns

### 1. Responsive Viewport
```html
<meta name="viewport" content="width=device-width,initial-scale=1">
```
- Mobile breakpoint: < 768px
- Current test: 375px width (iPhone SE)

### 2. Floating Action Button (FAB)
- Found: `.drawer-button` with primary color
- Pattern: Fixed position button for primary actions
- Mobile-optimized touch target

### 3. Navigation Drawer
- Hamburger menu icon in app bar
- Slide-out navigation pattern
- Touch-optimized drawer interactions

### 4. Vuetify Components
```javascript
// Button patterns found
{
  "icon-buttons": 12,     // v-btn--icon
  "round-buttons": 10,    // v-btn--round
  "fab-buttons": 1,       // Floating action
  "text-buttons": 1       // v-btn--text
}
```

### 5. Theme Configuration
```javascript
{
  "globalTheme": "light",
  "menuTheme": "global",
  "toolbarTheme": "global",
  "primaryColor": "#46BBB1",
  "shiftStep": 15,         // 15-minute intervals
  "intervalDuration": 15    // Calendar granularity
}
```

## 🎨 Color System for Mobile

### Event Type Colors (Mobile Calendar)
```javascript
{
  "SHIFT": "#00BFA5",          // Teal
  "VACATION": "#B388FF",       // Purple
  "SICK_LEAVE": "#FF80AB",     // Pink
  "LUNCH": "#33bef5",          // Light Blue
  "OVERTIME": "#00695C",       // Dark Green
  "MEETING": "#0097A7"         // Cyan
}
```

### Channel Colors (Call Center)
```javascript
{
  "Входящие звонки": "#eb8ae5",      // Pink
  "Отдел продаж": "#0dbfb6",         // Turquoise
  "Неголосовые входящие": "#e0df8d"  // Yellow
}
```

## 🔄 Navigation Routes

Employee portal main sections:
1. **Календарь** (/calendar) - Main schedule view
2. **Заявки** (/requests) - Time-off requests
3. **Оповещения** (/notifications) - Alerts
4. **Биржа** (/exchange) - Shift trading
5. **Ознакомления** (/introductions) - Acknowledgments
6. **Профиль** (/profile) - User settings

## 📊 Mobile Optimization Features

### 1. Touch Targets
- All buttons use Vuetify's standard sizing
- Icon buttons: v-btn--icon (48x48px minimum)
- Proper spacing for touch interaction

### 2. Responsive Grid
- Vuetify's 12-column grid system
- Breakpoints: xs, sm, md, lg, xl
- Mobile-first approach

### 3. Performance
- Code splitting (detected in bundle structure)
- Lazy loading for routes
- PWA with service worker

## 🚀 PWA Capabilities

```javascript
{
  "serviceWorker": true,    // PWA enabled
  "viewport": "responsive", // Mobile-ready
  "touch": false,          // Desktop browser
  "orientation": null      // Not available in desktop
}
```

## 📱 Mobile-Specific Features to Implement

Based on UI patterns discovered:

1. **Swipe Gestures**
   - Calendar week navigation
   - Shift details sliding panels
   - Pull-to-refresh for notifications

2. **Bottom Navigation**
   - Not currently implemented
   - Could replace drawer for key sections

3. **Touch Feedback**
   - Vuetify ripple effects
   - Long-press for context menus

4. **Offline Queue**
   - JWT token in localStorage
   - Could implement request queueing

## 🔗 API Patterns for Mobile

### Expected Mobile-Optimized Endpoints
Based on architecture, mobile APIs likely follow:
```
GET /gw/api/v1/calendar/mobile?week=current
GET /gw/api/v1/notifications/unread-count
GET /gw/api/v1/user/preferences/mobile
POST /gw/api/v1/requests/quick-create
```

### Batch Loading Pattern
Mobile should implement batching to reduce requests:
```javascript
POST /gw/api/v1/mobile/batch
{
  "requests": [
    { "id": "1", "endpoint": "/calendar/current" },
    { "id": "2", "endpoint": "/notifications/count" }
  ]
}
```

## 🎯 Key Findings

1. **Vue.js 2.x** with Vuetify provides mobile-ready components
2. **JWT Authentication** simpler than expected (not Keycloak)
3. **PWA Ready** with service worker support
4. **Responsive Design** with proper viewport and breakpoints
5. **Touch Optimized** UI elements with proper sizing
6. **Theme System** with comprehensive color configuration
7. **15-minute Intervals** for calendar and scheduling