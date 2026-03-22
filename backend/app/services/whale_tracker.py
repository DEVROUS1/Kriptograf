# Whale Alert API + Binance büyük işlem tespiti
# Whale Alert API anahtarı yoksa Binance /fapi/v1/trades endpoint'inden
# son 1000 işlemi çek, $500.000 üzerini filtrele

import httpx
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

WHALE_THRESHOLD_USD = 10_000


async def get_recent_whale_trades(symbol: str = "BTCUSDT") -> list[dict]:
    """
    Binance Futures'tan son büyük işlemleri çeker.
    Her işlem için tahmini USD değeri hesaplar.
    $500K üzerindeki işlemleri döner.
    """
    symbol = symbol.upper()
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            price_r = await client.get(
                f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={symbol}"
            )
            price_r.raise_for_status()
            price = float(price_r.json()["price"])

            trades_r = await client.get(
                f"https://fapi.binance.com/fapi/v1/trades?symbol={symbol}&limit=1000"
            )
            trades_r.raise_for_status()
            trades = trades_r.json()

        if not isinstance(trades, list):
            return []

        whales = []
        for t in trades:
            try:
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
                        "sembol": symbol,
                    })
            except (KeyError, ValueError, TypeError):
                continue

        return sorted(whales, key=lambda x: x["timestamp"], reverse=True)[:20]

    except httpx.TimeoutException:
        logger.warning("whale_tracker: Binance timeout — %s", symbol)
        return []
    except Exception as exc:
        logger.error("whale_tracker: beklenmeyen hata — %s: %s", symbol, exc)
        return []


async def get_whale_stats(symbol: str = "BTCUSDT") -> dict:
    """Son 1 saatteki balina istatistikleri"""
    trades = await get_recent_whale_trades(symbol)
    alis = [t for t in trades if t["yon"] == "ALIŞ"]
    satis = [t for t in trades if t["yon"] == "SATIŞ"]
    alis_hacim = sum(t["usd_deger"] for t in alis)
    satis_hacim = sum(t["usd_deger"] for t in satis)
    return {
        "toplam_balikane": len(trades),
        "alis_sayisi": len(alis),
        "satis_sayisi": len(satis),
        "alis_hacim_usd": alis_hacim,
        "satis_hacim_usd": satis_hacim,
        "baski": "ALIŞ" if alis_hacim >= satis_hacim else "SATIŞ",
        "islemler": trades,
    }
