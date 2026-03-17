import httpx
from dataclasses import dataclass


async def hesapla_sinyal(symbol: str = "BTCUSDT") -> dict:
    usdt = symbol.upper() if symbol.upper().endswith("USDT") else symbol.upper() + "USDT"

    async with httpx.AsyncClient(timeout=10) as client:
        klines_r = await client.get(
            f"https://fapi.binance.com/fapi/v1/klines"
            f"?symbol={usdt}&interval=1h&limit=50"
        )
        ticker_r = await client.get(
            f"https://fapi.binance.com/fapi/v1/ticker/24hr?symbol={usdt}"
        )

    klines = klines_r.json()
    ticker = ticker_r.json()
    closes = [float(k[4]) for k in klines]
    volumes = [float(k[5]) for k in klines]

    puan = 50
    nedenler = []

    # ── RSI ────────────────────────────────────────────────────────────────
    gains = [max(closes[i] - closes[i - 1], 0) for i in range(1, 15)]
    losses = [abs(min(closes[i] - closes[i - 1], 0)) for i in range(1, 15)]
    avg_g = sum(gains) / 14
    avg_l = (sum(losses) / 14) or 0.001
    rsi = 100 - (100 / (1 + avg_g / avg_l))

    if rsi < 30:
        puan += 25
        nedenler.append(f"RSI {rsi:.0f} — Aşırı satım bölgesi")
    elif rsi < 45:
        puan += 12
        nedenler.append(f"RSI {rsi:.0f} — Satım bölgesine yakın")
    elif rsi > 70:
        puan -= 25
        nedenler.append(f"RSI {rsi:.0f} — Aşırı alım bölgesi")
    elif rsi > 60:
        puan -= 10
        nedenler.append(f"RSI {rsi:.0f} — Alım bölgesine yakın")

    # ── MACD ───────────────────────────────────────────────────────────────
    def ema(data, period):
        k = 2 / (period + 1)
        e = sum(data[:period]) / period
        for v in data[period:]:
            e = v * k + e * (1 - k)
        return e

    macd = ema(closes, 12) - ema(closes, 26)
    sinyal_line = ema(closes[-9:], 9)
    histogram = macd - sinyal_line

    if histogram > 0 and macd > 0:
        puan += 15
        nedenler.append("MACD histogramı pozitif — yükseliş momentumu")
    elif histogram < 0 and macd < 0:
        puan -= 15
        nedenler.append("MACD histogramı negatif — düşüş momentumu")

    # ── HACİM ANOMALİSİ ────────────────────────────────────────────────────
    ort_hacim = sum(volumes[-20:-1]) / 19
    son_hacim = volumes[-1]
    hacim_oran = son_hacim / ort_hacim if ort_hacim > 0 else 1

    if hacim_oran > 2.0:
        puan += 10
        nedenler.append(f"Hacim ortalamanın {hacim_oran:.1f}x üzerinde")
    elif hacim_oran < 0.5:
        puan -= 5
        nedenler.append("Hacim ortalamanın altında — düşük ilgi")

    # ── FİYAT MOMENTUM ─────────────────────────────────────────────────────
    degisim = float(ticker["priceChangePercent"])
    if degisim > 3:
        puan += 10
        nedenler.append(f"24s değişim +{degisim:.1f}% — güçlü yükseliş")
    elif degisim < -3:
        puan -= 10
        nedenler.append(f"24s değişim {degisim:.1f}% — güçlü düşüş")

    # ── SINIFLANDIRMA ──────────────────────────────────────────────────────
    puan = max(0, min(100, puan))
    if puan >= 75:
        yon, renk = "GÜÇLÜ ALIŞ", "guclu_alis"
    elif puan >= 60:
        yon, renk = "ALIŞ", "alis"
    elif puan >= 40:
        yon, renk = "NÖTR", "notr"
    elif puan >= 25:
        yon, renk = "SATIŞ", "satis"
    else:
        yon, renk = "GÜÇLÜ SATIŞ", "guclu_satis"

    return {
        "yon": yon,
        "guc": puan,
        "renk": renk,
        "rsi": round(rsi, 1),
        "macd": round(macd, 4),
        "hacim_anomali": round(hacim_oran, 2),
        "nedenler": nedenler,
        "sembol": symbol.upper(),
    }
