from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import EstadoNecesidad


class NecesidadBase(BaseModel):
    titulo: str
    descripcion: str | None = None
    naturaleza: str | None = None
    prioridad: str | None = None
    habilidades_requeridas: list[str] = []
    cupos: int = 1
    ubicacion: str | None = None
    fecha: datetime | None = None
    duracion: int | None = None


class NecesidadCreate(NecesidadBase):
    organizacion_id: int
    estado: EstadoNecesidad | None = None


class NecesidadUpdate(BaseModel):
    titulo: str | None = None
    descripcion: str | None = None
    naturaleza: str | None = None
    prioridad: str | None = None
    habilidades_requeridas: list[str] | None = None
    cupos: int | None = None
    ubicacion: str | None = None
    fecha: datetime | None = None
    duracion: int | None = None
    estado: EstadoNecesidad | None = None


class NecesidadOut(NecesidadBase):
    id: int
    organizacion_id: int
    estado: EstadoNecesidad
    visible_desde: datetime | None = None
    model_config = ConfigDict(from_attributes=True)


class NecesidadRecomendadaOut(NecesidadOut):
    compatibilidad: int = 0


class CandidatoOut(BaseModel):
    estudiante_id: int
    nombre: str
    correo: str
    carrera: str | None = None
    anio: int | None = None
    habilidades: list[str] = []
    horas_acumuladas: int = 0
    compatibilidad: int = 0
    invitado: bool = False


class InvitarIn(BaseModel):
    estudiante_id: int
