"""
Portföy CRUD endpoint'leri.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.models import PortfoyKalem

router = APIRouter(prefix="/api/portfoy", tags=["portfoy"])


class KalemEkle(BaseModel):
    sembol: str
    miktar: float
    alis_fiyati: float
    not_: str | None = None


class KalemGuncelle(BaseModel):
    miktar: float | None = None
    alis_fiyati: float | None = None
    not_: str | None = None


@router.get("")
async def portfoy_listesi(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(PortfoyKalem).order_by(PortfoyKalem.olusturuldu.desc()))
    kalemler = result.scalars().all()
    return [
        {
            "id": k.id,
            "sembol": k.sembol,
            "miktar": k.miktar,
            "alis_fiyati": k.alis_fiyati,
            "not": k.not_,
            "olusturuldu": k.olusturuldu.isoformat(),
        }
        for k in kalemler
    ]


@router.post("", status_code=201)
async def kalem_ekle(body: KalemEkle, db: AsyncSession = Depends(get_db)):
    if body.miktar <= 0:
        raise HTTPException(status_code=422, detail="Miktar sıfırdan büyük olmalı")
    if body.alis_fiyati <= 0:
        raise HTTPException(status_code=422, detail="Alış fiyatı sıfırdan büyük olmalı")

    kalem = PortfoyKalem(
        sembol=body.sembol.upper(),
        miktar=body.miktar,
        alis_fiyati=body.alis_fiyati,
        not_=body.not_,
    )
    db.add(kalem)
    await db.commit()
    await db.refresh(kalem)
    return {"id": kalem.id, "mesaj": "Portföy kalemi eklendi"}


@router.patch("/{kalem_id}")
async def kalem_guncelle(kalem_id: str, body: KalemGuncelle, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(PortfoyKalem).where(PortfoyKalem.id == kalem_id))
    kalem = result.scalar_one_or_none()
    if not kalem:
        raise HTTPException(status_code=404, detail="Portföy kalemi bulunamadı")

    if body.miktar is not None:
        kalem.miktar = body.miktar
    if body.alis_fiyati is not None:
        kalem.alis_fiyati = body.alis_fiyati
    if body.not_ is not None:
        kalem.not_ = body.not_

    await db.commit()
    return {"mesaj": "Güncellendi"}


@router.delete("/{kalem_id}")
async def kalem_sil(kalem_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(PortfoyKalem).where(PortfoyKalem.id == kalem_id))
    kalem = result.scalar_one_or_none()
    if not kalem:
        raise HTTPException(status_code=404, detail="Portföy kalemi bulunamadı")
    await db.delete(kalem)
    await db.commit()
    return {"mesaj": "Silindi"}
