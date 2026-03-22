import asyncio, traceback, httpx, feedparser
from datetime import datetime
async def _f(url):
  try:
    async with httpx.AsyncClient(timeout=8) as c:
        r = await c.get(url, headers={'User-Agent': 'Mozilla/5.0'})
    f = feedparser.parse(r.text)
    print(url, len(f.entries))
  except Exception as e:
    print(url, 'ERROR:', e)
async def t():
  urls = ['https://feeds.feedburner.com/CoinDesk', 'https://cointelegraph.com/rss', 'https://www.cointurk.com/feed', 'https://bitcoinhaber.net/feed', 'https://kriptokoin.com/feed']
  await asyncio.gather(*[_f(u) for u in urls])
asyncio.run(t())
