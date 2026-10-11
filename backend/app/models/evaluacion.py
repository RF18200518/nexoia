from sqlalchemy import ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Evaluacion(Base):
    __tablename__ = "evaluaciones"

    id: Mapped[int] = mapped_column(primary_key=True)
    evaluador_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    evaluado_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    puntuacion: Mapped[int | None] = mapped_column(Integer)
    comentario: Mapped[str | None] = mapped_column(Text)
