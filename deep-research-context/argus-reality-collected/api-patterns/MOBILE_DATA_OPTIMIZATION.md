# Mobile Data Optimization APIs - Vue.js Employee Portal

**Agent**: R8-UXMobileEnhancements  
**Portal**: Employee (lkcc1010wfmcc.argustelecom.ru)  
**Performance**: 11.56s load → Target <3s  
**Date**: 2025-07-29

## 📊 Current Performance Baseline

### Initial Load Waterfall
```http
# Main bundles (blocking)
GET /js/chunk-vendors.[hash].js (446 Vuetify components)
Size: ~850KB → Needs code splitting
Duration: 2.1s

GET /js/app.[hash].js (Application code)
Size: ~320KB
Duration: 1.3s

GET /css/chunk-vendors.[hash].css
Size: ~180KB
Duration: 0.8s

# Total blocking time: ~4.2s
```

## 🚀 Mobile Optimization Patterns

### 1. Component Lazy Loading
```javascript
// Expected pattern for mobile routes
const Calendar = () => import(/* webpackChunkName: "calendar" */ './Calendar.vue')
const Notifications = () => import(/* webpackChunkName: "notifications" */ './Notifications.vue')

// API calls for lazy components
GET /js/calendar.[hash].js (on-demand)
GET /gw/api/v1/calendar/data?view=mobile
```

### 2. Mobile-Specific Data Endpoints
```http
# Desktop calendar (full month)
GET /gw/api/v1/calendar/events?month=2025-07
Response size: ~120KB (all events)

# Mobile calendar (viewport-aware)
GET /gw/api/v1/calendar/mobile?week=2025-W31&limit=20
Response: {
  "events": [...], // Only visible week
  "summary": {
    "totalShifts": 5,
    "totalHours": 40
  },
  "hasMore": true,
  "nextPageUrl": "/calendar/mobile?week=2025-W31&offset=20"
}
Response size: ~15KB (80% reduction)
```

### 3. Progressive Data Loading
```http
# Initial page load - critical data only
GET /gw/api/v1/mobile/bootstrap
Response: {
  "user": { "id": "123", "name": "Test User" },
  "criticalNotifications": [], // Urgent only
  "upcomingShift": { "date": "2025-07-29", "time": "09:00" },
  "quickActions": ["clockIn", "requestVacation"]
}

# After viewport idle
GET /gw/api/v1/mobile/prefetch
Response: {
  "fullCalendar": [...],
  "allNotifications": [...],
  "teamSchedule": [...]
}
```

### 4. Image Optimization
```http
# Desktop images
GET /images/profile/[id].jpg
Size: 500x500, ~150KB

# Mobile responsive images
GET /gw/api/v1/images/profile/[id]?size=mobile
Size: 100x100, ~15KB, WebP format

# Lazy loading pattern
<img loading="lazy" 
     srcset="/images/profile/[id]?size=50w 50w,
             /images/profile/[id]?size=100w 100w"
     sizes="(max-width: 375px) 50px, 100px">
```

### 5. API Response Compression
```http
# Enable gzip/brotli compression
GET /gw/api/v1/notifications/list
Headers:
  Accept-Encoding: gzip, br
  X-Mobile-Client: true

Response Headers:
  Content-Encoding: gzip
  X-Original-Size: 45KB
  X-Compressed-Size: 8KB
```

## 📱 Mobile-First API Patterns

### 1. Infinite Scroll vs Pagination
```javascript
// Mobile notification list
GET /gw/api/v1/notifications/mobile?page=1&size=20
Response: {
  "items": [...],
  "page": {
    "current": 1,
    "total": 6,
    "hasNext": true
  }
}

// Intersection Observer trigger
GET /gw/api/v1/notifications/mobile?page=2&size=20
```

### 2. Aggregated Data for Mobile
```http
# Instead of multiple calls
GET /gw/api/v1/dashboard/mobile
Response: {
  "summary": {
    "shifts": { "this_week": 5, "next_week": 4 },
    "requests": { "pending": 2, "approved": 3 },
    "notifications": { "unread": 15 }
  },
  "quickLinks": [...]
}
```

### 3. Field Selection for Mobile
```http
# Desktop - full employee data
GET /gw/api/v1/team/members

# Mobile - essential fields only
GET /gw/api/v1/team/members?fields=id,name,avatar,status
Response: [
  {
    "id": "123",
    "name": "Иванов И.И.",
    "avatar": "/images/123-thumb.jpg",
    "status": "available"
  }
  // No schedule details, contact info, etc.
]
```

## 🎯 Performance Optimization Checklist

### Bundle Optimization
- [ ] Code split by route (calendar, requests, etc.)
- [ ] Lazy load Vuetify components
- [ ] Tree-shake unused components
- [ ] Implement dynamic imports

### API Optimization
- [ ] Implement field selection
- [ ] Add mobile-specific endpoints
- [ ] Enable response compression
- [ ] Implement cursor-based pagination

### Caching Strategy
```javascript
// Service Worker caching
caches.open('api-cache-v1').then(cache => {
  cache.match('/gw/api/v1/user/preferences').then(response => {
    if (response) return response;
    return fetch('/gw/api/v1/user/preferences').then(fetchResponse => {
      cache.put('/gw/api/v1/user/preferences', fetchResponse.clone());
      return fetchResponse;
    });
  });
});
```

## 📊 Expected Performance Gains

### Current vs Optimized
```
Initial Load: 11.56s → 2.8s (75% improvement)
- Bundle size: 1350KB → 450KB (critical path)
- API calls: 8 parallel → 3 sequential
- Images: 2.1MB → 340KB (lazy + WebP)

Time to Interactive: 8.99s → 2.2s
- Defer non-critical JS
- Progressive enhancement
- Optimistic UI updates
```

## 🔗 Implementation Priority

1. **Quick Wins** (1 week)
   - Enable gzip compression
   - Implement lazy loading
   - Add mobile endpoints

2. **Medium Term** (2-3 weeks)
   - Code splitting
   - Service worker
   - Image optimization

3. **Long Term** (1-2 months)
   - Full PWA implementation
   - Offline-first architecture
   - Push notifications