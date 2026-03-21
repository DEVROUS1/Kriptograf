"""
Alarm CRUD endpoint'leri.
Alarmlar artık Redis'te geçici değil, Postgres'te kalıcı olarak saklanır.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.models import Alarm

router = APIRouter(prefix="/api/alarmlar", tags=["alarmlar"])


class AlarmEkle(BaseModel):
    sembol: str
    hedef_fiyat: float
    yon: str  # "YUKARI" | "ASAGI"


class AlarmTetiklendi(BaseModel):
    alarm_id: str


@router.get("")
async def alarm_listesi(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Alarm).where(Alarm.aktif == True).order_by(Alarm.olusturuldu.desc()))
    alarmlar = result.scalars().all()
    return [
        {
            "id": a.id,
            "sembol": a.sembol,
            "hedef": a.hedef_fiyat,
            "yon": a.yon,
            "aktif": a.aktif,
            "olusturuldu": a.olusturuldu.isoformat(),
        }
        for a in alarmlar
    ]


@router.post("", status_code=201)
async def alarm_ekle(body: AlarmEkle, db: AsyncSession = Depends(get_db)):
    if body.yon not in ("YUKARI", "ASAGI"):
        raise HTTPException(status_code=422, detail="Yön 'YUKARI' veya 'ASAGI' olmalı")
    if body.hedef_fiyat <= 0:
        raise HTTPException(status_code=422, detail="Hedef fiyat sıfırdan büyük olmalı")

    alarm = Alarm(
        sembol=body.sembol.upper(),
        hedef_fiyat=body.hedef_fiyat,
        yon=body.yon,
    )
    db.add(alarm)
    await db.commit()
    await db.refresh(alarm)
    return {"id": alarm.id, "mesaj": "Alarm oluşturuldu"}


@router.delete("/{alarm_id}")
async def alarm_sil(alarm_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Alarm).where(Alarm.id == alarm_id))
    alarm = result.scalar_one_or_none()
    if not alarm:
        raise HTTPException(status_code=404, detail="Alarm bulunamadı")
    await db.delete(alarm)
    await db.commit()
    return {"mesaj": "Alarm silindi"}
