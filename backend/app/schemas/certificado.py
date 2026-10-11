from datetime import datetime

from pydantic import BaseModel, ConfigDict


class CertificadoCreate(BaseModel):
    estudiante_id: int
    horas: float | None = None


class CertificadoOut(BaseModel):
    id: int
    estudiante_id: int
    estudiante_nombre: str | None = None
    horas: float
    codigo_verificacion: str
    fecha: datetime
    model_config = ConfigDict(from_attributes=True)


class VerificacionOut(BaseModel):
    valido: bool
    estudiante: str | None = None
    horas: float | None = None
    fecha: datetime | None = None
