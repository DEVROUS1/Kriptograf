import feedparser
import httpx
import urllib.parse
from app.services.cache import get_cache, set_cache

async def _translate_to_tr(text: str) -> str:
    if not text:
        return text
    try:
        url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=tr&dt=t&q={urllib.parse.quote(text)}"
        async with httpx.AsyncClient(timeout=4) as c:
            r = await c.get(url)
            data = r.json()
            return "".join([i[0] for i in data[0] if i[0]])
    except Exception:
        return text

async def get_news(lang: str = "tr"):
    cache_key = f"crypto_news_{lang}"
    cached = await get_cache(cache_key)
    if cached:
        return cached

    news_list = []
    # Coindesk RSS as a reliable source
    feed = feedparser.parse("https://www.coindesk.com/arc/outboundfeeds/rss/")
    for entry in feed.entries[:10]:
        title = entry.title
        sentiment = "NÖTR"
        title_lower = title.lower()
        if any(word in title_lower for word in ["bull", "surge", "up", "high", "gain", "soar", "rally"]):
            sentiment = "POZİTİF"
        elif any(word in title_lower for word in ["bear", "crash", "down", "low", "drop", "plunge", "selloff"]):
            sentiment = "NEGATİF"

        translated_title = await _translate_to_tr(title)

        news_list.append({
            "title": translated_title,
            "url": entry.link,
            "source": "CoinDesk",
            "published_at": entry.published,
            "sentiment": sentiment
        })

    await set_cache(cache_key, news_list, expire=300) # 5 dk
    return news_list
