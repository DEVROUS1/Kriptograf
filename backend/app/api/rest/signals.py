from fastapi import APIRouter
from app.services.signal_engine import hesapla_sinyal
from app.services.cache import get_cached, set_cached

router = APIRouter()


@router.get("/api/sinyal/{symbol}")
async def sinyal(symbol: str):
    key = f"sinyal:{symbol.upper()}"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await hesapla_sinyal(symbol)
    await set_cached(key, data, ttl=30)
    return data
