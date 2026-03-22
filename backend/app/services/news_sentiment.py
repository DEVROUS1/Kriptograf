import httpx
import feedparser
import asyncio
import urllib.parse
from datetime import datetime

HABER_KAYNAKLARI = [
    "https://tr.investing.com/rss/news_301.rss",
    "https://cryptopanic.com/news/rss/",
    "https://cointelegraph.com/rss",
    "https://feeds.feedburner.com/CoinDesk"
]

POZITIF = [
    "yükseliş", "artış", "rekor", "büyüme", "kazan", "bull", "surge",
    "rally", "gain", "bullish", "rise", "high", "pump", "growth", "adoption",
]
NEGATIF = [
    "düşüş", "kayıp", "çöküş", "ban", "hack", "bear", "crash", "drop",
    "fall", "bearish", "loss", "low", "dump", "scam", "fraud", "sell-off",
]


def _duygu(baslik: str) -> str:
    b = baslik.lower()
    poz = sum(1 for k in POZITIF if k in b)
    neg = sum(1 for k in NEGATIF if k in b)
    if poz > neg:
        return "POZİTİF"
    if neg > poz:
        return "NEGATİF"
    return "NÖTR"


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

async def _fetch_feed(url: str) -> list[dict]:
    try:
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.get(url, headers={"User-Agent": "Mozilla/5.0"})
        feed = feedparser.parse(r.text)
        
        results = []
        for e in feed.entries[:5]:
            baslik = e.get("title", "")
            if "investing" not in url.lower():
                baslik = await _translate_to_tr(baslik)
                
            results.append({
                "baslik": baslik,
                "link": e.get("link", ""),
                "kaynak": feed.feed.get("title", url.split("/")[2]),
                "zaman": e.get("published", ""),
                "duygu": _duygu(baslik),
            })
        return results
    except Exception:
        return []


async def get_news_with_sentiment() -> dict:
    feeds = await asyncio.gather(*[_fetch_feed(u) for u in HABER_KAYNAKLARI])
    haberler = [h for f in feeds for h in f]

    pozitif = sum(1 for h in haberler if h["duygu"] == "POZİTİF")
    negatif = sum(1 for h in haberler if h["duygu"] == "NEGATİF")
    toplam = len(haberler) or 1
    poz_yuzde = round((pozitif / toplam) * 100)

    if poz_yuzde >= 60:
        genel = "OLUMLU"
    elif poz_yuzde <= 40:
        genel = "OLUMSUZ"
    else:
        genel = "KARISIK"

    return {
        "haberler": haberler[:20],
        "istatistik": {
            "toplam": toplam,
            "pozitif": pozitif,
            "negatif": negatif,
            "pozitif_yuzde": poz_yuzde,
            "genel_duygu": genel,
        },
        "guncelleme": datetime.now().strftime("%H:%M"),
    }
