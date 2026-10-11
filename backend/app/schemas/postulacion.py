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
    estudiante_nombre: str | None = None
    estudiante_correo: str | None = None
    necesidad_titulo: str | None = None
    necesidad_naturaleza: str | None = None
    necesidad_ubicacion: str | None = None
    horas: float = 0
    model_config = ConfigDict(from_attributes=True)


class PostulacionDetalleOut(PostulacionOut):
    necesidad_titulo: str | None = None
    necesidad_naturaleza: str | None = None
    necesidad_ubicacion: str | None = None
    horas: float = 0


class FeedUnificadoItem(BaseModel):
    id: int
    tipo: str  # "simulada" | "invitacion"
    necesidad_id: int
    titulo: str
    naturaleza: str | None = None
    ubicacion: str | None = None
    compatibilidad: int | None = None
    estado: str | None = None  # para invitaciones: "sugerido", "aceptado", etc.
    model_config = ConfigDict(from_attributes=True)
