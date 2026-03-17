import httpx
from datetime import datetime

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"


async def _piyasa_verisi_topla(symbol: str) -> dict:
    usdt = symbol.upper() + "USDT"
    async with httpx.AsyncClient(timeout=10) as c:
        ticker = await c.get(f"https://api.binance.com/api/v3/ticker/24hr?symbol={usdt}")
        klines = await c.get(
            f"https://api.binance.com/api/v3/klines?symbol={usdt}&interval=4h&limit=50"
        )
        try:
            fg = await c.get("https://api.alternative.me/fng/?limit=1")
            fear = int(fg.json()["data"][0]["value"])
        except Exception:
            fear = 50

    t = ticker.json()
    k = klines.json()
    closes = [float(x[4]) for x in k]
    highs = [float(x[2]) for x in k]
    lows = [float(x[3]) for x in k]

    fiyat = float(t["lastPrice"])
    degisim = float(t["priceChangePercent"])
    hacim = float(t["quoteVolume"])

    # RSI hesapla
    gains = [max(closes[i] - closes[i-1], 0) for i in range(1, 15)]
    losses = [abs(min(closes[i] - closes[i-1], 0)) for i in range(1, 15)]
    ag = sum(gains) / 14
    al = (sum(losses) / 14) or 0.001
    rsi = round(100 - (100 / (1 + ag / al)), 1)

    # ATR
    trs = [max(highs[i] - lows[i], abs(highs[i] - closes[i-1]),
               abs(lows[i] - closes[i-1])) for i in range(1, 15)]
    atr = sum(trs) / 14
    atr_yuzde = round(atr / fiyat * 100, 2)

    # Trend
    ema20 = sum(closes[-20:]) / 20
    trend = "yükseliş" if fiyat > ema20 else "düşüş"

    # Son 20 mumun high/low
    son_high = max(highs[-20:])
    son_low = min(lows[-20:])

    return {
        "fiyat": fiyat,
        "degisim_24h": degisim,
        "hacim_usdt": round(hacim),
        "rsi": rsi,
        "atr_yuzde": atr_yuzde,
        "trend": trend,
        "ema20": round(ema20, 2),
        "son_high": round(son_high, 2),
        "son_low": round(son_low, 2),
        "fear_greed": fear,
    }


async def senaryo_analizi(symbol: str, api_key: str) -> dict:
    veri = await _piyasa_verisi_topla(symbol)

    prompt = f"""Sen dünya sınıfında bir kripto para analistisisin. {symbol} için aşağıdaki verileri analiz et ve tam olarak 3 senaryo üret. JSON formatında yanıt ver, başka hiçbir şey yazma.

VERİ:
- Fiyat: ${veri['fiyat']:,.2f}
- 24s Değişim: {veri['degisim_24h']:+.2f}%
- RSI: {veri['rsi']}
- ATR: %{veri['atr_yuzde']} (volatilite)
- Trend: {veri['trend']} (EMA20: ${veri['ema20']:,.2f})
- 20 mum High: ${veri['son_high']:,.2f}
- 20 mum Low: ${veri['son_low']:,.2f}
- Korku/Açgözlülük: {veri['fear_greed']}/100

Şu JSON formatını kullan:
{{
  "boga": {{
    "baslik": "kısa başlık",
    "ihtimal": 45,
    "hedef": 75000,
    "tetikleyici": "bu senaryoyu tetikleyecek şey",
    "aciklama": "2 cümle açıklama"
  }},
  "ayi": {{
    "baslik": "kısa başlık",
    "ihtimal": 35,
    "hedef": 65000,
    "tetikleyici": "bu senaryoyu tetikleyecek şey",
    "aciklama": "2 cümle açıklama"
  }},
  "yatay": {{
    "baslik": "kısa başlık",
    "ihtimal": 20,
    "aralik_ust": 72000,
    "aralik_alt": 68000,
    "aciklama": "2 cümle açıklama"
  }},
  "genel_yorum": "Piyasa hakkında tek cümlelik genel yorum",
  "kritik_seviye": 70000
}}

Türkçe yaz. İhtimallerin toplamı 100 olsun. Gerçekçi fiyat hedefleri ver."""

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    body = {
        "model": GROQ_MODEL,
        "max_tokens": 600,
        "temperature": 0.3,
        "messages": [
            {"role": "system", "content": "Kripto para analisti. Sadece JSON yanıt ver."},
            {"role": "user", "content": prompt},
        ],
        "response_format": {"type": "json_object"},
    }

    async with httpx.AsyncClient(timeout=20) as c:
        r = await c.post(GROQ_API_URL, json=body, headers=headers)
        r.raise_for_status()
        import json
        icerik = r.json()["choices"][0]["message"]["content"]
        senaryolar = json.loads(icerik)

    return {
        "senaryolar": senaryolar,
        "piyasa_verisi": veri,
        "sembol": symbol.upper(),
        "olusturulma": datetime.now().strftime("%H:%M"),
    }
