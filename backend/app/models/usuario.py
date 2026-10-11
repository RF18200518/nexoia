from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import Rol


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(150))
    correo: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    contrasena_hash: Mapped[str] = mapped_column(String(255))
    rol: Mapped[Rol] = mapped_column(default=Rol.estudiante)
    activo: Mapped[bool] = mapped_column(Boolean, default=True)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    perfil: Mapped["PerfilEstudiante | None"] = relationship(
        back_populates="usuario", uselist=False
    )


class PerfilEstudiante(Base):
    __tablename__ = "perfiles_estudiante"

    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"), primary_key=True)
    carrera: Mapped[str | None] = mapped_column(String(150))
    anio: Mapped[int | None] = mapped_column(Integer)
    habilidades: Mapped[list] = mapped_column(JSON, default=list)
    intereses: Mapped[list] = mapped_column(JSON, default=list)
    disponibilidad: Mapped[dict | None] = mapped_column(JSON)
    horas_acumuladas: Mapped[int] = mapped_column(Integer, default=0)
    simulacion_inicio: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True
    )
    simulacion_intervalo: Mapped[int | None] = mapped_column(Integer, nullable=True)

    usuario: Mapped[Usuario] = relationship(back_populates="perfil")
