from fastapi import APIRouter
from app.services.anomaly import detect_anomalies
from app.services.cache import get_cached, set_cached

router = APIRouter()


@router.get("/api/anomali/{symbol}")
async def anomali(symbol: str):
    key = f"anomali:{symbol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await detect_anomalies(symbol)
    await set_cached(key, data, ttl=30)
    return data
