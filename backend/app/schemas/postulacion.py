from pydantic import BaseModel, ConfigDict

from app.models.enums import EstadoPostulacion


class PostulacionCreate(BaseModel):
    necesidad_id: int


class PostulacionUpdate(BaseModel):
    estado: EstadoPostulacion


class PostulacionOut(BaseModel):
    id: int
    estudiante_id: int
    necesidad_id: int
    estado: EstadoPostulacion
    model_config = ConfigDict(from_attributes=True)


class PostulacionDetalleOut(PostulacionOut):
    necesidad_titulo: str | None = None
    necesidad_naturaleza: str | None = None
    necesidad_ubicacion: str | None = None
    horas: float = 0
