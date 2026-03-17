/**
 * Cloudflare Worker — Render Cold Start Çözümü
 * Her 5 dakikada backend'i uyandırır.
 * Ayrıca /api/health endpoint'ini kontrol eder,
 * hata varsa Cloudflare loglarına yazar.
 */
export default {
  async scheduled(event, env, ctx) {
    const BACKEND_URL = env.BACKEND_URL || "https://kriptograf-backend.onrender.com";

    ctx.waitUntil(
      (async () => {
        try {
          const res = await fetch(`${BACKEND_URL}/api/health`, {
            method: "GET",
            headers: { "User-Agent": "KriptoGraf-Ping/1.0" },
            signal: AbortSignal.timeout(10000),
          });
          const data = await res.json();
          console.log(`[PING OK] status=${res.status} ai=${data.ai} connections=${data.connections}`);
        } catch (err) {
          console.error(`[PING FAIL] ${err.message}`);
        }
      })()
    );
  },

  // Ayrıca HTTP isteklerine de cevap ver (manuel test için)
  async fetch(request, env, ctx) {
    const BACKEND_URL = env.BACKEND_URL || "https://kriptograf-backend.onrender.com";

    try {
      const res = await fetch(`${BACKEND_URL}/api/health`, {
        signal: AbortSignal.timeout(10000),
      });
      const data = await res.json();
      return new Response(JSON.stringify({ ok: true, backend: data }), {
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      return new Response(JSON.stringify({ ok: false, error: err.message }), {
        status: 503,
        headers: { "Content-Type": "application/json" },
      });
    }
  },
};
