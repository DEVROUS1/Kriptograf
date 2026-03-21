"""
Portföy servisi — sunucu tarafı hesaplama.
Varlık listesi frontend/DB'den gelir, güncel fiyatlar burada çekilir.
Alış fiyatı varsa kâr/zarar hesaplanır.
"""
import asyncio
import httpx


async def hesapla_portfoy(varliklar: list[dict], usd_try: float = 1.0) -> dict:
    """
    varliklar: [{"sembol": "BTC", "miktar": 0.5, "alis_fiyati": 60000.0}, ...]
    """
    if not varliklar:
        return {"varliklar": [], "toplam_usd": 0, "toplam_tl": 0, "usd_try": usd_try}

    async def fiyat(symbol: str) -> float:
        try:
            usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get(f"https://fapi.binance.com/fapi/v1/ticker/price?symbol={usdt}")
                return float(r.json()["price"])
        except Exception:
            return 0.0

    semboller = list({v["sembol"].upper() for v in varliklar})
    fiyatlar = dict(zip(semboller, await asyncio.gather(*[fiyat(s) for s in semboller])))

    sonuclar = []
    toplam_usd = 0.0
    for v in varliklar:
        sym = v["sembol"].upper()
        miktar = float(v.get("miktar", 0))
        alis_fiyati = float(v.get("alis_fiyati") or 0)
        p = fiyatlar.get(sym, 0)
        deger_usd = miktar * p
        toplam_usd += deger_usd

        kalem = {
            "sembol": sym,
            "miktar": miktar,
            "fiyat_usd": round(p, 4),
            "deger_usd": round(deger_usd, 2),
            "deger_tl": round(deger_usd * usd_try, 2),
        }

        # Kâr/zarar hesapla (alış fiyatı varsa)
        if alis_fiyati > 0 and p > 0:
            maliyet_usd = miktar * alis_fiyati
            kalem["alis_fiyati"] = round(alis_fiyati, 4)
            kalem["maliyet_usd"] = round(maliyet_usd, 2)
            kalem["kar_zarar_usd"] = round(deger_usd - maliyet_usd, 2)
            kalem["kar_zarar_yuzde"] = round((p - alis_fiyati) / alis_fiyati * 100, 2)

        sonuclar.append(kalem)

    return {
        "varliklar": sorted(sonuclar, key=lambda x: x["deger_usd"], reverse=True),
        "toplam_usd": round(toplam_usd, 2),
        "toplam_tl": round(toplam_usd * usd_try, 2),
        "usd_try": usd_try,
    }
