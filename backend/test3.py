import asyncio, feedparser, httpx
from app.services.news_sentiment import _fetch_feed
async def r():
  res = await _fetch_feed('https://cointelegraph.com/rss')
  print('RESULT:', res)
asyncio.run(r())
