from fastapi import APIRouter
from app.services.orderbook import get_orderbook_heatmap
from app.services.cache import get_cached, set_cached

router = APIRouter()

@router.get("/api/derinlik/{symbol}")
async def orderbook_endpoint(symbol: str):
    key = f"orderbook:{symbol}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_orderbook_heatmap(symbol)
    await set_cached(key, data, ttl=5)
    return data
