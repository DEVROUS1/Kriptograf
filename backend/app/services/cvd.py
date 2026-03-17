import httpx
from typing import List

async def get_cvd_data(symbol: str = "BTCUSDT", interval: str = "1m", limit: int = 60) -> dict:
    """
    Kline verilerinden CVD hesaplar.
    CVD = Σ(alış hacmi - satış hacmi)
    Binance kline'da taker_buy_base_volume alanı alış hacmini verir.
    """
    try:
        url = (f"https://fapi.binance.com/fapi/v1/klines"
               f"?symbol={symbol.upper()}&interval={interval}&limit={limit}")
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(url)
            r.raise_for_status()
            klines = r.json()
            if not isinstance(klines, list):
                raise ValueError("Invalid format")
    except Exception:
        return {
            "veri": [],
            "son_cvd": 0.0,
            "trend": "BELİRSİZ",
            "alis_baskisi": False,
        }

    cvd_data = []
    cumulative = 0.0
    for k in klines:
        volume = float(k[5])
        taker_buy = float(k[9])
        taker_sell = volume - taker_buy
        delta = taker_buy - taker_sell
        cumulative += delta
        cvd_data.append({
            "zaman": k[0],
            "delta": round(delta, 4),
            "kumulatif": round(cumulative, 4),
            "yon": "ALIŞ" if delta > 0 else "SATIŞ"
        })

    son_cvd = cvd_data[-1]["kumulatif"] if cvd_data else 0
    trend = "YÜKSELİŞ" if son_cvd > 0 else "DÜŞÜŞ"
    return {
        "veri": cvd_data,
        "son_cvd": son_cvd,
        "trend": trend,
        "alis_baskisi": son_cvd > 0,
    }
