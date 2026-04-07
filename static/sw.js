// Cleanup service worker: unregisters itself and clears all caches
// so browsers that cached the old Gatsby-based PWA get cleaned up.
self.addEventListener('install', event => {
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map(key => caches.delete(key)));
    const clients = await self.clients.matchAll({ type: 'window' });
    await self.registration.unregister();
    for (const client of clients) {
      client.navigate(client.url);
    }
  })());
});
