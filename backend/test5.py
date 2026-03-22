import asyncio
from app.services.news_sentiment import get_news_with_sentiment
async def t():
  res = await get_news_with_sentiment()
  print(len(res['haberler']))
asyncio.run(t())
