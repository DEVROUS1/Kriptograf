from fastapi import APIRouter
from app.services.cvd import get_cvd_data
from app.services.cache import get_cached, set_cached

router = APIRouter()

@router.get("/api/cvd/{symbol}")
async def cvd_endpoint(symbol: str, interval: str = "1m"):
    key = f"cvd:{symbol}:{interval}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_cvd_data(symbol, interval)
    await set_cached(key, data, ttl=10)
    return data
