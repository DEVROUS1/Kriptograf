# Whale Alert API + Binance büyük işlem tespiti
# Whale Alert API anahtarı yoksa Binance /api/v3/trades endpoint'inden
# son 1000 işlemi çek, $500.000 üzerini filtrele

import asyncio
import httpx
from datetime import datetime

WHALE_THRESHOLD_USD = 500_000

async def get_recent_whale_trades(symbol: str = "BTCUSDT") -> list[dict]:
    """
    Binance'ten son büyük işlemleri çeker.
    Her işlem için tahmini USD değeri hesaplar.
    $500K üzerindeki işlemleri döner.
    """
    url = f"https://fapi.binance.com/fapi/v1/trades?symbol={symbol.upper()}&limit=1000"
    async with httpx.AsyncClient() as client:
        # Önce güncel fiyatı al
        price_r = await client.get(f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={symbol.upper()}")
        price = float(price_r.json()["price"])
        
        trades_r = await client.get(url)
        trades = trades_r.json()
    
    whales = []
    for t in trades:
        qty = float(t["qty"])
        usd_value = qty * price
        if usd_value >= WHALE_THRESHOLD_USD:
            whales.append({
                "id": t["id"],
                "zaman": datetime.fromtimestamp(t["time"] / 1000).strftime("%H:%M:%S"),
                "timestamp": t["time"],
                "miktar": round(qty, 4),
                "fiyat": float(t["price"]),
                "usd_deger": round(usd_value),
                "yon": "SATIŞ" if t["isBuyerMaker"] else "ALIŞ",
                "sembol": symbol.upper()
            })
    
    # En yeni 20 balina işlemi
    return sorted(whales, key=lambda x: x["timestamp"], reverse=True)[:20]


async def get_whale_stats(symbol: str = "BTCUSDT") -> dict:
    """Son 1 saatteki balina istatistikleri"""
    trades = await get_recent_whale_trades(symbol)
    alis = [t for t in trades if t["yon"] == "ALIŞ"]
    satis = [t for t in trades if t["yon"] == "SATIŞ"]
    return {
        "toplam_balikane": len(trades),
        "alis_sayisi": len(alis),
        "satis_sayisi": len(satis),
        "alis_hacim_usd": sum(t["usd_deger"] for t in alis),
        "satis_hacim_usd": sum(t["usd_deger"] for t in satis),
        "baskı": "ALIŞ" if sum(t["usd_deger"] for t in alis) > sum(t["usd_deger"] for t in satis) else "SATIŞ",
        "islemler": trades
    }
