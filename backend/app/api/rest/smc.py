from fastapi import APIRouter
from app.services.smc_analysis import smc_analiz
from app.services.cache import get_cached, set_cached

router = APIRouter()

VALID_INTERVALS = {"15m", "1h", "4h", "1d"}


@router.get("/api/smc/{symbol}")
async def smc_endpoint(symbol: str, interval: str = "4h"):
    if interval not in VALID_INTERVALS:
        interval = "4h"
    key = f"smc:{symbol.upper()}:{interval}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await smc_analiz(symbol, interval)
    await set_cached(key, data, ttl=60)
    return data
