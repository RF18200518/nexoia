from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import EstadoOrganizacion


class Organizacion(Base):
    __tablename__ = "organizaciones"

    id: Mapped[int] = mapped_column(primary_key=True)
    usuario_id: Mapped[int | None] = mapped_column(
        ForeignKey("usuarios.id"), nullable=True
    )
    nombre: Mapped[str] = mapped_column(String(200))
    tipo: Mapped[str | None] = mapped_column(String(100))
    contacto: Mapped[str | None] = mapped_column(String(200))
    estado: Mapped[EstadoOrganizacion] = mapped_column(
        default=EstadoOrganizacion.pendiente
    )
    sitio: Mapped[str | None] = mapped_column(String(200))

    necesidades: Mapped[list["Necesidad"]] = relationship(back_populates="organizacion")
