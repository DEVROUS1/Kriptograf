import random
from app.services.fear_greed import get_fear_and_greed
from app.services.cache import get_cache, set_cache

async def calculate_stress_index():
    cache_key = "stress_index"
    cached = await get_cache(cache_key)
    if cached: return cached
    
    fng_data = await get_fear_and_greed()
    fng_val = fng_data[0]["value"] if fng_data else 50
    
    volatility = random.uniform(30, 80)
    volume_anomaly = random.uniform(20, 70)
    
    fng_stress = abs(fng_val - 50) * 2
    
    stress_score = (volatility * 0.40) + (fng_stress * 0.30) + (volume_anomaly * 0.30)
    score_int = int(min(max(stress_score, 0), 100))
    
    label = "STABIL"
    if score_int >= 60:
        label = "KRİTİK"
    elif score_int >= 30:
        label = "DİKKATLİ"
        
    result = {
        "score": score_int,
        "label": label,
        "components": {
            "volatility": int(volatility),
            "fear_greed_stress": int(fng_stress),
            "volume_anomaly": int(volume_anomaly)
        }
    }
    
    await set_cache(cache_key, result, expire=60)
    return result
