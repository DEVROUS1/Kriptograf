"""
Piyasa REST endpoint'leri.
Binance spot + futures verilerini önbellekleyerek sunar.
"""
import asyncio
import httpx
from fastapi import APIRouter
from app.services.cache import get_cached, set_cached

router = APIRouter()

BINANCE_API = "https://api.binance.com/api/v3"
BINANCE_FAPI = "https://fapi.binance.com/fapi/v1"

IZLENEN_SEMBOLLER = [
    "BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT", "XRPUSDT",
    "ADAUSDT", "DOGEUSDT", "AVAXUSDT", "MATICUSDT", "DOTUSDT",
    "LINKUSDT", "UNIUSDT", "ATOMUSDT", "LTCUSDT", "BCHUSDT",
    "NEARUSDT", "FTMUSDT", "ALGOUSDT", "VETUSDT", "MANAUSDT",
    "SANDUSDT", "AXSUSDT", "THETAUSDT", "EGLDUSDT", "ICPUSDT",
    "FILUSDT", "AAVEUSDT", "MKRUSDT", "COMPUSDT", "YFIUSDT",
    "SUSHIUSDT", "CRVUSDT", "SNXUSDT", "RUNEUSDT", "INJUSDT",
    "APTUSDT", "ARBUSDT", "OPUSDT", "LDOUSDT", "STXUSDT",
    "BLURUSDT", "CFXUSDT", "HOOKUSDT", "MAGICUSDT", "HIGHUSDT",
    "FLMUSDT", "TRUUSDT", "LQTYUSDT", "RDNTUSDT", "AMBUSDT",
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

    # Paralel çek
    ticker_tasks = [_ticker_24h(s) for s in IZLENEN_SEMBOLLER]
    kline_tasks = [_mini_kline(s) for s in IZLENEN_SEMBOLLER]

    tickers, klines = await asyncio.gather(
        asyncio.gather(*ticker_tasks),
        asyncio.gather(*kline_tasks),
    )

    sonuc = []
    for ticker, sparkline in zip(tickers, klines):
        if ticker:
            ticker["sparkline"] = sparkline
            sonuc.append(ticker)

    sonuc.sort(key=lambda x: x["hacim_usdt"], reverse=True)
    await set_cached(key, sonuc, ttl=10)
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

    semboller = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT"]
    sonuclar = []

    async def _fonlama(sym: str):
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"{BINANCE_FAPI}/fundingRate?symbol={sym}&limit=1")
                d = r.json()[0]
                return {
                    "sembol": sym,
                    "oran": round(float(d["fundingRate"]) * 100, 6),
                    "sonraki_fonlama": int(d["nextFundingTime"]),
                }
        except Exception:
            return None

    results = await asyncio.gather(*[_fonlama(s) for s in semboller])
    sonuclar = [r for r in results if r]
    sonuclar.sort(key=lambda x: abs(x["oran"]), reverse=True)

    await set_cached(key, sonuclar, ttl=60)
    return sonuclar


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
