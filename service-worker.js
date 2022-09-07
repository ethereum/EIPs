// The cache identifier. Change this whenever the caching strategy changes.
const cacheName = 'EIP-cache-v1';

self.addEventListener('fetch', (event) => {
  event.respondWith(async () => {
    // Fetch cached response
    let cache = await caches.open(cacheName);
    let cachedResponse = await cache.match(event.request);
    
    // Start networked response
    let networkResponsePromise = fetch(event.request);
    
    // Cache networked response
    networkResponsePromise.then((networkResponse) => {
        cache.put(event.request, networkResponse.clone());
    });
    
    // Return cached response if available, otherwise wait for network response
    return cachedResponse || await networkResponsePromise;
  }));
});
