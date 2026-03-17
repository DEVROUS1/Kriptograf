from fastapi import APIRouter
from app.services.news_aggregator import get_news

router = APIRouter(tags=["News"])

@router.get("/haberler")
async def read_news(lang: str = "tr"):
    return await get_news(lang)
