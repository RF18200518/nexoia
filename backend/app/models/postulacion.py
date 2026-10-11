from sqlalchemy import ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.enums import EstadoPostulacion


class Postulacion(Base):
    __tablename__ = "postulaciones"

    id: Mapped[int] = mapped_column(primary_key=True)
    estudiante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    necesidad_id: Mapped[int] = mapped_column(ForeignKey("necesidades.id"))
    estado: Mapped[EstadoPostulacion] = mapped_column(
        default=EstadoPostulacion.sugerido
    )


class Equipo(Base):
    __tablename__ = "equipos"

    id: Mapped[int] = mapped_column(primary_key=True)
    necesidad_id: Mapped[int] = mapped_column(ForeignKey("necesidades.id"))
    integrantes: Mapped[list] = mapped_column(JSON, default=list)
