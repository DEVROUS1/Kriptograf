import asyncio
import httpx

async def get_exchange_spread(symbol: str = "BTC") -> dict:
    """
    Binance, Bybit, OKX fiyatlarını paralel çeker.
    Aralarındaki spread ve arbitraj fırsatını hesaplar.
    """
    usdt_symbol = f"{symbol.upper()}USDT"

    async def binance_price():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={usdt_symbol}")
                return ("Binance", float(r.json()["price"]))
        except Exception:
            return ("Binance", None)

    async def bybit_price():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"https://api.bybit.com/v5/market/tickers?category=spot&symbol={usdt_symbol}")
                return ("Bybit", float(r.json()["result"]["list"][0]["lastPrice"]))
        except Exception:
            return ("Bybit", None)

    async def okx_price():
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"https://www.okx.com/api/v5/market/ticker?instId={symbol.upper()}-USDT")
                return ("OKX", float(r.json()["data"][0]["last"]))
        except Exception:
            return ("OKX", None)

    results = await asyncio.gather(binance_price(), bybit_price(), okx_price())
    prices = {name: price for name, price in results if price is not None}

    if len(prices) < 2:
        return {"borsalar": prices, "spread": 0, "firsat": False}

    en_ucuz_borsa = min(prices, key=prices.get)
    en_pahali_borsa = max(prices, key=prices.get)
    spread = prices[en_pahali_borsa] - prices[en_ucuz_borsa]
    spread_yuzde = (spread / prices[en_ucuz_borsa]) * 100

    return {
        "borsalar": {k: round(v, 2) for k, v in prices.items()},
        "en_ucuz": en_ucuz_borsa,
        "en_pahali": en_pahali_borsa,
        "spread_usd": round(spread, 2),
        "spread_yuzde": round(spread_yuzde, 4),
        "firsat": spread_yuzde > 0.1,  # %0.1 üzeri arbitraj fırsatı
    }
