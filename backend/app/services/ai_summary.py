import httpx
from datetime import datetime

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"


async def generate_market_summary(
    symbol: str,
    price: float,
    change_24h: float,
    rsi: float | None,
    funding_rate: float | None,
    whale_pressure: str,
    fear_greed: int,
    api_key: str,
) -> dict:
    isaret = "+" if change_24h >= 0 else ""

    prompt = f"""Sen KriptoGraf Pro'nun AI analistisisin. Aşağıdaki gerçek zamanlı kripto piyasa verisini analiz et ve tam olarak 3 kısa Türkçe cümle yaz. Sadece cümleleri yaz, başlık veya açıklama ekleme. Tahmin yapma, sadece mevcut veriyi yorumla.

VERİ:
- Sembol: {symbol}
- Fiyat: ${price:,.2f}
- 24 saatlik değişim: {isaret}{change_24h:.2f}%
- RSI (14): {f'{rsi:.1f}' if rsi else 'Hesaplanıyor'}
- Fonlama oranı: {f'{funding_rate:.4f}%' if funding_rate else 'Veri yok'}
- Balina baskısı: {whale_pressure}
- Korku/Açgözlülük endeksi: {fear_greed}/100"""

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_MODEL,
        "max_tokens": 300,
        "temperature": 0.4,
        "messages": [
            {
                "role": "system",
                "content": (
                    "Sen bir kripto para piyasası analistisisin. "
                    "Türkçe, kısa ve net cümleler kurarsın. "
                    "Hiçbir zaman yatırım tavsiyesi vermezsin."
                ),
            },
            {"role": "user", "content": prompt},
        ],
    }

    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.post(GROQ_API_URL, json=body, headers=headers)
        r.raise_for_status()
        ozet = r.json()["choices"][0]["message"]["content"].strip()

    return {
        "ozet": ozet,
        "sembol": symbol,
        "olusturulma": datetime.now().strftime("%H:%M"),
        "model": GROQ_MODEL,
    }
