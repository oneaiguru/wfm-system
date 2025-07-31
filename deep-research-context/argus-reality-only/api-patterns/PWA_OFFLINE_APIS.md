# PWA & Offline API Patterns - Employee Portal

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (Vue.js WFMCC1.24.0)  
**Target**: Progressive Web App with offline support  
**Date**: 2025-07-29

## 🔧 Service Worker Registration

### Initial Registration Pattern
```javascript
// Expected in main.js or App.vue
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')
    .then(registration => {
      // Check for updates periodically
      setInterval(() => {
        registration.update();
      }, 60 * 60 * 1000); // Every hour
      
      // Send registration to server
      fetch('/gw/api/v1/pwa/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scope: registration.scope,
          endpoint: registration.active?.scriptURL
        })
      });
    });
}
```

### Update Detection API
```http
POST /gw/api/v1/pwa/version-check
Request: {
  "currentVersion": "1.24.0",
  "lastSync": "2025-07-29T10:00:00Z"
}
Response: {
  "hasUpdate": true,
  "newVersion": "1.24.1",
  "updateType": "minor",
  "forceUpdate": false
}
```

## 📡 Push Notification APIs

### Subscription Flow
```javascript
// Request permission and subscribe
async function subscribeToPush() {
  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(PUBLIC_VAPID_KEY)
    });
    
    // Send subscription to server
    await fetch('/gw/api/v1/notifications/push/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        endpoint: subscription.endpoint,
        keys: subscription.toJSON().keys,
        topics: ['shifts', 'requests', 'alerts']
      })
    });
  }
}
```

### Push Notification Payload
```http
# Server to client push
POST [subscription.endpoint]
Headers:
  Authorization: WebPush [VAPID_SIGNATURE]
  TTL: 2419200
  Content-Encoding: aes128gcm

Payload: {
  "type": "shift-reminder",
  "title": "Смена через 30 минут",
  "body": "Ваша смена начинается в 09:00",
  "data": {
    "shiftId": "12345",
    "startTime": "2025-07-29T09:00:00Z",
    "deepLink": "/calendar/shift/12345"
  },
  "actions": [
    { "action": "view", "title": "Посмотреть" },
    { "action": "acknowledge", "title": "Понятно" }
  ]
}
```

## 💾 Offline Queue Management

### Queue Structure
```javascript
// IndexedDB schema for offline queue
const OFFLINE_DB = {
  name: 'wfm-offline',
  version: 1,
  stores: {
    requests: {
      keyPath: 'localId',
      indexes: ['timestamp', 'syncStatus']
    },
    cache: {
      keyPath: 'url',
      indexes: ['expiry', 'category']
    }
  }
};

// Queue action example
const queueAction = {
  localId: 'offline-' + Date.now(),
  type: 'vacation-request',
  method: 'POST',
  url: '/gw/api/v1/requests/vacation',
  body: {
    startDate: '2025-08-01',
    endDate: '2025-08-10',
    reason: 'Отпуск'
  },
  timestamp: Date.now(),
  syncStatus: 'pending',
  retryCount: 0
};
```

### Sync API Pattern
```http
# Background sync when online
POST /gw/api/v1/sync/batch
Request: {
  "deviceId": "unique-device-id",
  "actions": [
    {
      "localId": "offline-1627384920",
      "type": "vacation-request",
      "data": {
        "startDate": "2025-08-01",
        "endDate": "2025-08-10"
      },
      "timestamp": "2025-07-29T08:00:00Z"
    }
  ],
  "lastSuccessfulSync": "2025-07-29T07:00:00Z"
}

Response: {
  "results": [
    {
      "localId": "offline-1627384920",
      "status": "success",
      "serverId": "req-98765",
      "serverTimestamp": "2025-07-29T10:00:00Z"
    }
  ],
  "serverTime": "2025-07-29T10:00:00Z",
  "nextSyncToken": "sync-token-123"
}
```

## 🗄️ Cache Management Strategies

### API Response Caching
```javascript
// Service worker cache strategies
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  
  // Cache-first for static assets
  if (url.pathname.startsWith('/static/')) {
    event.respondWith(
      caches.match(event.request)
        .then(response => response || fetch(event.request))
    );
  }
  
  // Network-first with fallback for API
  else if (url.pathname.startsWith('/gw/api/')) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          // Cache successful responses
          if (response.ok) {
            const clone = response.clone();
            caches.open('api-cache-v1').then(cache => {
              cache.put(event.request, clone);
            });
          }
          return response;
        })
        .catch(() => {
          // Fallback to cache when offline
          return caches.match(event.request);
        })
    );
  }
});
```

### Cache Control Headers
```http
# Server response headers for caching
GET /gw/api/v1/user/preferences
Response Headers:
  Cache-Control: private, max-age=3600
  ETag: "abc123"
  Last-Modified: Mon, 29 Jul 2025 10:00:00 GMT

# Conditional request when online
GET /gw/api/v1/user/preferences
Request Headers:
  If-None-Match: "abc123"
  If-Modified-Since: Mon, 29 Jul 2025 10:00:00 GMT
Response: 304 Not Modified
```

## 📱 App Shell Architecture

### Shell Caching Pattern
```javascript
// Precache app shell resources
const APP_SHELL = [
  '/',
  '/index.html',
  '/js/app.[hash].js',
  '/css/app.[hash].css',
  '/manifest.json',
  '/offline.html'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open('app-shell-v1')
      .then(cache => cache.addAll(APP_SHELL))
  );
});
```

### Manifest Configuration
```json
// manifest.json
{
  "name": "WFM Employee Portal",
  "short_name": "WFM",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#46BBB1",
  "background_color": "#FAFAFA",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "categories": ["business", "productivity"],
  "orientation": "portrait"
}
```

## 🔄 Background Sync Patterns

### Periodic Sync Registration
```javascript
// Register periodic background sync
async function registerPeriodicSync() {
  const registration = await navigator.serviceWorker.ready;
  
  try {
    await registration.periodicSync.register('sync-schedule', {
      minInterval: 12 * 60 * 60 * 1000 // 12 hours
    });
    
    // Notify server of sync registration
    await fetch('/gw/api/v1/sync/register-periodic', {
      method: 'POST',
      body: JSON.stringify({
        tag: 'sync-schedule',
        interval: 12 * 60 * 60 * 1000
      })
    });
  } catch (err) {
    console.error('Periodic sync not supported');
  }
}
```

### Background Fetch for Large Data
```javascript
// Download schedule data in background
async function backgroundFetchSchedule() {
  const registration = await navigator.serviceWorker.ready;
  
  const bgFetch = await registration.backgroundFetch.fetch(
    'monthly-schedule',
    ['/gw/api/v1/schedule/export?month=2025-08'],
    {
      title: 'Загрузка расписания',
      icons: [{ src: '/icons/download.png' }],
      downloadTotal: 1024 * 1024 * 5 // 5MB estimate
    }
  );
  
  bgFetch.addEventListener('progress', event => {
    const percent = Math.round(event.downloaded / event.downloadTotal * 100);
    // Update UI with progress
  });
}
```

## 🚨 Offline Error Handling

### Network Status Detection
```javascript
// Vuex store module for network status
const networkModule = {
  state: {
    isOnline: navigator.onLine,
    connectionType: navigator.connection?.effectiveType,
    lastOnline: null
  },
  
  mutations: {
    SET_ONLINE_STATUS(state, isOnline) {
      state.isOnline = isOnline;
      if (isOnline) {
        state.lastOnline = new Date().toISOString();
      }
    }
  },
  
  actions: {
    async syncOfflineData({ state, dispatch }) {
      if (!state.isOnline) return;
      
      // Trigger sync
      const response = await fetch('/gw/api/v1/sync/trigger', {
        method: 'POST',
        body: JSON.stringify({
          lastSync: state.lastOnline
        })
      });
      
      if (response.ok) {
        dispatch('processQueuedActions');
      }
    }
  }
};
```

## 📊 PWA Analytics APIs

### Performance Tracking
```http
POST /gw/api/v1/analytics/pwa-metrics
Request: {
  "metrics": {
    "cacheHitRate": 0.85,
    "offlineUsageMinutes": 45,
    "syncConflicts": 2,
    "pushNotificationEngagement": 0.72
  },
  "deviceInfo": {
    "platform": "iOS",
    "version": "15.5",
    "networkType": "4g"
  },
  "timestamp": "2025-07-29T10:00:00Z"
}
```

## 🔗 Implementation Checklist

### Core PWA Features
- [ ] Service worker registration
- [ ] App manifest configuration
- [ ] HTTPS enforcement
- [ ] Offline page fallback

### Caching Strategy
- [ ] Static asset caching
- [ ] API response caching
- [ ] Cache versioning
- [ ] Storage quota management

### Offline Functionality
- [ ] Offline queue implementation
- [ ] Conflict resolution
- [ ] Background sync
- [ ] Network status handling

### Push Notifications
- [ ] VAPID key generation
- [ ] Subscription management
- [ ] Topic-based routing
- [ ] Engagement tracking

## 🎯 Related Patterns
- See MOBILE_DATA_OPTIMIZATION.md for data strategies
- See VUE_MOBILE_PATTERNS.md for Vue.js integration
- See MOBILE_AUTHENTICATION_APIS.md for offline auth