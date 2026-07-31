// NightCompare service worker
// Strateji: HTML için "önce ağ" (deploy'lar anında görünsün, cache eski sürümü
// asla kilitlemesin), statik varlıklar için "önce cache". Supabase gibi farklı
// origin'lere giden istekler hiç ellenmez — hep canlı veri.

const CACHE = 'nightcompare-v1';
const SHELL = ['./', './index.html', './icon.svg', './manifest.json'];

self.addEventListener('install', (e)=>{
  e.waitUntil(
    caches.open(CACHE)
      .then(c=>c.addAll(SHELL).catch(()=>{ /* biri 404 olursa kurulum patlamasın */ }))
      .then(()=>self.skipWaiting())
  );
});

self.addEventListener('activate', (e)=>{
  e.waitUntil(
    caches.keys()
      .then(keys=>Promise.all(keys.filter(k=>k !== CACHE).map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener('fetch', (e)=>{
  const req = e.request;
  if(req.method !== 'GET') return;

  let url;
  try { url = new URL(req.url); } catch(_){ return; }
  // Supabase (auth, veri, realtime, storage) ve diğer dış kaynaklar: dokunma.
  if(url.origin !== self.location.origin) return;

  // Sayfa istekleri: önce ağ, çevrimdışıysa son başarılı kopya.
  if(req.mode === 'navigate' || req.destination === 'document'){
    e.respondWith(
      fetch(req)
        .then(res=>{
          const copy = res.clone();
          caches.open(CACHE).then(c=>c.put('./index.html', copy)).catch(()=>{});
          return res;
        })
        .catch(()=>caches.match('./index.html').then(hit=>hit || Response.error()))
    );
    return;
  }

  // Statik varlıklar: önce cache, yoksa ağdan al ve sakla.
  e.respondWith(
    caches.match(req).then(hit=>{
      if(hit) return hit;
      return fetch(req).then(res=>{
        if(res && res.ok && res.type === 'basic'){
          const copy = res.clone();
          caches.open(CACHE).then(c=>c.put(req, copy)).catch(()=>{});
        }
        return res;
      });
    })
  );
});
