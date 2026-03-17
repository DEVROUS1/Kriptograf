import httpx
import feedparser
import asyncio
from datetime import datetime

HABER_KAYNAKLARI = [
    "https://feeds.feedburner.com/CoinDesk",
    "https://cointelegraph.com/rss",
    "https://www.cointurk.com/feed",
    "https://bitcoinhaber.net/feed",
    "https://kriptokoin.com/feed",
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


async def _fetch_feed(url: str) -> list[dict]:
    try:
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.get(url, headers={"User-Agent": "KriptoGraf/1.0"})
        feed = feedparser.parse(r.text)
        return [
            {
                "baslik": e.get("title", ""),
                "link": e.get("link", ""),
                "kaynak": feed.feed.get("title", url.split("/")[2]),
                "zaman": e.get("published", ""),
                "duygu": _duygu(e.get("title", "")),
            }
            for e in feed.entries[:5]
        ]
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
