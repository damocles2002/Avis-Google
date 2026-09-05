// ============================================================
// 🔧 SERVICE WORKER — mode hors-ligne + TOUJOURS à jour
// Stratégie : réseau d'abord (network-first), cache en secours.
// Ainsi, quand le téléphone est en ligne, il récupère la DERNIÈRE
// version du site (tous les boutons à jour). Hors-ligne → cache.
// ============================================================
const CACHE_NAME = 'damavis-v2';

// Installation
self.addEventListener('install', (e) => {
  self.skipWaiting();
});

// Activation : nettoyer les anciens caches
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Récupération : réseau d'abord, cache si hors-ligne
self.addEventListener('fetch', (e) => {
  // Ignorer les appels API (Supabase) et les méthodes non-GET
  if (e.request.method !== 'GET' || e.request.url.includes('supabase.co')) return;
  e.respondWith(
    fetch(e.request)
      .then((res) => {
        // Mettre à jour le cache avec la version fraîche
        const clone = res.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(e.request, clone));
        return res;
      })
      .catch(() => caches.match(e.request)) // hors-ligne → cache
  );
});
