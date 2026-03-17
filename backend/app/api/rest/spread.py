from fastapi import APIRouter
from app.services.spread import get_exchange_spread
from app.services.cache import get_cached, set_cached

router = APIRouter()

@router.get("/api/spread/{symbol}")
async def spread_endpoint(symbol: str):
    key = f"spread:{symbol}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_exchange_spread(symbol)
    await set_cached(key, data, ttl=8)
    return data
