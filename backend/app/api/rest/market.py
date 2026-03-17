"""
Piyasa REST endpoint'leri.
Binance spot + futures verilerini önbellekleyerek sunar.
"""
import asyncio
import httpx
from fastapi import APIRouter
from app.services.cache import get_cached, set_cached

router = APIRouter()

BINANCE_API = "https://fapi.binance.com/fapi/v1"
BINANCE_FAPI = "https://fapi.binance.com/fapi/v1"

IZLENEN_SEMBOLLER = [
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'ZECUSDT', 'DOGEUSDT', '1000PEPEUSDT', 'BNXUSDT', 'BNBUSDT', 'TAOUSDT', 'ANIMEUSDT', 'POLYXUSDT', 'ASTERUSDT', 'DEGOUSDT', 'ADAUSDT', 'SUIUSDT', 'TRUMPUSDT', 'AVAXUSDT', 'NEARUSDT', 'LINKUSDT', 'DOTUSDT', 'CFGUSDT', 'VANRYUSDT', 'FETUSDT', 'FILUSDT', 'PAXGUSDT', 'VIDTUSDT', 'SXPUSDT', 'AGIXUSDT', 'LTCUSDT', 'WLDUSDT', 'LINAUSDT', 'MEMEFIUSDT', 'ENAUSDT', 'LEVERUSDT', 'NEIROETHUSDT', 'FTMUSDT', 'BCHUSDT', 'PIXELUSDT', 'CRCLUSDT', 'XPLUSDT', 'TRXUSDT', 'WAVESUSDT', 'AAVEUSDT', 'WIFUSDT', 'UNIUSDT', 'OMNIUSDT', 'YALAUSDT', 'AMBUSDT', 'HYPERUSDT', 'TRIAUSDT', 'BSWUSDT', 'OCEANUSDT', 'BEATUSDT', 'STRAXUSDT', 'DASHUSDT', 'PENGUUSDT', 'RENUSDT', 'UNFIUSDT', 'OPNUSDT', 'VIRTUALUSDT', '1000SHIBUSDT', 'GRASSUSDT', 'RENDERUSDT', 'DGBUSDT', '1000BONKUSDT', 'TROYUSDT', 'HUMAUSDT', 'ARBUSDT', 'IRUSDT', 'XLMUSDT', 'BANUSDT', 'KITEUSDT', 'HBARUSDT', 'CRVUSDT', 'LITUSDT', 'XANUSDT', 'RVNUSDT', 'HIFIUSDT', 'APTUSDT', 'TLMUSDT', 'TSLAUSDT', 'OMUSDT', 'XMRUSDT', 'ICPUSDT', 'TONUSDT', 'ZENUSDT', 'SHIBUSDT', 'LDOUSDT', 'OPUSDT', 'MKRUSDT', 'AXSUSDT', 'SANDUSDT', 'MANAUSDT', 'FLOWUSDT', 'GALAUSDT', 'RUNEUSDT', 'INJUSDT', 'LQTYUSDT', 'RDNTUSDT'
]


async def _ticker_24h(sembol: str) -> dict | None:
    try:
        async with httpx.AsyncClient(timeout=6) as c:
            r = await c.get(f"{BINANCE_API}/ticker/24hr?symbol={sembol}")
            d = r.json()
            return {
                "sembol": sembol,
                "fiyat": float(d["lastPrice"]),
                "degisim_yuzde": round(float(d["priceChangePercent"]), 2),
                "degisim_usd": round(float(d["priceChange"]), 4),
                "hacim_usdt": round(float(d["quoteVolume"])),
                "yuksek_24h": float(d["highPrice"]),
                "dusuk_24h": float(d["lowPrice"]),
                "islem_sayisi": int(d["count"]),
            }
    except Exception:
        return None


async def _mini_kline(sembol: str, limit: int = 20) -> list[float]:
    """Küçük sparkline grafiği için son kapanış fiyatları."""
    try:
        async with httpx.AsyncClient(timeout=5) as c:
            r = await c.get(
                f"{BINANCE_API}/klines?symbol={sembol}&interval=1h&limit={limit}"
            )
            return [float(k[4]) for k in r.json()]
    except Exception:
        return []


@router.get("/api/piyasalar")
async def piyasalar():
    key = "piyasalar_listesi"
    cached = await get_cached(key)
    if cached:
        return cached

    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{BINANCE_API}/ticker/24hr")
            all_tickers = r.json()
    except Exception:
        all_tickers = []

    ticker_dict = {}
    if isinstance(all_tickers, list):
        for d in all_tickers:
            if d.get("symbol") in IZLENEN_SEMBOLLER:
                ticker_dict[d["symbol"]] = {
                    "sembol": d["symbol"],
                    "fiyat": float(d.get("lastPrice", 0)),
                    "degisim_yuzde": round(float(d.get("priceChangePercent", 0)), 2),
                    "degisim_usd": round(float(d.get("priceChange", 0)), 4),
                    "hacim_usdt": round(float(d.get("quoteVolume", 0))),
                    "yuksek_24h": float(d.get("highPrice", 0)),
                    "dusuk_24h": float(d.get("lowPrice", 0)),
                    "islem_sayisi": int(d.get("count", 0)),
                }

    sem = asyncio.Semaphore(15)

    async def _safe_mini_kline(s):
        async with sem:
            return s, await _mini_kline(s)

    kline_tasks = [_safe_mini_kline(s) for s in IZLENEN_SEMBOLLER]
    klines_results = await asyncio.gather(*kline_tasks)
    
    klines_dict = {k: v for k, v in klines_results}

    sonuc = []
    for s in IZLENEN_SEMBOLLER:
        if s in ticker_dict:
            t = ticker_dict[s]
            t["sparkline"] = klines_dict.get(s, [])
            sonuc.append(t)

    sonuc.sort(key=lambda x: x["hacim_usdt"], reverse=True)
    await set_cached(key, sonuc, ttl=30)
    return sonuc


@router.get("/api/piyasalar/{sembol}")
async def piyasa_detay(sembol: str):
    key = f"piyasa_detay:{sembol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached

    usdt = sembol.upper() + ("USDT" if not sembol.upper().endswith("USDT") else "")

    async def ticker():
        return await _ticker_24h(usdt)

    async def kline_1s():
        return await _mini_kline(usdt, 60)

    async def order_book():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"{BINANCE_API}/depth?symbol={usdt}&limit=10")
                d = r.json()
                return {
                    "alis": [[float(p), float(q)] for p, q in d["bids"][:5]],
                    "satis": [[float(p), float(q)] for p, q in d["asks"][:5]],
                }
        except Exception:
            return {"alis": [], "satis": []}

    t, k, ob = await asyncio.gather(ticker(), kline_1s(), order_book())
    if not t:
        return {"hata": "Sembol bulunamadı"}

    t["sparkline_1h"] = k
    t["order_book"] = ob
    await set_cached(key, t, ttl=5)
    return t


@router.get("/api/acik-faiz")
async def acik_faiz():
    key = "acik_faiz"
    cached = await get_cached(key)
    if cached:
        return cached

    try:
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.get(f"{BINANCE_FAPI}/openInterest?symbol=BTCUSDT")
            btc = r.json()
            r2 = await c.get(f"{BINANCE_FAPI}/openInterest?symbol=ETHUSDT")
            eth = r2.json()

        data = {
            "btc": {
                "acik_faiz": float(btc["openInterest"]),
                "sembol": "BTCUSDT",
            },
            "eth": {
                "acik_faiz": float(eth["openInterest"]),
                "sembol": "ETHUSDT",
            },
        }
        await set_cached(key, data, ttl=30)
        return data
    except Exception:
        return {"hata": "Açık faiz verisi alınamadı"}


@router.get("/api/fonlama")
async def fonlama_oranlari():
    key = "fonlama_oranlari"
    cached = await get_cached(key)
    if cached:
        return cached

    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(f"{BINANCE_FAPI}/premiumIndex")
            data = r.json()
            
            sonuclar = []
            if isinstance(data, list):
                for d in data:
                    if d.get("symbol") in IZLENEN_SEMBOLLER:
                        sonuclar.append({
                            "sembol": d["symbol"],
                            "oran": round(float(d.get("lastFundingRate", 0)) * 100, 6),
                            "sonraki_fonlama": int(d.get("nextFundingTime", 0)),
                        })
            
            sonuclar.sort(key=lambda x: abs(x["oran"]), reverse=True)
            await set_cached(key, sonuclar, ttl=60)
            return sonuclar
    except Exception:
        return []


@router.get("/api/likidasyonlar")
async def likidasyonlar():
    key = "likidasyonlar"
    cached = await get_cached(key)
    if cached:
        return cached

    try:
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.get(
                f"{BINANCE_FAPI}/allForceOrders?symbol=BTCUSDT&limit=50"
            )
            orders = r.json()

        sonuc = []
        for o in orders:
            sonuc.append({
                "sembol": o["symbol"],
                "taraf": "LONG" if o["side"] == "SELL" else "SHORT",
                "miktar": float(o["origQty"]),
                "fiyat": float(o["price"]),
                "zaman": int(o["time"]),
            })

        await set_cached(key, sonuc, ttl=15)
        return sonuc
    except Exception:
        return []
