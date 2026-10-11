from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Certificado(Base):
    __tablename__ = "certificados"

    id: Mapped[int] = mapped_column(primary_key=True)
    estudiante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    horas: Mapped[float] = mapped_column(Float, default=0)
    codigo_verificacion: Mapped[str] = mapped_column(
        String(100), unique=True, index=True
    )
    fecha: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
