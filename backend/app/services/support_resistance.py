import httpx
from dataclasses import dataclass

@dataclass
class Seviye:
    fiyat: float
    tip: str        # "DESTEK" | "DIRENC"
    guc: str        # "ZAYIF" | "ORTA" | "GUCLU" | "COK_GUCLU"
    dokunma: int    # kaç kez test edildi
    mesafe_yuzde: float  # güncel fiyattan uzaklık %


async def hesapla_destek_direnc(symbol: str = "BTCUSDT") -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"

    async with httpx.AsyncClient(timeout=10) as c:
        # 4 saatlik 200 mum — önemli seviyeleri bulmak için yeterli
        r = await c.get(
            f"https://fapi.binance.com/fapi/v1/klines"
            f"?symbol={usdt}&interval=4h&limit=200"
        )
        klines = r.json()
        # Güncel fiyat
        p = await c.get(f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={usdt}")
        guncel = float(p.json()["price"])

    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    closes = [float(k[4]) for k in klines]

    # Pivot noktaları bul (yerel tepe/dip)
    pivotler = []
    for i in range(2, len(klines) - 2):
        # Yerel tepe
        if highs[i] > highs[i-1] and highs[i] > highs[i-2] and \
           highs[i] > highs[i+1] and highs[i] > highs[i+2]:
            pivotler.append(("DIRENC", highs[i]))
        # Yerel dip
        if lows[i] < lows[i-1] and lows[i] < lows[i-2] and \
           lows[i] < lows[i+1] and lows[i] < lows[i+2]:
            pivotler.append(("DESTEK", lows[i]))

    # Yakın seviyeleri grupla (%0.5 içindeki pivoları birleştir)
    gruplar: list[tuple[str, list[float]]] = []
    for tip, fiyat in pivotler:
        eklendi = False
        for grup_tip, grup_fiyatlar in gruplar:
            ort = sum(grup_fiyatlar) / len(grup_fiyatlar)
            if grup_tip == tip and abs(fiyat - ort) / ort < 0.005:
                grup_fiyatlar.append(fiyat)
                eklendi = True
                break
        if not eklendi:
            gruplar.append((tip, [fiyat]))

    seviyeler = []
    for tip, fiyatlar in gruplar:
        ort_fiyat = round(sum(fiyatlar) / len(fiyatlar), 2)
        dokunma = len(fiyatlar)
        mesafe = abs(guncel - ort_fiyat) / guncel * 100

        # Güç belirleme — dokunma sayısına ve güncel fiyata yakınlığa göre
        if dokunma >= 4:
            guc = "COK_GUCLU"
        elif dokunma == 3:
            guc = "GUCLU"
        elif dokunma == 2:
            guc = "ORTA"
        else:
            guc = "ZAYIF"

        # Sadece güncel fiyatın %15 yakınındakileri al
        if mesafe <= 15:
            seviyeler.append({
                "fiyat": ort_fiyat,
                "tip": tip,
                "guc": guc,
                "dokunma": dokunma,
                "mesafe_yuzde": round(mesafe, 2),
            })

    # Destek: fiyatın altındakiler (yakından uzağa)
    destekler = sorted(
        [s for s in seviyeler if s["fiyat"] < guncel],
        key=lambda x: x["fiyat"], reverse=True
    )[:5]

    # Direnç: fiyatın üstündekiler (yakından uzağa)
    direngler = sorted(
        [s for s in seviyeler if s["fiyat"] > guncel],
        key=lambda x: x["fiyat"]
    )[:5]

    # Fibonacci seviyeleri (son 50 mumun high/low'u)
    son_high = max(highs[-50:])
    son_low = min(lows[-50:])
    fark = son_high - son_low
    fibonacci = {
        "0": round(son_low, 2),
        "0.236": round(son_low + fark * 0.236, 2),
        "0.382": round(son_low + fark * 0.382, 2),
        "0.5": round(son_low + fark * 0.5, 2),
        "0.618": round(son_low + fark * 0.618, 2),
        "0.786": round(son_low + fark * 0.786, 2),
        "1": round(son_high, 2),
    }

    return {
        "guncel_fiyat": guncel,
        "destekler": destekler,
        "direngler": direngler,
        "fibonacci": fibonacci,
        "sembol": symbol.upper(),
    }
