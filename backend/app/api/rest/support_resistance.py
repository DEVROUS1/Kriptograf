from fastapi import APIRouter
from app.services.support_resistance import hesapla_destek_direnc
from app.services.indicators_advanced import hesapla_indikatorler
from app.services.cache import get_cached, set_cached

router = APIRouter()


@router.get("/api/destek-direnc/{symbol}")
async def destek_direnc(symbol: str):
    key = f"sd:{symbol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await hesapla_destek_direnc(symbol)
    await set_cached(key, data, ttl=60)
    return data


@router.get("/api/indikatorler/{symbol}")
async def indikatorler(symbol: str, interval: str = "1h"):
    key = f"ind:{symbol.upper()}:{interval}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await hesapla_indikatorler(symbol, interval)
    await set_cached(key, data, ttl=30)
    return data
