import asyncio
import httpx
from fastapi import APIRouter, HTTPException
from app.services.ai_summary import generate_market_summary
from app.services.cache import get_cached, set_cached
from app.core.config import settings

router = APIRouter()


async def _piyasa_verisi(symbol: str) -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"

    async def fiyat():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"https://fapi.binance.com/fapi/v1/ticker/24hr?symbol={usdt}")
                d = r.json()
                if "lastPrice" not in d:
                    return 0.0, 0.0
                return float(d.get("lastPrice", 0.0)), float(d.get("priceChangePercent", 0.0))
        except Exception:
            return 0.0, 0.0

    async def fonlama():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(
                    f"https://fapi.binance.com/fapi/v1/fundingRate"
                    f"?symbol={usdt}&limit=1"
                )
                return float(r.json()[0]["fundingRate"]) * 100
        except Exception:
            return None

    async def korku():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get("https://api.alternative.me/fng/?limit=1")
                return int(r.json()["data"][0]["value"])
        except Exception:
            return 50

    async def rsi():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(
                    f"https://fapi.binance.com/fapi/v1/klines"
                    f"?symbol={usdt}&interval=1h&limit=15"
                )
            closes = [float(k[4]) for k in r.json()]
            gains = [max(closes[i] - closes[i-1], 0) for i in range(1, len(closes))]
            losses = [abs(min(closes[i] - closes[i-1], 0)) for i in range(1, len(closes))]
            ag = sum(gains) / len(gains) if gains else 0
            al = (sum(losses) / len(losses)) if losses else 0.001
            return round(100 - (100 / (1 + ag / al)), 1)
        except Exception:
            return None

    (price, change), fund, fg, rsi_val = await asyncio.gather(
        fiyat(), fonlama(), korku(), rsi()
    )
    return {"price": price, "change": change, "funding": fund, "fear_greed": fg, "rsi": rsi_val}


@router.get("/api/ai-ozet/{symbol}")
async def ai_ozet(symbol: str):
    if not settings.groq_api_key:
        return {
            "ozet": "Yapay zeka analisti kullanılmıyor. Lütfen sunucu ayarlarından (Render Environment Variables) GROQ_API_KEY değişkenini ekleyin.",
            "sembol": symbol.upper(),
            "olusturulma": "Şimdi",
            "model": "Sistem",
        }

    key = f"ai_ozet:{symbol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached

    veri = await _piyasa_verisi(symbol)
    try:
        result = await generate_market_summary(
            symbol=symbol.upper(),
            price=veri["price"],
            change_24h=veri["change"],
            rsi=veri["rsi"],
            funding_rate=veri["funding"],
            whale_pressure="ALIŞ",
            fear_greed=veri["fear_greed"],
            api_key=settings.groq_api_key,
        )
    except Exception as e:
        result = {
            "ozet": f"AI verisi oluşturulamadı: Lütfen API anahtarınızı (veya Groq limitlerinizi) kontrol edin. Detay: {str(e)}",
            "sembol": symbol.upper(),
            "olusturulma": "Hatali",
            "model": "Hata",
        }

    await set_cached(key, result, ttl=300)
    return result
