/**
 * Service Worker for WFM Enterprise PWA
 * Implements offline-first strategy with background sync
 */

const CACHE_VERSION = 'wfm-v1.0.0';
const STATIC_CACHE = `${CACHE_VERSION}-static`;
const DYNAMIC_CACHE = `${CACHE_VERSION}-dynamic`;
const API_CACHE = `${CACHE_VERSION}-api`;

// Assets to cache immediately (critical for app shell)
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/offline.html',
  // Add critical CSS and JS files when bundled
  '/static/css/main.css',
  '/static/js/main.js',
  // Icons
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
  // Fallback pages
  '/offline'
];

// API endpoints to cache with different strategies
const API_CACHE_PATTERNS = [
  '/api/v1/mobile/cabinet/profile',
  '/api/v1/mobile/cabinet/dashboard',
  '/api/v1/mobile/cabinet/calendar',
  '/api/v1/mobile/cabinet/sync/status',
  '/api/v1/ai/recommendations',
  '/api/v1/ai/anomalies'
];

// Data that should always be fresh (never cached)
const NEVER_CACHE_PATTERNS = [
  '/api/v1/auth/',
  '/api/v1/mobile/sync/upload-changes',
  '/api/v1/realtime/'
];

// Maximum age for different types of cached content (in milliseconds)
const CACHE_EXPIRY = {
  static: 7 * 24 * 60 * 60 * 1000,    // 7 days
  dynamic: 24 * 60 * 60 * 1000,       // 24 hours
  api: 15 * 60 * 1000,                // 15 minutes
  profile: 60 * 60 * 1000,             // 1 hour
  schedule: 30 * 60 * 1000             // 30 minutes
};

// Install event - cache static assets
self.addEventListener('install', event => {
  console.log('[SW] Installing service worker...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        console.log('[SW] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log('[SW] Static assets cached successfully');
        return self.skipWaiting();
      })
      .catch(error => {
        console.error('[SW] Failed to cache static assets:', error);
      })
  );
});

// Activate event - cleanup old caches
self.addEventListener('activate', event => {
  console.log('[SW] Activating service worker...');
  
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => {
            if (!cacheName.startsWith(CACHE_VERSION)) {
              console.log('[SW] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('[SW] Service worker activated');
        return self.clients.claim();
      })
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests and chrome-extension requests
  if (request.method !== 'GET' || url.protocol === 'chrome-extension:') {
    return;
  }

  // API endpoints
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(handleApiRequest(request));
    return;
  }

  // Static assets and pages
  if (url.origin === location.origin) {
    event.respondWith(handleStaticRequest(request));
    return;
  }

  // External resources (CDNs, etc.)
  event.respondWith(handleExternalRequest(request));
});

// Handle API requests with cache-first or network-first strategy
async function handleApiRequest(request) {
  const url = new URL(request.url);
  
  // Never cache certain endpoints
  if (NEVER_CACHE_PATTERNS.some(pattern => url.pathname.startsWith(pattern))) {
    try {
      const response = await fetch(request);
      return response;
    } catch (error) {
      console.log('[SW] Network failed for never-cache endpoint:', url.pathname);
      return new Response(JSON.stringify({ 
        error: 'Network unavailable', 
        offline: true 
      }), {
        status: 503,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // Cache-first for profile and configuration data
  if (url.pathname.includes('/profile') || url.pathname.includes('/config')) {
    return cacheFirst(request, API_CACHE, CACHE_EXPIRY.profile);
  }

  // Cache-first for schedule data
  if (url.pathname.includes('/schedule') || url.pathname.includes('/calendar')) {
    return cacheFirst(request, API_CACHE, CACHE_EXPIRY.schedule);
  }

  // Network-first for real-time data
  if (url.pathname.includes('/dashboard') || url.pathname.includes('/status')) {
    return networkFirst(request, API_CACHE, CACHE_EXPIRY.api);
  }

  // Default: network-first with short cache
  return networkFirst(request, API_CACHE, CACHE_EXPIRY.api);
}

// Handle static requests (app shell)
async function handleStaticRequest(request) {
  // For navigation requests, try cache first, then network, then offline page
  if (request.mode === 'navigate') {
    try {
      // Try cache first
      const cachedResponse = await caches.match(request);
      if (cachedResponse) {
        return cachedResponse;
      }

      // Try network
      const response = await fetch(request);
      
      // Cache successful responses
      if (response.status === 200) {
        const cache = await caches.open(DYNAMIC_CACHE);
        cache.put(request, response.clone());
      }
      
      return response;
    } catch (error) {
      // Return offline page
      console.log('[SW] Serving offline page for navigation');
      const offlineResponse = await caches.match('/offline.html');
      return offlineResponse || new Response('Offline', { status: 503 });
    }
  }

  // For other static resources, use cache-first
  return cacheFirst(request, STATIC_CACHE, CACHE_EXPIRY.static);
}

// Handle external requests
async function handleExternalRequest(request) {
  try {
    const response = await fetch(request);
    
    // Cache successful responses
    if (response.status === 200) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Try to serve from cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    throw error;
  }
}

// Cache-first strategy
async function cacheFirst(request, cacheName, maxAge) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  // Check if cached response is still fresh
  if (cachedResponse) {
    const cachedDate = new Date(cachedResponse.headers.get('sw-cached-date') || 0);
    const isExpired = Date.now() - cachedDate.getTime() > maxAge;
    
    if (!isExpired) {
      return cachedResponse;
    }
  }
  
  try {
    // Fetch from network
    const response = await fetch(request);
    
    if (response.status === 200) {
      // Add timestamp header and cache
      const responseToCache = response.clone();
      responseToCache.headers.set('sw-cached-date', new Date().toISOString());
      cache.put(request, responseToCache);
    }
    
    return response;
  } catch (error) {
    // Return cached version if available
    if (cachedResponse) {
      return cachedResponse;
    }
    throw error;
  }
}

// Network-first strategy
async function networkFirst(request, cacheName, maxAge) {
  try {
    const response = await fetch(request);
    
    if (response.status === 200) {
      const cache = await caches.open(cacheName);
      const responseToCache = response.clone();
      responseToCache.headers.set('sw-cached-date', new Date().toISOString());
      cache.put(request, responseToCache);
    }
    
    return response;
  } catch (error) {
    // Try to serve from cache
    const cache = await caches.open(cacheName);
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      // Check if cached response is still acceptable
      const cachedDate = new Date(cachedResponse.headers.get('sw-cached-date') || 0);
      const age = Date.now() - cachedDate.getTime();
      
      // Return cached response with offline indicator
      if (age < maxAge * 3) { // Allow stale content up to 3x max age when offline
        const offlineResponse = cachedResponse.clone();
        offlineResponse.headers.set('sw-offline', 'true');
        return offlineResponse;
      }
    }
    
    throw error;
  }
}

// Background sync for offline actions
self.addEventListener('sync', event => {
  console.log('[SW] Background sync triggered:', event.tag);
  
  if (event.tag === 'offline-sync') {
    event.waitUntil(syncOfflineActions());
  }
});

// Sync offline actions with server
async function syncOfflineActions() {
  try {
    // Get offline changes from IndexedDB
    const db = await openOfflineDB();
    const transaction = db.transaction(['offline_changes'], 'readonly');
    const store = transaction.objectStore('offline_changes');
    const changes = await getAllFromStore(store);
    
    console.log('[SW] Found offline changes to sync:', changes.length);
    
    if (changes.length === 0) return;
    
    // Send changes to server
    const response = await fetch('/api/v1/mobile/sync/upload-changes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${await getAuthToken()}`
      },
      body: JSON.stringify({ offline_changes: changes })
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log('[SW] Sync completed:', result);
      
      // Remove synced changes from IndexedDB
      if (result.processed_changes?.length > 0) {
        await removeProcessedChanges(result.processed_changes);
      }
      
      // Notify clients of successful sync
      const clients = await self.clients.matchAll();
      clients.forEach(client => {
        client.postMessage({
          type: 'SYNC_COMPLETE',
          data: result
        });
      });
    }
  } catch (error) {
    console.error('[SW] Background sync failed:', error);
  }
}

// Push notifications
self.addEventListener('push', event => {
  console.log('[SW] Push message received');
  
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge.png',
    vibrate: [200, 100, 200],
    data: data.data,
    actions: data.actions || [
      {
        action: 'view',
        title: 'View',
        icon: '/icons/action-view.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss',
        icon: '/icons/action-dismiss.png'
      }
    ],
    tag: data.tag || 'wfm-notification',
    renotify: true,
    requireInteraction: data.priority === 'high'
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', event => {
  console.log('[SW] Notification clicked:', event.action);
  
  event.notification.close();
  
  if (event.action === 'dismiss') {
    return;
  }
  
  // Default action or 'view' action
  const urlToOpen = event.notification.data?.url || '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window' })
      .then(clientList => {
        // Check if app is already open
        for (const client of clientList) {
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        
        // Open new window/tab
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// Utility functions
async function openOfflineDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('wfm_offline_db', 1);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function getAllFromStore(store) {
  return new Promise((resolve, reject) => {
    const request = store.getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function getAuthToken() {
  // Try to get token from clients
  const clients = await self.clients.matchAll();
  if (clients.length > 0) {
    return new Promise((resolve) => {
      const messageChannel = new MessageChannel();
      messageChannel.port1.onmessage = (event) => {
        resolve(event.data.token);
      };
      
      clients[0].postMessage(
        { type: 'GET_AUTH_TOKEN' },
        [messageChannel.port2]
      );
    });
  }
  
  return null;
}

async function removeProcessedChanges(processedChanges) {
  const db = await openOfflineDB();
  const transaction = db.transaction(['offline_changes'], 'readwrite');
  const store = transaction.objectStore('offline_changes');
  
  for (const change of processedChanges) {
    await store.delete(change.change_id);
  }
}

// Periodic background sync (if supported)
self.addEventListener('periodicsync', event => {
  if (event.tag === 'wfm-periodic-sync') {
    event.waitUntil(performPeriodicSync());
  }
});

async function performPeriodicSync() {
  console.log('[SW] Performing periodic sync');
  
  try {
    // Sync offline changes
    await syncOfflineActions();
    
    // Update critical cache entries
    await updateCriticalData();
    
    console.log('[SW] Periodic sync completed');
  } catch (error) {
    console.error('[SW] Periodic sync failed:', error);
  }
}

async function updateCriticalData() {
  const criticalEndpoints = [
    '/api/v1/mobile/cabinet/profile',
    '/api/v1/mobile/cabinet/sync/status'
  ];
  
  const cache = await caches.open(API_CACHE);
  
  for (const endpoint of criticalEndpoints) {
    try {
      const response = await fetch(endpoint, {
        headers: {
          'Authorization': `Bearer ${await getAuthToken()}`
        }
      });
      
      if (response.ok) {
        const responseToCache = response.clone();
        responseToCache.headers.set('sw-cached-date', new Date().toISOString());
        await cache.put(endpoint, responseToCache);
      }
    } catch (error) {
      console.log('[SW] Failed to update critical data for:', endpoint);
    }
  }
}

// Handle messages from clients
self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data?.type === 'GET_AUTH_TOKEN') {
    // Respond with auth token if available
    event.ports[0].postMessage({
      token: null // Would be retrieved from storage
    });
  }
  
  if (event.data?.type === 'CACHE_UPDATE') {
    // Force update specific cache entries
    event.waitUntil(updateCacheEntry(event.data.url));
  }
});

async function updateCacheEntry(url) {
  try {
    const response = await fetch(url);
    if (response.ok) {
      const cache = await caches.open(API_CACHE);
      const responseToCache = response.clone();
      responseToCache.headers.set('sw-cached-date', new Date().toISOString());
      await cache.put(url, responseToCache);
    }
  } catch (error) {
    console.error('[SW] Failed to update cache entry:', url, error);
  }
}

console.log('[SW] Service worker script loaded');