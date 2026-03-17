import httpx
import statistics


async def detect_anomalies(symbol: str = "BTCUSDT") -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"
    anomaliler = []
    severity = "NORMAL"

    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(
                f"https://api.binance.com/api/v3/klines"
                f"?symbol={usdt}&interval=15m&limit=50"
            )
            r.raise_for_status()
        klines = r.json()
        if not isinstance(klines, list) or len(klines) < 20:
            raise ValueError("Insufficient data")
    except Exception:
        return {
            "anomaliler": [{"tip": "BİLGİ", "mesaj": "Anomali verisi çekilemedi", "siddet": "NORMAL"}],
            "siddet": "NORMAL",
            "anomali_var": False,
            "sembol": symbol.upper(),
        }

    closes = [float(k[4]) for k in klines]
    volumes = [float(k[5]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]

    # ── Hacim anomalisi ────────────────────────────────────────────────────
    ort = statistics.mean(volumes[:-1])
    std = statistics.stdev(volumes[:-1])
    z = (volumes[-1] - ort) / std if std > 0 else 0

    if z > 3:
        anomaliler.append({
            "tip": "HACİM",
            "mesaj": f"Hacim ortalamanın {volumes[-1]/ort:.1f}x üzerinde — olağandışı aktivite",
            "siddet": "KRİTİK",
        })
        severity = "KRİTİK"
    elif z > 2:
        anomaliler.append({
            "tip": "HACİM",
            "mesaj": f"Hacim normalin {volumes[-1]/ort:.1f}x üzerinde — dikkat",
            "siddet": "DİKKAT",
        })
        if severity == "NORMAL":
            severity = "DİKKAT"

    # ── Fiyat hareketi ─────────────────────────────────────────────────────
    hareket = abs(closes[-1] - closes[-2]) / closes[-2] * 100
    if hareket > 2:
        s = "KRİTİK" if hareket > 3 else "DİKKAT"
        anomaliler.append({
            "tip": "FİYAT",
            "mesaj": f"Son 15 dakikada %{hareket:.2f} fiyat hareketi",
            "siddet": s,
        })
        if s == "KRİTİK":
            severity = "KRİTİK"
        elif severity == "NORMAL":
            severity = "DİKKAT"

    # ── Volatilite sıkışması ───────────────────────────────────────────────
    araliklar = [highs[i] - lows[i] for i in range(-10, -1)]
    ort_aralik = statistics.mean(araliklar) if araliklar else 1
    if (highs[-1] - lows[-1]) < ort_aralik * 0.3:
        anomaliler.append({
            "tip": "SIKISMAN",
            "mesaj": "Volatilite %70 daraldı — büyük hareket yaklaşıyor olabilir",
            "siddet": "DİKKAT",
        })
        if severity == "NORMAL":
            severity = "DİKKAT"

    return {
        "anomaliler": anomaliler,
        "siddet": severity,
        "anomali_var": len(anomaliler) > 0,
        "sembol": symbol.upper(),
    }
