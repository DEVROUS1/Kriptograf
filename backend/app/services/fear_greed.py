import httpx
from app.services.cache import get_cache, set_cache

async def get_fear_and_greed():
    cache_key = "fear_and_greed"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get("https://api.alternative.me/fng/?limit=7")
            data = resp.json()
            results = []
            for item in data["data"]:
                val = int(item["value"])
                label = "NÖTR"
                if val <= 20: label = "AŞIRI KORKU"
                elif val <= 40: label = "KORKU"
                elif val >= 80: label = "AŞIRI AÇGÖZLÜLÜK"
                elif val >= 60: label = "AÇGÖZLÜLÜK"
                
                results.append({
                    "value": val,
                    "classification": label,
                    "timestamp": item["timestamp"]
                })
            await set_cache(cache_key, results, expire=3600)
            return results
        except Exception:
            return [{"value": 50, "classification": "NÖTR", "timestamp": "0"}]
