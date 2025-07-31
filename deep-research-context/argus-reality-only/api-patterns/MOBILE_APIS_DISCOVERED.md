# Mobile APIs - Actually Discovered via MCP Testing

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (Vue.js) - lkcc1010wfmcc.argustelecom.ru  
**Date**: 2025-07-29  
**Method**: Direct MCP browser automation with API monitoring

## 🔐 Authentication APIs (Confirmed)

### Login Endpoint
```http
POST /gw/signin
Content-Type: application/json

Request:
{
  "username": "string",
  "password": "string"
}

Response (Error):
{
  "message": "Неверный логин или пароль. Проверьте правильность введенных данных.",
  "description": "BadCredentialsException"
}

Response (Success - Expected):
{
  "token": "string",
  "refreshToken": "string",
  "userInfo": {
    "id": "number",
    "name": "string",
    "role": "string"
  }
}
```

## 📱 Mobile Detection

### Current Viewport Detection
- Desktop viewport: 1484x795
- Mobile detection: `window.innerWidth < 768`
- Touch support: Not available in desktop browser
- User Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)

## 🎯 API Monitoring Script (Working)

Successfully injected and capturing:
- All fetch() calls
- All XMLHttpRequest calls
- Request/response data
- Viewport information
- Timestamps

## 📋 Next Steps for Discovery

1. **Get Valid Credentials**: Need working login to access main app
2. **Test Mobile Viewport**: Use browser dev tools to simulate mobile
3. **Capture Navigation APIs**: Document route transitions
4. **Monitor Data Loading**: Track lazy loading patterns
5. **Test Offline Mode**: Check PWA capabilities

## 🚧 Current Blockers

1. **Invalid Credentials**: Both test accounts (ivanov.i, sidorov.s) failing
2. **Viewport Simulation**: Browser window.resizeTo() not working
3. **Touch Events**: Not available in desktop browser

## 📊 Captured API Patterns

### Request Structure
- Base URL: `https://lkcc1010wfmcc.argustelecom.ru`
- API Gateway: `/gw/` prefix
- Content-Type: `application/json`
- Authentication: Likely Bearer token after login

### Error Response Pattern
```json
{
  "message": "Human-readable error message",
  "description": "TechnicalExceptionType"
}
```

## 📱 Vue.js Configuration (Discovered from Vuex)

### Application Settings
```json
{
  "product": {
    "name": "WFMCC",
    "version": "1.24.0"
  },
  "globalTheme": "light",
  "shiftStep": 5,
  "intervalDuration": 900000,  // 15 minutes in ms
  "requestConfig": {
    "commentRequired": false
  },
  "color": "#46BBB1"  // Primary theme color
}
```

### Authentication State Structure
```json
{
  "auth": {
    "status": {
      "loggedIn": false
    },
    "user": null,
    "state": null,
    "codeVerifier": null,
    "keycloakRefreshToken": null,
    "keycloakAccessToken": null
  }
}
```

**Important Discovery**: Uses Keycloak for authentication!

### JavaScript Bundle Structure
- Chunk vendors: `chunk-vendors.1b334e1c.js`
- Main app: `app.07e99728.js`
- Additional chunks loaded on demand

## 🔄 Session Progress

- [x] MCP tools confirmed working
- [x] API monitor injected successfully
- [x] Authentication endpoint discovered
- [x] Vuex store structure discovered
- [x] Keycloak integration identified
- [ ] Main application APIs pending (need valid login)
- [ ] Mobile-specific endpoints pending
- [ ] PWA/offline APIs pending