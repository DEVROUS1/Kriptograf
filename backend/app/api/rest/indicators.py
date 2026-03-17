from fastapi import APIRouter
from app.services.fear_greed import get_fear_and_greed
from app.services.indicators import calculate_stress_index

router = APIRouter(tags=["Indicators"])

@router.get("/korku-acgozluluk")
async def read_fear_and_greed():
    return await get_fear_and_greed()

@router.get("/stres-endeksi")
async def read_stress_index():
    return await calculate_stress_index()
