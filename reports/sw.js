// Service Worker for Dashboard Caching
const CACHE_NAME = 'gv-dashboard-v1';
const STATIC_ASSETS = [
  '/',
  '/dashboard.html',
  '/api/metrics/charts',
  '/api/live'
];

// Install event - cache static assets
self.addEventListener('install', function(event) {
  console.log('[SW] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('[SW] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .catch(function(err) {
        console.log('[SW] Cache failed:', err);
      })
  );
  self.skipWaiting();
});

// Activate event - clean old caches
self.addEventListener('activate', function(event) {
  console.log('[SW] Activating...');
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', function(event) {
  const request = event.request;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // API calls - network first, cache fallback
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(request)
        .then(function(response) {
          // Clone response for caching
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put(request, responseClone);
          });
          return response;
        })
        .catch(function() {
          // Return cached version if network fails
          return caches.match(request);
        })
    );
    return;
  }
  
  // Static assets - cache first, network fallback
  event.respondWith(
    caches.match(request)
      .then(function(response) {
        if (response) {
          console.log('[SW] Serving from cache:', url.pathname);
          return response;
        }
        
        return fetch(request)
          .then(function(response) {
            // Cache successful responses
            if (response.status === 200) {
              const responseClone = response.clone();
              caches.open(CACHE_NAME).then(function(cache) {
                cache.put(request, responseClone);
              });
            }
            return response;
          })
          .catch(function(err) {
            console.log('[SW] Fetch failed:', err);
            // Return offline page if available
            return caches.match('/offline.html');
          });
      })
  );
});

// Background sync for offline data
self.addEventListener('sync', function(event) {
  if (event.tag === 'refresh-dashboard') {
    event.waitUntil(
      fetch('/api/metrics/charts')
        .then(function(response) {
          return caches.open(CACHE_NAME).then(function(cache) {
            return cache.put('/api/metrics/charts', response);
          });
        })
    );
  }
});

// Push notifications (for critical alerts)
self.addEventListener('push', function(event) {
  const data = event.data ? event.data.json() : {};
  const title = data.title || 'Dashboard Alert';
  const options = {
    body: data.body || 'New alert from Gentle-Vanguard',
    icon: '/favicon.ico',
    badge: '/badge.png',
    tag: data.tag || 'dashboard-alert',
    requireInteraction: true
  };
  
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Notification click handler
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.openWindow('/dashboard.html')
  );
});
