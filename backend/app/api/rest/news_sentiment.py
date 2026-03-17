from fastapi import APIRouter
from app.services.news_sentiment import get_news_with_sentiment
from app.services.cache import get_cached, set_cached

router = APIRouter()


@router.get("/api/haber-duygu")
async def haber_duygu():
    key = "haber_duygu"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_news_with_sentiment()
    await set_cached(key, data, ttl=300)
    return data
