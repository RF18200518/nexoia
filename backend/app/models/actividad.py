from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Asistencia(Base):
    __tablename__ = "asistencias"

    id: Mapped[int] = mapped_column(primary_key=True)
    estudiante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    necesidad_id: Mapped[int] = mapped_column(ForeignKey("necesidades.id"))
    fecha: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    horas: Mapped[float] = mapped_column(Float, default=0)
    codigo_qr: Mapped[str | None] = mapped_column(String(100))
    validado: Mapped[bool] = mapped_column(Boolean, default=False)
    expira_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Evidencia(Base):
    __tablename__ = "evidencias"

    id: Mapped[int] = mapped_column(primary_key=True)
    asistencia_id: Mapped[int] = mapped_column(ForeignKey("asistencias.id"))
    foto: Mapped[str | None] = mapped_column(String(300))
    descripcion: Mapped[str | None] = mapped_column(Text)
