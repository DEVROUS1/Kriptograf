from fastapi import APIRouter
from app.services.whale_tracker import get_whale_stats
from app.services.cache import get_cached, set_cached

router = APIRouter()

@router.get("/api/balinalar/{symbol}")
async def whale_endpoint(symbol: str = "BTCUSDT"):
    key = f"whale:{symbol}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_whale_stats(symbol)
    await set_cached(key, data, ttl=15)  # 15 saniye önbellek
    return data
