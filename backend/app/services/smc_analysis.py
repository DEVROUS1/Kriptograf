"""
Smart Money Concepts (SMC) / ICT Analizi
- Order Blocks: Kurumsal alım/satım bölgeleri
- Fair Value Gaps (FVG): Doldurulamayan boşluklar
- Liquidity Levels: Stop-loss avı yapılan seviyeler
- Break of Structure (BOS): Yapı kırılımları
- Change of Character (CHoCH): Karakter değişimi
"""
import httpx
from dataclasses import dataclass, asdict
from typing import Literal


@dataclass
class OrderBlock:
    tip: Literal["BULLISH", "BEARISH"]
    ust: float
    alt: float
    orta: float
    guc: Literal["ZAYIF", "ORTA", "GUCLU"]
    test_sayisi: int
    mum_index: int
    gecerli: bool  # fiyat içinden geçmediyse geçerli


@dataclass
class FairValueGap:
    tip: Literal["BULLISH", "BEARISH"]
    ust: float
    alt: float
    orta: float
    dolduruldu: bool
    boyut_yuzde: float


@dataclass
class LiquidityLevel:
    tip: Literal["BSL", "SSL"]  # Buy Side / Sell Side Liquidity
    fiyat: float
    guc: Literal["ZAYIF", "ORTA", "GUCLU"]
    aciklama: str


async def smc_analiz(symbol: str = "BTCUSDT", interval: str = "4h") -> dict:
    usdt = symbol.upper() if "USDT" in symbol.upper() else symbol.upper() + "USDT"

    async with httpx.AsyncClient(timeout=12) as c:
        r = await c.get(
            f"https://api.binance.com/api/v3/klines"
            f"?symbol={usdt}&interval={interval}&limit=100"
        )
        klines = r.json()
        p = await c.get(f"https://api.binance.com/api/v3/ticker/price?symbol={usdt}")
        guncel = float(p.json()["price"])

    opens = [float(k[1]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    closes = [float(k[4]) for k in klines]
    volumes = [float(k[5]) for k in klines]

    order_blocks = _tespit_order_blocks(opens, highs, lows, closes, volumes, guncel)
    fvg_listesi = _tespit_fvg(highs, lows, closes, guncel)
    likidite = _tespit_likidite(highs, lows, closes, guncel)
    bos_choch = _tespit_bos_choch(highs, lows, closes)
    market_yapi = _piyasa_yapisi(highs, lows, closes)

    # Güçlü OB'lara yakınlık kontrolü
    en_yakin_ob = None
    en_yakin_mesafe = 999.0
    for ob in order_blocks:
        if ob["gecerli"]:
            mesafe = abs(guncel - ob["orta"]) / guncel * 100
            if mesafe < en_yakin_mesafe:
                en_yakin_mesafe = mesafe
                en_yakin_ob = ob

    # FVG'lerin özeti
    aktif_fvg = [f for f in fvg_listesi if not f["dolduruldu"]]

    return {
        "sembol": symbol.upper(),
        "interval": interval,
        "guncel_fiyat": guncel,
        "piyasa_yapisi": market_yapi,
        "bos_choch": bos_choch,
        "order_blocks": {
            "bullish": [ob for ob in order_blocks if ob["tip"] == "BULLISH"][:4],
            "bearish": [ob for ob in order_blocks if ob["tip"] == "BEARISH"][:4],
            "en_yakin": en_yakin_ob,
            "en_yakin_mesafe_yuzde": round(en_yakin_mesafe, 2),
        },
        "fair_value_gaps": {
            "bullish": [f for f in aktif_fvg if f["tip"] == "BULLISH"][:3],
            "bearish": [f for f in aktif_fvg if f["tip"] == "BEARISH"][:3],
            "toplam_aktif": len(aktif_fvg),
        },
        "likidite_seviyeleri": likidite,
        "ozet": _ozet_uret(market_yapi, order_blocks, aktif_fvg, likidite, guncel),
    }


def _tespit_order_blocks(opens, highs, lows, closes, volumes, guncel):
    """
    Order Block = Kurumsal katılımın başladığı son karşıt mum.
    Bullish OB: Düşüşten önce son bearish mum
    Bearish OB: Yükselişten önce son bullish mum
    """
    obs = []
    avg_volume = sum(volumes) / len(volumes)

    for i in range(2, len(closes) - 3):
        # Bullish Order Block
        if closes[i] < opens[i]:  # Bearish mum
            # Sonraki 3 mumda güçlü yükseliş var mı?
            sonraki_yukselis = all(closes[i+j] > closes[i+j-1] for j in range(1, 3))
            hacim_yuksek = volumes[i] > avg_volume * 1.2

            if sonraki_yukselis:
                # OB hala geçerli mi? (fiyat içinden geçmedi mi?)
                ob_ust = max(opens[i], closes[i])
                ob_alt = min(opens[i], closes[i])
                gecerli = guncel > ob_alt  # fiyat OB'nin altına düşmediyse

                # Kaç kez test edildi?
                test = sum(1 for j in range(i+1, len(lows))
                          if ob_alt <= lows[j] <= ob_ust + (ob_ust - ob_alt) * 0.1)

                guc = "GUCLU" if (hacim_yuksek and test >= 2) else \
                      "ORTA" if (hacim_yuksek or test >= 1) else "ZAYIF"

                obs.append({
                    "tip": "BULLISH",
                    "ust": round(ob_ust, 4),
                    "alt": round(ob_alt, 4),
                    "orta": round((ob_ust + ob_alt) / 2, 4),
                    "guc": guc,
                    "test_sayisi": test,
                    "mum_index": i,
                    "gecerli": gecerli,
                    "mesafe_yuzde": round(abs(guncel - (ob_ust + ob_alt) / 2) / guncel * 100, 2),
                })

        # Bearish Order Block
        elif closes[i] > opens[i]:  # Bullish mum
            sonraki_dusus = all(closes[i+j] < closes[i+j-1] for j in range(1, 3))
            hacim_yuksek = volumes[i] > avg_volume * 1.2

            if sonraki_dusus:
                ob_ust = max(opens[i], closes[i])
                ob_alt = min(opens[i], closes[i])
                gecerli = guncel < ob_ust

                test = sum(1 for j in range(i+1, len(highs))
                          if ob_alt - (ob_ust - ob_alt) * 0.1 <= highs[j] <= ob_ust)

                guc = "GUCLU" if (hacim_yuksek and test >= 2) else \
                      "ORTA" if (hacim_yuksek or test >= 1) else "ZAYIF"

                obs.append({
                    "tip": "BEARISH",
                    "ust": round(ob_ust, 4),
                    "alt": round(ob_alt, 4),
                    "orta": round((ob_ust + ob_alt) / 2, 4),
                    "guc": guc,
                    "test_sayisi": test,
                    "mum_index": i,
                    "gecerli": gecerli,
                    "mesafe_yuzde": round(abs(guncel - (ob_ust + ob_alt) / 2) / guncel * 100, 2),
                })

    # En yakın ve güçlü OB'ları döndür
    obs_gecerli = [o for o in obs if o["gecerli"] and o["mesafe_yuzde"] < 10]
    obs_gecerli.sort(key=lambda x: x["mesafe_yuzde"])
    return obs_gecerli[:8]


def _tespit_fvg(highs, lows, closes, guncel):
    """
    Fair Value Gap = 3 mumlu boşluk.
    Bullish FVG: mum[i-1].high < mum[i+1].low
    Bearish FVG: mum[i-1].low > mum[i+1].high
    """
    fvglar = []

    for i in range(1, len(closes) - 1):
        # Bullish FVG
        if highs[i-1] < lows[i+1]:
            boyut = (lows[i+1] - highs[i-1]) / closes[i] * 100
            if boyut > 0.1:  # minimum boyut filtresi
                dolduruldu = any(lows[j] <= highs[i-1] for j in range(i+2, len(lows)))
                fvglar.append({
                    "tip": "BULLISH",
                    "ust": round(lows[i+1], 4),
                    "alt": round(highs[i-1], 4),
                    "orta": round((lows[i+1] + highs[i-1]) / 2, 4),
                    "dolduruldu": dolduruldu,
                    "boyut_yuzde": round(boyut, 3),
                    "mesafe_yuzde": round(abs(guncel - (lows[i+1] + highs[i-1]) / 2) / guncel * 100, 2),
                })

        # Bearish FVG
        elif lows[i-1] > highs[i+1]:
            boyut = (lows[i-1] - highs[i+1]) / closes[i] * 100
            if boyut > 0.1:
                dolduruldu = any(highs[j] >= lows[i-1] for j in range(i+2, len(highs)))
                fvglar.append({
                    "tip": "BEARISH",
                    "ust": round(lows[i-1], 4),
                    "alt": round(highs[i+1], 4),
                    "orta": round((lows[i-1] + highs[i+1]) / 2, 4),
                    "dolduruldu": dolduruldu,
                    "boyut_yuzde": round(boyut, 3),
                    "mesafe_yuzde": round(abs(guncel - (lows[i-1] + highs[i+1]) / 2) / guncel * 100, 2),
                })

    aktifler = [f for f in fvglar if not f["dolduruldu"] and f["mesafe_yuzde"] < 8]
    aktifler.sort(key=lambda x: x["mesafe_yuzde"])
    return aktifler[:6]


def _tespit_likidite(highs, lows, closes, guncel):
    """
    Liquidity = Stop-loss'ların biriktiği seviyeler.
    BSL (Buy Side): Swing High'ların üstü = kısa pozisyon stop'ları
    SSL (Sell Side): Swing Low'ların altı = uzun pozisyon stop'ları
    """
    seviyeler = []

    # Swing high/low tespit
    for i in range(2, len(closes) - 2):
        # Swing High → BSL
        if highs[i] > highs[i-1] and highs[i] > highs[i-2] and \
           highs[i] > highs[i+1] and highs[i] > highs[i+2]:
            mesafe = (guncel - highs[i]) / guncel * 100
            if -8 < mesafe < 8:
                guc = "GUCLU" if abs(mesafe) < 2 else "ORTA" if abs(mesafe) < 5 else "ZAYIF"
                seviyeler.append({
                    "tip": "BSL",
                    "fiyat": round(highs[i], 4),
                    "guc": guc,
                    "mesafe_yuzde": round(mesafe, 2),
                    "aciklama": f"Swing High — Short stop-loss bölgesi",
                })

        # Swing Low → SSL
        elif lows[i] < lows[i-1] and lows[i] < lows[i-2] and \
             lows[i] < lows[i+1] and lows[i] < lows[i+2]:
            mesafe = (guncel - lows[i]) / guncel * 100
            if -8 < mesafe < 8:
                guc = "GUCLU" if abs(mesafe) < 2 else "ORTA" if abs(mesafe) < 5 else "ZAYIF"
                seviyeler.append({
                    "tip": "SSL",
                    "fiyat": round(lows[i], 4),
                    "guc": guc,
                    "mesafe_yuzde": round(mesafe, 2),
                    "aciklama": f"Swing Low — Long stop-loss bölgesi",
                })

    seviyeler.sort(key=lambda x: abs(x["mesafe_yuzde"]))
    return seviyeler[:6]


def _tespit_bos_choch(highs, lows, closes):
    """
    Break of Structure (BOS): Trend yönünde yapı kırılımı
    Change of Character (CHoCH): Trend değişim sinyali
    """
    if len(closes) < 10:
        return {"bos": None, "choch": None, "trend": "BELIRSIZ"}

    # Son 20 mumda trend belirle
    son = closes[-20:]
    yukselis_sayisi = sum(1 for i in range(1, len(son)) if son[i] > son[i-1])
    trend = "YUKSELIS" if yukselis_sayisi > 12 else "DUSUS" if yukselis_sayisi < 8 else "YATAY"

    # BOS: Son swing high kırıldı mı?
    son_swing_high = max(highs[-15:-3])
    son_swing_low = min(lows[-15:-3])
    bos = None
    choch = None

    if closes[-1] > son_swing_high and trend == "DUSUS":
        choch = {"tip": "BULLISH_CHOCH", "seviye": round(son_swing_high, 4),
                 "aciklama": "Ayı trendinde yapı kırıldı — trend değişimi sinyali"}
    elif closes[-1] > son_swing_high and trend == "YUKSELIS":
        bos = {"tip": "BULLISH_BOS", "seviye": round(son_swing_high, 4),
               "aciklama": "Boğa trendinde yeni yüksek — trend devam ediyor"}
    elif closes[-1] < son_swing_low and trend == "YUKSELIS":
        choch = {"tip": "BEARISH_CHOCH", "seviye": round(son_swing_low, 4),
                 "aciklama": "Boğa trendinde yapı kırıldı — trend değişimi sinyali"}
    elif closes[-1] < son_swing_low and trend == "DUSUS":
        bos = {"tip": "BEARISH_BOS", "seviye": round(son_swing_low, 4),
               "aciklama": "Ayı trendinde yeni düşük — trend devam ediyor"}

    return {"bos": bos, "choch": choch, "trend": trend}


def _piyasa_yapisi(highs, lows, closes):
    """Higher Highs/Lower Lows analizi"""
    if len(closes) < 20:
        return "BELIRSIZ"

    # Son 4 swing high/low karşılaştır
    son_highs = sorted(range(len(highs)-20, len(highs)-1),
                       key=lambda i: highs[i], reverse=True)[:4]
    son_lows = sorted(range(len(lows)-20, len(lows)-1),
                      key=lambda i: lows[i])[:4]

    if len(son_highs) >= 2 and len(son_lows) >= 2:
        hh = highs[max(son_highs)] > highs[min(son_highs)]
        hl = lows[max(son_lows)] > lows[min(son_lows)]
        lh = highs[max(son_highs)] < highs[min(son_highs)]
        ll = lows[max(son_lows)] < lows[min(son_lows)]

        if hh and hl:
            return "HH/HL — Güçlü Boğa Yapısı"
        elif lh and ll:
            return "LH/LL — Güçlü Ayı Yapısı"
        elif hh and ll:
            return "HH/LL — Dağılım / Belirsiz"
        elif lh and hl:
            return "LH/HL — Birikim / Belirsiz"

    return "BELIRSIZ"


def _ozet_uret(market_yapi, obs, fvglar, likidite, guncel):
    """SMC özet yorumu"""
    satirlar = []

    # Piyasa yapısı
    satirlar.append(f"Piyasa yapısı: {market_yapi}")

    # En yakın OB
    bullish_obs = [o for o in obs if o["tip"] == "BULLISH" and o["gecerli"]]
    bearish_obs = [o for o in obs if o["tip"] == "BEARISH" and o["gecerli"]]

    if bullish_obs:
        en_yakin = min(bullish_obs, key=lambda x: x["mesafe_yuzde"])
        satirlar.append(f"En yakın Bullish OB: ${en_yakin['alt']:,.2f}–${en_yakin['ust']:,.2f} ({en_yakin['guc']})")

    if bearish_obs:
        en_yakin = min(bearish_obs, key=lambda x: x["mesafe_yuzde"])
        satirlar.append(f"En yakın Bearish OB: ${en_yakin['alt']:,.2f}–${en_yakin['ust']:,.2f} ({en_yakin['guc']})")

    # FVG
    aktif_fvg = [f for f in fvglar if not f["dolduruldu"]]
    if aktif_fvg:
        satirlar.append(f"{len(aktif_fvg)} aktif FVG mevcut — fiyat bu boşlukları doldurmaya çalışabilir")

    # BSL/SSL
    bsl = [l for l in likidite if l["tip"] == "BSL" and l["guc"] == "GUCLU"]
    ssl = [l for l in likidite if l["tip"] == "SSL" and l["guc"] == "GUCLU"]
    if bsl:
        satirlar.append(f"BSL (hedef): ${bsl[0]['fiyat']:,.2f} — kısa pozisyon stop-loss havuzu")
    if ssl:
        satirlar.append(f"SSL (hedef): ${ssl[0]['fiyat']:,.2f} — uzun pozisyon stop-loss havuzu")

    return " | ".join(satirlar)
