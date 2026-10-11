from pydantic import BaseModel

from app.schemas.necesidad import NecesidadRecomendadaOut


class InteresOut(BaseModel):
    clave: str
    label: str
    emoji: str
    naturaleza: str


class FeedSimulacionOut(BaseModel):
    activa: bool
    total: int
    recibidas: int
    siguiente_en: int | None = None
    intervalo: int
    propuestas: list[NecesidadRecomendadaOut]
