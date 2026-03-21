"""
SQLAlchemy ORM modelleri — alarmlar ve portföy.
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Alarm(Base):
    __tablename__ = "alarmlar"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sembol: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    hedef_fiyat: Mapped[float] = mapped_column(Float, nullable=False)
    yon: Mapped[str] = mapped_column(String(10), nullable=False)  # "YUKARI" | "ASAGI"
    aktif: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    olusturuldu: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    tetiklendi: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PortfoyKalem(Base):
    __tablename__ = "portfoy"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sembol: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    miktar: Mapped[float] = mapped_column(Float, nullable=False)
    alis_fiyati: Mapped[float] = mapped_column(Float, nullable=False)
    not_: Mapped[str | None] = mapped_column("not", Text, nullable=True)
    olusturuldu: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    guncellendi: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now, onupdate=_now)
