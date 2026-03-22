import httpx
import websockets
import asyncio
import json
from app.services.cache import get_cache, set_cache
from app.api.websocket.manager import ws_manager

BINANCE_FUTURES_API = "https://fapi.binance.com"
BINANCE_SPOT_API = "https://api.binance.com"
BINANCE_WS_URL = "wss://stream.binance.com:9443/ws"

async def get_top_markets():
    cache_key = "top_markets"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BINANCE_SPOT_API}/api/v3/ticker/24hr")
        data = resp.json()
        
        usdt_pairs = [d for d in data if d["symbol"].endswith("USDT")]
        sorted_pairs = sorted(usdt_pairs, key=lambda x: float(x["quoteVolume"]), reverse=True)[:50]
        
        results = []
        for pair in sorted_pairs:
            results.append({
                "symbol": pair["symbol"],
                "price": float(pair["lastPrice"]),
                "change_percent": float(pair["priceChangePercent"]),
                "volume": float(pair["quoteVolume"]),
                "high_24h": float(pair["highPrice"]),
                "low_24h": float(pair["lowPrice"]),
            })
            
        await set_cache(cache_key, results, expire=10)
        return results

async def get_market_detail(symbol: str):
    cache_key = f"market_detail_{symbol}"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BINANCE_SPOT_API}/api/v3/ticker/24hr", params={"symbol": symbol})
        data = resp.json()
        result = {
            "symbol": data["symbol"],
            "price": float(data["lastPrice"]),
            "change_percent": float(data["priceChangePercent"]),
            "volume": float(data["quoteVolume"]),
            "high_24h": float(data["highPrice"]),
            "low_24h": float(data["lowPrice"]),
        }
        await set_cache(cache_key, result, expire=10)
        return result

async def get_open_interest():
    cache_key = "open_interest_all"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BINANCE_FUTURES_API}/fapi/v1/openInterestHist", params={"symbol": "BTCUSDT", "period": "1d"})
        data = resp.json()
        result = [{"symbol": "BTCUSDT", "openInterest": d["sumOpenInterest"]} for d in data]
        await set_cache(cache_key, result, expire=60)
        return result

async def get_funding_rate():
    cache_key = "funding_rate_all"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BINANCE_FUTURES_API}/fapi/v1/premiumIndex")
        data = resp.json()
        result = [{"symbol": d["symbol"], "fundingRate": d["lastFundingRate"]} for d in data if d["symbol"].endswith("USDT")]
        await set_cache(cache_key, result, expire=60)
        return result

async def get_liquidations(symbol: str = "BTCUSDT", limit: int = 50):
    """Binance Futures zorla tasfiye emirleri (gerçek veri)."""
    cache_key = f"liquidations_{symbol}_{limit}"
    cached = await get_cache(cache_key)
    if cached:
        return cached

    try:
        async with httpx.AsyncClient(timeout=8) as client:
            r = await client.get(
                f"{BINANCE_FUTURES_API}/fapi/v1/allForceOrders",
                params={"symbol": symbol.upper(), "limit": limit},
            )
            r.raise_for_status()
            orders = r.json()

        result = [
            {
                "symbol": o["symbol"],
                "side": "LONG" if o["side"] == "SELL" else "SHORT",
                "amount": float(o["origQty"]),
                "price": float(o["price"]),
                "time": int(o["time"]),
            }
            for o in orders
        ]
        await set_cache(cache_key, result, expire=15)
        return result
    except Exception:
        return []

async def stream_kline(symbol: str, interval: str, room: str):
    ws_url = f"{BINANCE_WS_URL}/{symbol.lower()}@kline_{interval}"
    while True:
        try:
            async with websockets.connect(ws_url) as websocket:
                while str(room) in ws_manager.active_rooms and len(ws_manager.active_rooms[str(room)]) > 0:
                    message = await websocket.recv()
                    data = json.loads(message)
                    kline = data["k"]
                    payload = {
                        "symbol": data["s"],
                        "interval": kline["i"],
                        "open": float(kline["o"]),
                        "high": float(kline["h"]),
                        "low": float(kline["l"]),
                        "close": float(kline["c"]),
                        "is_closed": kline["x"],
                        "timestamp": kline["t"]
                    }
                    await ws_manager.broadcast(json.dumps(payload), room)
                break
        except Exception as e:
            await asyncio.sleep(5)

async def stream_markets(room: str):
    ws_url = f"{BINANCE_WS_URL}/!ticker@arr"
    while True:
        try:
            async with websockets.connect(ws_url) as websocket:
                while str(room) in ws_manager.active_rooms and len(ws_manager.active_rooms[str(room)]) > 0:
                    message = await websocket.recv()
                    data = json.loads(message)
                    payload = [
                        {
                            "symbol": d["s"],
                            "price": float(d["c"]),
                            "change_percent": float(d["P"]),
                            "volume": float(d.get("q", 0)),
                            "high_24h": float(d.get("h", 0)),
                            "low_24h": float(d.get("l", 0))
                        } for d in data if d["s"].endswith("USDT")
                    ][:50]
                    await ws_manager.broadcast(json.dumps(payload), room)
                break
        except Exception as e:
            await asyncio.sleep(5)
