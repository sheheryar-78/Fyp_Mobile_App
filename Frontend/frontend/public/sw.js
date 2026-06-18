// A minimal service worker to satisfy Chrome's PWA install requirement
self.addEventListener('install', (e) => {
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  return self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  // Having a fetch handler is required to trigger the native PWA install banner
  e.respondWith(fetch(e.request));
});
