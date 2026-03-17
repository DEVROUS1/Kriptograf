import httpx
import math


async def hesapla_indikatorler(symbol: str = "BTCUSDT", interval: str = "1h") -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"

    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(
                f"https://fapi.binance.com/fapi/v1/klines"
                f"?symbol={usdt}&interval={interval}&limit=200"
            )
            r.raise_for_status()
            klines = r.json()
            if not isinstance(klines, list) or len(klines) < 50:
                raise ValueError("Veri yetersiz")
    except Exception:
        return {
            "sembol": symbol.upper(),
            "guncel": 0.0,
            "rsi": 50.0,
            "rsi_yorum": "Hata",
            "macd": {"deger": 0.0, "sinyal": 0.0, "histogram": 0.0},
            "bollinger": {
                "ust": 0.0, "orta": 0.0, "alt": 0.0,
                "genislik": 0.0,
                "pozisyon": "ORTA",
            },
            "stoch_rsi": {"k": 50.0, "d": 50.0, "yorum": "Hata"},
            "ema": {
                "ema20": 0.0, "ema50": 0.0, "ema100": 0.0, "ema200": 0.0,
                "trend": "BELIRSIZ",
            },
            "atr": {"deger": 0.0, "yuzde": 0.0},
            "cci": 0.0,
            "williams_r": 0.0,
            "obv_trend": "BELIRSIZ",
            "ichimoku": {
                "tenkan": 0.0, "kijun": 0.0, "senkou_a": 0.0, "senkou_b": 0.0,
                "bulut_rengi": "YOK", "fiyat_bulut_ustu": False
            },
            "genel_skor": 50,
            "genel_sinyal": "VERİ ALINAMADI",
        }

    closes = [float(k[4]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    volumes = [float(k[5]) for k in klines]
    guncel = closes[-1]

    def ema(data, period):
        if len(data) < period:
            return 0.0
        k = 2 / (period + 1)
        e = sum(data[:period]) / period
        for v in data[period:]:
            e = v * k + e * (1 - k)
        return e

    def sma(data, period):
        if len(data) < period:
            return 0.0
        return sum(data[-period:]) / period

    def stdev(data, period):
        if len(data) < period:
            return 0.0
        sl = data[-period:]
        mean = sum(sl) / period
        var = sum((x - mean) ** 2 for x in sl) / period
        return math.sqrt(var)

    def rsi(data, period=14):
        if len(data) < period + 1:
            return 50.0
        gains = [max(data[i] - data[i-1], 0) for i in range(1, period + 1)]
        losses = [abs(min(data[i] - data[i-1], 0)) for i in range(1, period + 1)]
        ag = sum(gains) / period
        al = sum(losses) / period or 0.001
        return round(100 - (100 / (1 + ag / al)), 2)

    def atr(highs, lows, closes, period=14):
        trs = []
        for i in range(1, len(closes)):
            tr = max(
                highs[i] - lows[i],
                abs(highs[i] - closes[i-1]),
                abs(lows[i] - closes[i-1]),
            )
            trs.append(tr)
        if len(trs) < period:
            return 0.0
        return sum(trs[-period:]) / period

    def stoch_rsi(closes, period=14, smooth=3):
        rsi_vals = []
        for i in range(period, len(closes)):
            rsi_vals.append(rsi(closes[i-period:i+1], period))
        if len(rsi_vals) < period:
            return 50.0, 50.0
        sl = rsi_vals[-period:]
        mn, mx = min(sl), max(sl)
        if mx == mn:
            return 50.0, 50.0
        k = (rsi_vals[-1] - mn) / (mx - mn) * 100
        d = sum([(rsi_vals[-i] - mn) / (mx - mn) * 100 for i in range(1, smooth + 1)]) / smooth
        return round(k, 2), round(d, 2)

    def cci(highs, lows, closes, period=20):
        if len(closes) < period:
            return 0.0
        tp = [(highs[i] + lows[i] + closes[i]) / 3 for i in range(len(closes))]
        tp_slice = tp[-period:]
        mean = sum(tp_slice) / period
        md = sum(abs(x - mean) for x in tp_slice) / period
        if md == 0:
            return 0.0
        return round((tp[-1] - mean) / (0.015 * md), 2)

    def williams_r(highs, lows, closes, period=14):
        if len(closes) < period:
            return -50.0
        h = max(highs[-period:])
        l = min(lows[-period:])
        if h == l:
            return -50.0
        return round((h - closes[-1]) / (h - l) * -100, 2)

    def ichimoku(highs, lows):
        def midpoint(h, l):
            return (max(h) + min(l)) / 2
        tenkan = midpoint(highs[-9:], lows[-9:]) if len(highs) >= 9 else 0
        kijun = midpoint(highs[-26:], lows[-26:]) if len(highs) >= 26 else 0
        senkou_a = (tenkan + kijun) / 2
        senkou_b = midpoint(highs[-52:], lows[-52:]) if len(highs) >= 52 else 0
        return {
            "tenkan": round(tenkan, 2),
            "kijun": round(kijun, 2),
            "senkou_a": round(senkou_a, 2),
            "senkou_b": round(senkou_b, 2),
            "bulut_rengi": "YESIL" if senkou_a > senkou_b else "KIRMIZI",
            "fiyat_bulut_ustu": guncel > max(senkou_a, senkou_b),
        }

    # MACD
    macd_val = ema(closes, 12) - ema(closes, 26)
    macd_sig = ema(closes[-9:], 9)
    macd_hist = macd_val - macd_sig

    # Bollinger Bands
    bb_mid = sma(closes, 20)
    bb_std = stdev(closes, 20)
    bb_ust = bb_mid + 2 * bb_std
    bb_alt = bb_mid - 2 * bb_std
    bb_genislik = (bb_ust - bb_alt) / bb_mid * 100 if bb_mid > 0 else 0

    # RSI
    rsi_val = rsi(closes)

    # Stochastic RSI
    stoch_k, stoch_d = stoch_rsi(closes)

    # ATR
    atr_val = atr(highs, lows, closes)
    atr_yuzde = atr_val / guncel * 100

    # OBV (On-Balance Volume)
    obv = 0.0
    for i in range(1, len(closes)):
        if closes[i] > closes[i-1]:
            obv += volumes[i]
        elif closes[i] < closes[i-1]:
            obv -= volumes[i]
    obv_trend = "YUKSELIS" if obv > 0 else "DUSUS"

    # Vortex göstergesi (trend yönü)
    vm_plus = sum(abs(highs[i] - lows[i-1]) for i in range(1, min(14, len(highs))))
    vm_minus = sum(abs(lows[i] - highs[i-1]) for i in range(1, min(14, len(highs))))
    vortex_yukari = vm_plus > vm_minus

    # Genel sinyal skoru
    skor = 50
    skor += 15 if rsi_val < 30 else (-15 if rsi_val > 70 else 0)
    skor += 10 if macd_hist > 0 else -10
    skor += 8 if guncel > bb_mid else -8
    skor += 8 if stoch_k < 20 else (-8 if stoch_k > 80 else 0)
    skor += 10 if vortex_yukari else -10
    skor = max(0, min(100, skor))

    if skor >= 75:
        genel = "GUCLU ALIS"
    elif skor >= 60:
        genel = "ALIS"
    elif skor >= 40:
        genel = "NOTR"
    elif skor >= 25:
        genel = "SATIS"
    else:
        genel = "GUCLU SATIS"

    return {
        "sembol": symbol.upper(),
        "guncel": guncel,
        "rsi": rsi_val,
        "rsi_yorum": "Asiri Satim" if rsi_val < 30 else ("Asiri Alim" if rsi_val > 70 else "Notr"),
        "macd": {"deger": round(macd_val, 4), "sinyal": round(macd_sig, 4), "histogram": round(macd_hist, 4)},
        "bollinger": {
            "ust": round(bb_ust, 2), "orta": round(bb_mid, 2), "alt": round(bb_alt, 2),
            "genislik": round(bb_genislik, 2),
            "pozisyon": "UST" if guncel > bb_ust else ("ALT" if guncel < bb_alt else "ORTA"),
        },
        "stoch_rsi": {"k": stoch_k, "d": stoch_d,
                      "yorum": "Asiri Satim" if stoch_k < 20 else ("Asiri Alim" if stoch_k > 80 else "Notr")},
        "ema": {
            "ema20": round(ema(closes, 20), 2),
            "ema50": round(ema(closes, 50), 2),
            "ema100": round(ema(closes, 100), 2),
            "ema200": round(ema(closes, 200), 2),
            "trend": "YUKSELIS" if closes[-1] > ema(closes, 50) else "DUSUS",
        },
        "atr": {"deger": round(atr_val, 4), "yuzde": round(atr_yuzde, 2)},
        "cci": round(cci(highs, lows, closes), 2),
        "williams_r": round(williams_r(highs, lows, closes), 2),
        "obv_trend": obv_trend,
        "ichimoku": ichimoku(highs, lows),
        "genel_skor": skor,
        "genel_sinyal": genel,
    }
