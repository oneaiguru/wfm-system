# Vue.js Mobile Patterns - PROPOSED IMPLEMENTATION GUIDE

**Agent**: R8-UXMobileEnhancements  
**Framework**: Vue.js WFMCC1.24.0 + Vuetify  
**Architecture**: SPA with client-side routing  
**Date**: 2025-07-29  
**Status**: PROPOSED PATTERNS - Not discovered from live system

## ⚠️ IMPORTANT NOTE
This document contains **proposed implementation patterns** based on Vue.js best practices.
These are NOT discovered from the actual Argus system via MCP testing.
For actual discovered APIs, see MOBILE_APIS_DISCOVERED.md

## 🏗️ Vue.js Mobile Architecture

### Component Structure
```javascript
// Main App.vue mobile setup
export default {
  data() {
    return {
      isMobile: false,
      viewport: { width: 0, height: 0 }
    }
  },
  mounted() {
    this.checkMobile();
    window.addEventListener('resize', this.checkMobile);
  },
  methods: {
    checkMobile() {
      this.isMobile = window.innerWidth < 768;
      this.viewport = {
        width: window.innerWidth,
        height: window.innerHeight
      };
      // Trigger mobile-specific API calls
      if (this.isMobile) {
        this.$store.dispatch('app/loadMobileData');
      }
    }
  }
}
```

## 📱 Mobile-Specific Vuex Patterns

### State Management for Mobile
```javascript
// store/modules/app.js
const state = {
  isMobile: false,
  offlineQueue: [],
  syncStatus: 'idle',
  touchSupport: false,
  deviceInfo: {}
};

const actions = {
  // Mobile-specific data loading
  async loadMobileData({ commit, state }) {
    if (!state.isMobile) return;
    
    // Batch mobile API calls
    const [calendar, notifications, preferences] = await Promise.all([
      fetch('/gw/api/v1/calendar/mobile?view=week'),
      fetch('/gw/api/v1/notifications/badge'),
      fetch('/gw/api/v1/user/preferences/mobile')
    ]);
    
    commit('SET_MOBILE_DATA', {
      calendar: await calendar.json(),
      notifications: await notifications.json(),
      preferences: await preferences.json()
    });
  },
  
  // Offline queue management
  queueOfflineAction({ commit }, action) {
    commit('ADD_TO_OFFLINE_QUEUE', {
      ...action,
      timestamp: Date.now(),
      id: `offline-${Date.now()}`
    });
  }
};
```

## 🔄 Route-Based Code Splitting

### Mobile Route Configuration
```javascript
// router/index.js
const routes = [
  {
    path: '/calendar',
    component: () => import(
      /* webpackChunkName: "calendar-mobile" */
      /* webpackPrefetch: true */
      '@/views/mobile/CalendarMobile.vue'
    ),
    meta: { 
      requiresAuth: true,
      preloadData: ['calendar', 'shifts']
    }
  },
  {
    path: '/requests',
    component: () => import(
      /* webpackChunkName: "requests-mobile" */
      '@/views/mobile/RequestsMobile.vue'
    )
  }
];

// Route guards for mobile data preloading
router.beforeEach(async (to, from, next) => {
  if (store.state.app.isMobile && to.meta.preloadData) {
    await store.dispatch('preloadMobileData', to.meta.preloadData);
  }
  next();
});
```

## 📲 Touch Interaction Patterns

### Swipe Gestures
```javascript
// Mobile calendar component
<template>
  <v-touch
    @swipeleft="nextWeek"
    @swiperight="previousWeek"
    :swipe-options="{ threshold: 100 }"
  >
    <mobile-calendar-week 
      :week="currentWeek"
      @shift-press="handleShiftPress"
    />
  </v-touch>
</template>

<script>
export default {
  methods: {
    async nextWeek() {
      // Optimistic UI update
      this.currentWeek = addWeek(this.currentWeek);
      
      // API call for next week data
      const response = await this.$api.get('/gw/api/v1/calendar/mobile', {
        params: { week: this.currentWeek }
      });
      
      this.$store.commit('calendar/SET_WEEK_DATA', response.data);
    },
    
    handleShiftPress(shift) {
      if (this.touchDuration > 500) {
        // Long press - show quick actions
        this.$refs.quickActions.show(shift);
      } else {
        // Regular tap - show details
        this.$router.push(`/shift/${shift.id}`);
      }
    }
  }
}
</script>
```

## 🎨 Vuetify Mobile Optimizations

### Responsive Component Usage
```vue
<!-- Mobile-optimized navigation -->
<v-navigation-drawer
  v-model="drawer"
  :temporary="$vuetify.breakpoint.mobile"
  :permanent="!$vuetify.breakpoint.mobile"
  :mini-variant="!$vuetify.breakpoint.mobile && miniVariant"
  app
>
  <mobile-nav-list v-if="$vuetify.breakpoint.mobile" />
  <desktop-nav-list v-else />
</v-navigation-drawer>

<!-- Mobile-specific dialog -->
<v-dialog
  v-model="showRequestDialog"
  :fullscreen="$vuetify.breakpoint.mobile"
  :max-width="$vuetify.breakpoint.mobile ? '100%' : '600px'"
  :transition="$vuetify.breakpoint.mobile ? 'dialog-bottom-transition' : 'dialog-transition'"
>
  <mobile-request-form v-if="$vuetify.breakpoint.mobile" />
  <desktop-request-form v-else />
</v-dialog>
```

### Mobile Theme Patterns
```javascript
// plugins/vuetify.js
export default new Vuetify({
  theme: {
    themes: {
      light: {
        primary: '#46BBB1', // From user preferences
        // Mobile-specific overrides
        ...(window.innerWidth < 768 ? {
          background: '#FAFAFA', // Lighter for mobile
        } : {})
      }
    },
    options: {
      customProperties: true,
      variations: false // Disable for mobile performance
    }
  },
  breakpoint: {
    mobileBreakpoint: 'sm',
    thresholds: {
      xs: 375,  // Mobile portrait
      sm: 768,  // Mobile landscape / tablet
      md: 1024, // Desktop
    }
  }
});
```

## 🔧 Mobile API Integration Patterns

### API Interceptors for Mobile
```javascript
// plugins/axios.js
axios.interceptors.request.use(config => {
  // Add mobile headers
  if (store.state.app.isMobile) {
    config.headers['X-Mobile-Client'] = 'true';
    config.headers['X-Viewport'] = `${window.innerWidth}x${window.innerHeight}`;
  }
  
  // Handle offline
  if (!navigator.onLine) {
    if (config.method === 'GET') {
      // Try cache first
      return getCachedResponse(config.url) || Promise.reject(new Error('Offline'));
    } else {
      // Queue for sync
      store.dispatch('app/queueOfflineAction', config);
      return Promise.reject(new Error('Queued for sync'));
    }
  }
  
  return config;
});
```

### Mobile-Specific API Calls
```javascript
// api/mobile.js
export const mobileAPI = {
  // Batch requests for mobile
  async getInitialData() {
    const response = await axios.post('/gw/api/v1/mobile/batch', {
      requests: [
        { id: '1', url: '/calendar/current-week' },
        { id: '2', url: '/notifications/unread-count' },
        { id: '3', url: '/user/quick-actions' }
      ]
    });
    
    return response.data.responses.reduce((acc, res) => {
      acc[res.id] = res.data;
      return acc;
    }, {});
  },
  
  // Progressive data loading
  async loadViewportData(component, viewport) {
    return axios.get(`/gw/api/v1/components/${component}/data`, {
      params: {
        viewport: `${viewport.width}x${viewport.height}`,
        limit: this.calculateOptimalLimit(viewport)
      }
    });
  },
  
  calculateOptimalLimit(viewport) {
    // Mobile portrait: 10 items
    // Mobile landscape: 15 items
    // Tablet: 20 items
    return viewport.width < 414 ? 10 : viewport.width < 768 ? 15 : 20;
  }
};
```

## 📊 Performance Monitoring

### Vue.js Performance API Integration
```javascript
// mixins/performance.js
export default {
  mounted() {
    if (this.$options.trackPerformance) {
      performance.mark(`${this.$options.name}-mounted`);
      
      // Track component mount time
      this.$nextTick(() => {
        performance.measure(
          `${this.$options.name}-mount`,
          'navigationStart',
          `${this.$options.name}-mounted`
        );
        
        // Send to analytics if mobile
        if (this.$store.state.app.isMobile) {
          this.$analytics.track('component-performance', {
            component: this.$options.name,
            mountTime: performance.getEntriesByName(`${this.$options.name}-mount`)[0].duration,
            viewport: this.$store.state.app.viewport
          });
        }
      });
    }
  }
};
```

## 🚀 Mobile Optimization Checklist

### Component Level
- [x] Lazy load route components
- [x] Use v-if instead of v-show for mobile
- [x] Implement virtual scrolling for long lists
- [ ] Add skeleton screens during loading

### API Level
- [x] Batch requests where possible
- [x] Implement field selection
- [x] Add viewport-aware pagination
- [ ] Enable HTTP/2 multiplexing

### State Management
- [x] Separate mobile/desktop state
- [x] Implement offline queue
- [x] Cache API responses
- [ ] Add optimistic updates

## 🔗 Related Patterns
- See MOBILE_DATA_OPTIMIZATION.md for API patterns
- See PWA_OFFLINE_APIS.md for offline support
- See MOBILE_AUTHENTICATION_APIS.md for auth flow