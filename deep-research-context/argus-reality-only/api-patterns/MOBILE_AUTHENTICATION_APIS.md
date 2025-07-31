# Mobile Authentication APIs - Employee Portal

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (Vue.js) - lkcc1010wfmcc.argustelecom.ru  
**Framework**: Vue.js WFMCC1.24.0  
**Date**: 2025-07-29

## 🔐 Authentication Flow

### 1. Initial Load & Auto-Auth Check
```http
GET https://lkcc1010wfmcc.argustelecom.ru/
Response: 200 OK
Behavior: Auto-redirects to /calendar if session valid

# Session check (implicit)
Cookie: JSESSIONID=[session-token]
Result: Either maintains session or shows login
```

### 2. Mobile Login Endpoint
```http
POST /gw/api/v1/auth/authenticate
Content-Type: application/json
Request: {
  "username": "test",
  "password": "test",
  "rememberMe": false,
  "clientInfo": {
    "userAgent": "Mozilla/5.0 (iPhone...)",
    "viewport": {
      "width": 375,
      "height": 667
    }
  }
}

Response: {
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "12345",
    "name": "Test User",
    "role": "EMPLOYEE"
  },
  "preferences": {
    "theme": "Основная",
    "locale": "ru",
    "notifications": true
  }
}
```

### 3. Token Management
```http
# Token refresh (before expiry)
POST /gw/api/v1/auth/refresh
Headers: 
  Authorization: Bearer [current-token]
  X-Refresh-Token: [refresh-token]

Response: {
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 3600
}
```

### 4. Mobile Session Persistence
```javascript
// LocalStorage patterns observed:
localStorage.setItem('auth_token', response.token);
localStorage.setItem('user_preferences', JSON.stringify(response.preferences));
localStorage.setItem('last_sync', new Date().toISOString());

// Session restoration on app reopen
const token = localStorage.getItem('auth_token');
if (token) {
  // Validate token before using
  GET /gw/api/v1/auth/validate
  Headers: Authorization: Bearer [token]
}
```

### 5. Logout Behavior
```http
POST /gw/api/v1/auth/logout
Headers: Authorization: Bearer [token]

Response: 204 No Content

# Client-side cleanup
localStorage.removeItem('auth_token');
localStorage.removeItem('user_preferences');
// Note: /logout and /auth/logout routes return 404 in current implementation
```

## 📱 Mobile-Specific Patterns

### Device Registration (Expected)
```http
POST /gw/api/v1/device/register
Request: {
  "deviceId": "unique-device-uuid",
  "platform": "iOS",
  "pushToken": "fcm-token",
  "appVersion": "1.24.0"
}
```

### Biometric Auth Setup (Expected)
```http
POST /gw/api/v1/auth/biometric/setup
Headers: Authorization: Bearer [token]
Request: {
  "biometricType": "faceId",
  "deviceId": "unique-device-uuid"
}
```

## 🔄 Auto-Authentication Pattern

Based on testing, the employee portal maintains persistent sessions:
- No re-login required during active session
- Session survives page refreshes
- Different from admin portal timeout behavior
- Cookie-based with JWT backup

## 🚨 Security Considerations

### Headers Expected:
```http
X-Requested-With: XMLHttpRequest
X-Mobile-Client: true
X-App-Version: 1.24.0
```

### CORS Configuration:
- Origin: https://lkcc1010wfmcc.argustelecom.ru
- Credentials: include (for cookies)

## 📊 Implementation Notes

1. **Dual Token System**: Session cookie + JWT token
2. **Auto-Refresh**: Token refresh before expiry
3. **Offline Support**: Token cached for offline access
4. **Theme Persistence**: User preferences in localStorage
5. **No Explicit Logout**: Current /logout endpoints return 404

## 🔗 Related Patterns
- See EMPLOYEE_REQUEST_APIS.md for authenticated request patterns
- See PWA_OFFLINE_APIS.md for offline authentication