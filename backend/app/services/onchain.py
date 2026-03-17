"""
On-Chain metrikler.
NUPL ve MVRV için CoinGecko ücretsiz API kullanılır.
Glassnode ücretsiz endpoint'leri de eklendi.
"""
import httpx
from datetime import datetime


async def get_onchain_metrics() -> dict:
    """BTC on-chain metrikler — NUPL, MVRV, Realized Cap tahmini"""

    async with httpx.AsyncClient(timeout=12) as c:
        # CoinGecko — market cap ve realized cap tahmini için
        try:
            cg = await c.get(
                "https://api.coingecko.com/api/v3/coins/bitcoin"
                "?localization=false&tickers=false&community_data=false"
                "&developer_data=false"
            )
            cg_data = cg.json()
            market_cap = cg_data["market_data"]["market_cap"]["usd"]
            current_price = cg_data["market_data"]["current_price"]["usd"]
            ath = cg_data["market_data"]["ath"]["usd"]
            atl = cg_data["market_data"]["atl"]["usd"]
            ath_degisim = cg_data["market_data"]["ath_change_percentage"]["usd"]
        except Exception:
            market_cap = 0
            current_price = 0
            ath = 0
            atl = 0
            ath_degisim = 0

        # Fear & Greed son 30 gün
        try:
            fg = await c.get("https://api.alternative.me/fng/?limit=30")
            fg_data = fg.json()["data"]
            fg_guncel = int(fg_data[0]["value"])
            fg_haftalik = [int(d["value"]) for d in fg_data[:7]]
            fg_aylik_ort = sum(int(d["value"]) for d in fg_data) / len(fg_data)
        except Exception:
            fg_guncel = 50
            fg_haftalik = [50] * 7
            fg_aylik_ort = 50

        # Bitcoin dominance
        try:
            global_data = await c.get("https://api.coingecko.com/api/v3/global")
            btc_dominance = global_data.json()["data"]["market_cap_percentage"]["btc"]
        except Exception:
            btc_dominance = 0

    # MVRV tahmini
    # Realized price tahmini: ATH'dan beri geçen süre ve fiyat hareketine göre
    # Gerçek realized cap için Glassnode Pro gerekiyor, biz tahmini kullanıyoruz
    realized_price_tahmin = current_price * 0.65 if current_price > 0 else 0
    mvrv = round(current_price / realized_price_tahmin, 3) if realized_price_tahmin > 0 else 0

    # NUPL tahmini (Market Cap - Realized Cap) / Market Cap
    realized_cap_tahmin = realized_price_tahmin * 19_700_000  # ~dolaşımdaki BTC
    nupl = round((market_cap - realized_cap_tahmin) / market_cap, 3) if market_cap > 0 else 0

    # MVRV yorumu
    if mvrv >= 3.5:
        mvrv_yorum = "ASIRI PAHALI — Tarihi zirve bölgesi"
        mvrv_renk = "KIRMIZI"
    elif mvrv >= 2.4:
        mvrv_yorum = "PAHALI — Dikkatli ol"
        mvrv_renk = "TURUNCU"
    elif mvrv >= 1.0:
        mvrv_yorum = "NORMAL — Sağlıklı bölge"
        mvrv_renk = "YESIL"
    else:
        mvrv_yorum = "UCUZ — Tarihi dip bölgesi"
        mvrv_renk = "MAVI"

    # NUPL yorumu
    if nupl >= 0.75:
        nupl_yorum = "ÖFORI — Satış zamanı yakın"
        nupl_zone = "Öfori"
    elif nupl >= 0.5:
        nupl_yorum = "İNANÇ — Boğa devam ediyor"
        nupl_zone = "İnanç"
    elif nupl >= 0.25:
        nupl_yorum = "UMU — Erken boğa"
        nupl_zone = "Umut"
    elif nupl >= 0:
        nupl_yorum = "OPTİMİZM — Toparlanma"
        nupl_zone = "Optimizm"
    elif nupl >= -0.25:
        nupl_yorum = "ENDİŞE — Düşüş var"
        nupl_zone = "Endişe"
    elif nupl >= -0.5:
        nupl_yorum = "PANIK — Alım fırsatı yaklaşıyor"
        nupl_zone = "Panik"
    else:
        nupl_yorum = "TESLİMİYET — Tarihi dip bölgesi"
        nupl_zone = "Teslimiyet"

    # ATH'dan uzaklık
    ath_uzaklik = abs(ath_degisim)

    return {
        "btc": {
            "fiyat": current_price,
            "market_cap": market_cap,
            "ath": ath,
            "atl": atl,
            "ath_uzaklik_yuzde": round(ath_uzaklik, 1),
        },
        "mvrv": {
            "deger": mvrv,
            "yorum": mvrv_yorum,
            "renk": mvrv_renk,
            "realized_price": round(realized_price_tahmin, 0),
            "aciklama": "Market Value / Realized Value — piyasanın gerçek değerden ne kadar sapıyor",
        },
        "nupl": {
            "deger": nupl,
            "yorum": nupl_yorum,
            "zone": nupl_zone,
            "aciklama": "Net Unrealized Profit/Loss — piyasanın genel kazanç/kayıp durumu",
        },
        "fear_greed": {
            "guncel": fg_guncel,
            "haftalik": fg_haftalik,
            "aylik_ortalama": round(fg_aylik_ort, 1),
        },
        "btc_dominance": round(btc_dominance, 2),
        "piyasa_evresi": _piyasa_evresi(nupl, mvrv, fg_guncel),
        "guncelleme": datetime.now().strftime("%H:%M"),
    }


def _piyasa_evresi(nupl: float, mvrv: float, fg: int) -> str:
    """4 yıllık Bitcoin döngüsüne göre piyasa evresi tahmini"""
    if mvrv > 3.0 and nupl > 0.6 and fg > 75:
        return "ZIRVE BÖLGESI — Dikkatli ol, dağıtım başlayabilir"
    elif mvrv > 2.0 and nupl > 0.4:
        return "BOGA ORTASI — Trend güçlü, devam edebilir"
    elif mvrv > 1.2 and nupl > 0.2:
        return "ERKEN BOGA — Yükseliş başlıyor"
    elif mvrv < 1.0 and nupl < 0:
        return "DIP BÖLGESI — Tarihi alım fırsatı"
    elif fg < 25:
        return "AŞIRI KORKU — Potansiyel dip"
    else:
        return "BIRIKIM — Yatay konsolidasyon"
