// ============================================================
// 🔧 SERVICE WORKER — permet l'installation + le mode hors-ligne
// ============================================================
const CACHE_NAME = 'damavis-v1';
const ASSETS = [
  './',
  './index.html',
  './avis.html',
  './login.html',
  './dashboard.html',
  './admin.html',
  './qrcode.html',
  './js/config.js',
  './js/supabase.js',
  './manifest.json'
];

// Installation : mettre en cache les fichiers principaux
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
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

// Récupération : servir depuis le cache (hors-ligne), sinon réseau
self.addEventListener('fetch', (e) => {
  // Ne pas mettre en cache les appels API Supabase
  if (e.request.url.includes('supabase.co')) return;
  e.respondWith(
    caches.match(e.request).then((cached) => cached || fetch(e.request))
  );
});
