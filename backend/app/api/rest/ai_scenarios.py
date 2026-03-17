from fastapi import APIRouter, HTTPException
from app.services.scenario_analysis import senaryo_analizi
from app.services.onchain import get_onchain_metrics
from app.services.cache import get_cached, set_cached
from app.core.config import settings

router = APIRouter()


@router.get("/api/senaryo/{symbol}")
async def senaryo(symbol: str):
    if not settings.groq_api_key:
        from datetime import datetime
        return {
            "senaryolar": {
                "boga": {"baslik": "Bekleniyor", "ihtimal": 0, "hedef": 0, "tetikleyici": "-", "aciklama": "GROQ_API_KEY eksik."},
                "ayi": {"baslik": "Bekleniyor", "ihtimal": 0, "hedef": 0, "tetikleyici": "-", "aciklama": "GROQ_API_KEY eksik."},
                "yatay": {"baslik": "Bekleniyor", "ihtimal": 0, "aralik_ust": 0, "aralik_alt": 0, "aciklama": "GROQ_API_KEY eksik."},
                "genel_yorum": "AI analizi yapılabilmesi için API anahtarı gerekiyor.",
                "kritik_seviye": 0
            },
            "piyasa_verisi": {},
            "sembol": symbol.upper(),
            "olusturulma": datetime.now().strftime("%H:%M")
        }
    key = f"senaryo:{symbol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await senaryo_analizi(symbol, settings.groq_api_key)
    await set_cached(key, data, ttl=900)  # 15 dakika
    return data


@router.get("/api/onchain")
async def onchain():
    key = "onchain_metrics"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_onchain_metrics()
    await set_cached(key, data, ttl=300)  # 5 dakika
    return data
