from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import EstadoNecesidad
from app.models.organizacion import Organizacion


class Necesidad(Base):
    __tablename__ = "necesidades"

    id: Mapped[int] = mapped_column(primary_key=True)
    organizacion_id: Mapped[int] = mapped_column(ForeignKey("organizaciones.id"))
    titulo: Mapped[str] = mapped_column(String(200))
    descripcion: Mapped[str | None] = mapped_column(Text)
    naturaleza: Mapped[str | None] = mapped_column(String(100))
    prioridad: Mapped[str | None] = mapped_column(String(50))
    habilidades_requeridas: Mapped[list] = mapped_column(JSON, default=list)
    cupos: Mapped[int] = mapped_column(Integer, default=1)
    ubicacion: Mapped[str | None] = mapped_column(String(200))
    fecha: Mapped[datetime | None] = mapped_column(DateTime)
    duracion: Mapped[int | None] = mapped_column(Integer, nullable=True)
    estado: Mapped[EstadoNecesidad] = mapped_column(default=EstadoNecesidad.borrador)
    visible_desde: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    simulacion_estudiante_id: Mapped[int | None] = mapped_column(
        ForeignKey("usuarios.id"), nullable=True
    )

    organizacion: Mapped[Organizacion] = relationship(back_populates="necesidades")
