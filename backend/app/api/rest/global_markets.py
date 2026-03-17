from fastapi import APIRouter
from pydantic import BaseModel
from app.services.global_markets import get_global_markets, get_macro_correlation
from app.services.portfolio import hesapla_portfoy
from app.services.cache import get_cached, set_cached

router = APIRouter()


@router.get("/api/kuresel-piyasalar")
async def kuresel():
    key = "kuresel_piyasalar"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_global_markets()
    await set_cached(key, data, ttl=60)
    return data


@router.get("/api/korelasyon")
async def korelasyon():
    key = "korelasyon"
    cached = await get_cached(key)
    if cached:
        return cached
    data = await get_macro_correlation()
    await set_cached(key, data, ttl=3600)  # 1 saat
    return data


class PortfoyIstek(BaseModel):
    varliklar: list[dict]
    usd_try: float = 32.0


@router.post("/api/portfoy-hesapla")
async def portfoy(istek: PortfoyIstek):
    return await hesapla_portfoy(istek.varliklar, istek.usd_try)
