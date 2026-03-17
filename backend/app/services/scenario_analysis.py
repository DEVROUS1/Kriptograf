import httpx
from datetime import datetime

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"


async def _piyasa_verisi_topla(symbol: str) -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"
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
    
    if "lastPrice" not in t:
        fiyat, degisim, hacim = 0.0, 0.0, 0.0
    else:
        fiyat = float(t.get("lastPrice", 0.0))
        degisim = float(t.get("priceChangePercent", 0.0))
        hacim = float(t.get("quoteVolume", 0.0))
        
    if not isinstance(k, list) or len(k) == 0:
        closes = [0.0] * 50
        highs = [0.0] * 50
        lows = [0.0] * 50
    else:
        closes = [float(x[4]) for x in k]
        highs = [float(x[2]) for x in k]
        lows = [float(x[3]) for x in k]

    # RSI hesapla
    gains = [max(closes[i] - closes[i-1], 0) for i in range(1, 15)]
    losses = [abs(min(closes[i] - closes[i-1], 0)) for i in range(1, 15)]
    ag = sum(gains) / 14
    al = (sum(losses) / 14) or 0.001
    rsi = round(100 - (100 / (1 + ag / al)), 1)

    # ATR
    trs = [max(highs[i] - lows[i], abs(highs[i] - closes[i-1]),
               abs(lows[i] - closes[i-1])) for i in range(1, 15)]
    atr = sum(trs) / 14 if len(trs) >= 14 else 0.0
    atr_yuzde = round(atr / fiyat * 100, 2) if fiyat != 0.0 else 0.0

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

    prompt = f"""Sen dünya sınıfında bir kripto para analistisisin. ŞU ANKİ GERÇEK {symbol} FİYATI: ${veri['fiyat']:,.6f}
Aşağıdaki verileri analiz et ve tam olarak 3 senaryo üret. Hedef fiyatları belirlerken MUTLAKA şu anki fiyatı (${veri['fiyat']:,.6f}) baz al.
JSON formatında yanıt ver, başka hiçbir şey yazma.

VERİ:
- Sembol: {symbol}
- Mevcut Fiyat: ${veri['fiyat']:,.6f}
- 24s Değişim: {veri['degisim_24h']:+.2f}%
- RSI: {veri['rsi']}
- ATR: %{veri['atr_yuzde']} (volatilite)
- Trend: {veri['trend']} (EMA20: ${veri['ema20']:,.6f})
- 20 mum High: ${veri['son_high']:,.6f}
- 20 mum Low: ${veri['son_low']:,.6f}
- Korku/Açgözlülük: {veri['fear_greed']}/100

Şu JSON formatını kullan:
{{
  "boga": {{
    "baslik": "kısa başlık",
    "ihtimal": 45,
    "hedef": 123.45,
    "tetikleyici": "bu senaryoyu tetikleyecek şey",
    "aciklama": "2 cümle açıklama"
  }},
  "ayi": {{
    "baslik": "kısa başlık",
    "ihtimal": 35,
    "hedef": 100.10,
    "tetikleyici": "bu senaryoyu tetikleyecek şey",
    "aciklama": "2 cümle açıklama"
  }},
  "yatay": {{
    "baslik": "kısa başlık",
    "ihtimal": 20,
    "aralik_ust": 115.00,
    "aralik_alt": 105.00,
    "aciklama": "2 cümle açıklama"
  }},
  "genel_yorum": "Piyasa hakkında tek cümlelik genel yorum",
  "kritik_seviye": 110.00
}}

ÖNEMLİ KURALLAR:
1. Türkçe yaz ve sadece JSON nesnesi döndür.
2. Örnekteki rakamları (123.45, 75000 vb.) KOPYALAMA. Kendi analizine göre hedefler belirle.
3. İhtimallerin toplamı tam olarak 100 olmalıdır.
4. "hedef", "aralik_ust", "aralik_alt" ve "kritik_seviye" fiyatlarını belirlerken KESİNLİKLE ŞU ANKİ GÜNCEL FİYATI (${veri['fiyat']:,.6f}) BAZ AL! (Örneğin düşük bir altcoin için binlerce dolar hedef verme)."""

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

    try:
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.post(GROQ_API_URL, json=body, headers=headers)
            r.raise_for_status()
            import json
            icerik = r.json()["choices"][0]["message"]["content"]
            senaryolar = json.loads(icerik)
    except Exception as e:
        senaryolar = {
            "boga": {"baslik": "Hata", "ihtimal": 0, "hedef": 0, "tetikleyici": "-", "aciklama": "Veri çekilemedi."},
            "ayi": {"baslik": "Hata", "ihtimal": 0, "hedef": 0, "tetikleyici": "-", "aciklama": "Veri çekilemedi."},
            "yatay": {"baslik": "Hata", "ihtimal": 0, "aralik_ust": 0, "aralik_alt": 0, "aciklama": f"AI Analizi Hatası: {e}"},
            "genel_yorum": "AI bağlantı veya limit sorunu yaşanıyor.",
            "kritik_seviye": 0
        }

    return {
        "senaryolar": senaryolar,
        "piyasa_verisi": veri,
        "sembol": symbol.upper(),
        "olusturulma": datetime.now().strftime("%H:%M"),
    }
