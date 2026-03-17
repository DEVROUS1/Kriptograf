import httpx

async def get_orderbook_heatmap(symbol: str = "BTCUSDT", depth: int = 50) -> dict:
    """
    Binance order book derinliğini alır.
    Alış ve satış duvarlarını yoğunluk değerleriyle döner.
    """
    url = f"https://api.binance.com/api/v3/depth?symbol={symbol.upper()}&limit={depth}"
    async with httpx.AsyncClient() as client:
        r = await client.get(url)
        data = r.json()

    bids = [[float(p), float(q)] for p, q in data["bids"]]
    asks = [[float(p), float(q)] for p, q in data["asks"]]

    # En büyük duvarları bul
    max_bid_qty = max(q for _, q in bids) if bids else 1
    max_ask_qty = max(q for _, q in asks) if asks else 1

    return {
        "alis_duvarlari": [
            {"fiyat": p, "miktar": q, "yogunluk": round(q / max_bid_qty * 100)}
            for p, q in sorted(bids, key=lambda x: x[1], reverse=True)[:10]
        ],
        "satis_duvarlari": [
            {"fiyat": p, "miktar": q, "yogunluk": round(q / max_ask_qty * 100)}
            for p, q in sorted(asks, key=lambda x: x[1], reverse=True)[:10]
        ],
        "en_guclu_destek": min(bids, key=lambda x: x[0])[0] if bids else 0,
        "en_guclu_direnc": min(asks, key=lambda x: x[0])[0] if asks else 0,
    }
