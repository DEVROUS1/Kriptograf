import asyncio
import httpx
from datetime import datetime

async def get_global_markets() -> dict:
    """
    Kripto piyasasını etkileyen küresel ve Türkiye verileri.
    Yahoo Finance non-official endpoint + TCMB + alternatif kaynaklar.
    """

    async def yahoo(symbol: str) -> dict | None:
        try:
            url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1d&range=2d"
            async with httpx.AsyncClient(timeout=8, headers={"User-Agent": "Mozilla/5.0"}) as c:
                r = await c.get(url)
                d = r.json()["chart"]["result"][0]
                meta = d["meta"]
                kapanis = meta["regularMarketPrice"]
                onceki = meta["chartPreviousClose"]
                degisim = ((kapanis - onceki) / onceki) * 100
                return {
                    "fiyat": round(kapanis, 2),
                    "degisim": round(degisim, 2),
                    "onceki_kapanis": round(onceki, 2),
                }
        except Exception:
            return None

    async def tcmb_kur() -> dict:
        """TCMB günlük döviz kuru XML verisi."""
        try:
            url = "https://www.tcmb.gov.tr/kurlar/today.xml"
            async with httpx.AsyncClient(timeout=8) as c:
                r = await c.get(url)
            import xml.etree.ElementTree as ET
            root = ET.fromstring(r.text)
            kurlar = {}
            for item in root.findall("Currency"):
                kod = item.get("CurrencyCode", "")
                satis = item.findtext("ForexSelling")
                if kod in ("USD", "EUR", "GBP") and satis:
                    kurlar[kod] = round(float(satis.replace(",", ".")), 4)
            return kurlar
        except Exception:
            return {"USD": None, "EUR": None}

    async def altin_fiyat() -> dict | None:
        """Gram altın TL fiyatı — Yahoo Finance GC=F (USD/oz) + TCMB USD/TRY kuru."""
        # Bu fonksiyon asyncio.gather'dan sonra altin_usd ve kurlar ile hesaplanır.
        # Placeholder olarak None döndururuz, gerçek hesap aşağıda yapılır.
        return None

    async def bist100() -> dict | None:
        """BIST 100 endeksi."""
        try:
            d = await yahoo("XU100.IS")
            return d
        except Exception:
            return None

    async def fear_greed() -> dict:
        try:
            async with httpx.AsyncClient(timeout=6) as c:
                r = await c.get("https://api.alternative.me/fng/?limit=7")
                data = r.json()["data"]
                return {
                    "bugun": int(data[0]["value"]),
                    "bugun_etiket": data[0]["value_classification"],
                    "haftalik": [int(d["value"]) for d in data],
                }
        except Exception:
            return {"bugun": 50, "bugun_etiket": "Neutral", "haftalik": [50] * 7}

    # Paralel çek
    (sp500, nasdaq, dxy, altin_usd, petrol, vix,
     bist, kurlar, altin_tl, fg) = await asyncio.gather(
        yahoo("^GSPC"),     # S&P 500
        yahoo("^IXIC"),     # NASDAQ
        yahoo("DX-Y.NYB"),  # Dolar Endeksi
        yahoo("GC=F"),      # Altın (USD/oz)
        yahoo("CL=F"),      # Ham Petrol
        yahoo("^VIX"),      # VIX Korku Endeksi
        bist100(),          # BIST 100
        tcmb_kur(),         # TCMB Kurları
        altin_fiyat(),      # Gram Altın TL
        fear_greed(),       # Kripto Korku/Açgözlülük
    )

    # BTC/TRY ve Altın TL hesapla
    btc_try = None
    eth_try = None
    altin_tl_hesap = None
    try:
        usd_tl = kurlar.get("USD")
        if usd_tl:
            btc_data = await yahoo("BTC-USD")
            eth_data = await yahoo("ETH-USD")
            if btc_data:
                btc_try = round(btc_data["fiyat"] * usd_tl, 0)
            if eth_data:
                eth_try = round(eth_data["fiyat"] * usd_tl, 0)
            # Gram altın TL = (USD/oz ÷ 31.1035) × USD/TL
            if altin_usd:
                gram_usd = altin_usd["fiyat"] / 31.1035
                gram_tl = gram_usd * usd_tl
                altin_tl_hesap = {
                    "gram_tl": round(gram_tl, 2),
                    "ceyrek_tl": round(gram_tl * 1.75, 2),  # ~1.75 gram
                    "tam_tl": round(gram_tl * 7.0, 2),       # ~7 gram
                }
    except Exception:
        pass

    return {
        "kuresel": {
            "sp500":     {"isim": "S&P 500",     "veri": sp500,    "sembol": "^GSPC"},
            "nasdaq":    {"isim": "NASDAQ",       "veri": nasdaq,   "sembol": "^IXIC"},
            "dxy":       {"isim": "Dolar Endeksi","veri": dxy,      "sembol": "DXY"},
            "altin_usd": {"isim": "Altın ($/oz)", "veri": altin_usd,"sembol": "GC=F"},
            "petrol":    {"isim": "Ham Petrol",   "veri": petrol,   "sembol": "CL=F"},
            "vix":       {"isim": "VIX Endeksi",  "veri": vix,      "sembol": "^VIX"},
        },
        "turkiye": {
            "bist100": {"isim": "BIST 100",  "veri": bist},
            "usd_try": {"isim": "USD/TRY",   "fiyat": kurlar.get("USD")},
            "eur_try": {"isim": "EUR/TRY",   "fiyat": kurlar.get("EUR")},
            "altin_tl": altin_tl_hesap,
        },
        "kripto_tl": {
            "btc_try": btc_try,
            "eth_try": eth_try,
        },
        "korku_acgozluluk": fg,
        "guncelleme": datetime.now().strftime("%H:%M:%S"),
    }


async def get_macro_correlation() -> dict:
    """
    BTC ile küresel piyasalar arasındaki korelasyon yorumu.
    Son 30 günlük kapanış verilerinden hesaplanır.
    """
    async def closes(symbol: str, count: int = 30) -> list[float]:
        try:
            url = (f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
                   f"?interval=1d&range=60d")
            async with httpx.AsyncClient(timeout=8, headers={"User-Agent": "Mozilla/5.0"}) as c:
                r = await c.get(url)
                prices = r.json()["chart"]["result"][0]["indicators"]["quote"][0]["close"]
                return [p for p in prices if p is not None][-count:]
        except Exception:
            return []

    btc, sp500, nasdaq, altin, dxy = await asyncio.gather(
        closes("BTC-USD"),
        closes("^GSPC"),
        closes("^IXIC"),
        closes("GC=F"),
        closes("DX-Y.NYB"),
    )

    def korelasyon(a: list, b: list) -> float | None:
        n = min(len(a), len(b))
        if n < 5:
            return None
        a, b = a[-n:], b[-n:]
        ort_a = sum(a) / n
        ort_b = sum(b) / n
        pay = sum((a[i] - ort_a) * (b[i] - ort_b) for i in range(n))
        payda_a = (sum((x - ort_a) ** 2 for x in a)) ** 0.5
        payda_b = (sum((x - ort_b) ** 2 for x in b)) ** 0.5
        if payda_a * payda_b == 0:
            return None
        return round(pay / (payda_a * payda_b), 3)

    def yorum(k: float | None, isim: str) -> str:
        if k is None:
            return f"{isim}: Veri yetersiz"
        if k > 0.7:
            return f"{isim}: Güçlü pozitif korelasyon (+{k})"
        if k > 0.3:
            return f"{isim}: Orta pozitif korelasyon (+{k})"
        if k < -0.7:
            return f"{isim}: Güçlü negatif korelasyon ({k})"
        if k < -0.3:
            return f"{isim}: Orta negatif korelasyon ({k})"
        return f"{isim}: Zayıf korelasyon ({k})"

    k_sp500 = korelasyon(btc, sp500)
    k_nasdaq = korelasyon(btc, nasdaq)
    k_altin = korelasyon(btc, altin)
    k_dxy = korelasyon(btc, dxy)

    return {
        "sp500":  {"deger": k_sp500,  "yorum": yorum(k_sp500,  "S&P 500")},
        "nasdaq": {"deger": k_nasdaq, "yorum": yorum(k_nasdaq, "NASDAQ")},
        "altin":  {"deger": k_altin,  "yorum": yorum(k_altin,  "Altın")},
        "dxy":    {"deger": k_dxy,    "yorum": yorum(k_dxy,    "Dolar Endeksi")},
        "ozet": (
            "BTC şu an hisse senetleriyle yüksek korelasyon gösteriyor — risk iştahı belirleyici."
            if (k_sp500 or 0) > 0.5
            else "BTC şu an bağımsız hareket ediyor — makro etkisi sınırlı."
        ),
    }
