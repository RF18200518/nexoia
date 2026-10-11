from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AsistenciaGenerarIn(BaseModel):
    necesidad_id: int


class AsistenciaOut(BaseModel):
    id: int
    estudiante_id: int
    necesidad_id: int
    horas: float
    validado: bool
    codigo_qr: str | None = None
    fecha: datetime
    model_config = ConfigDict(from_attributes=True)


class QrGeneradoOut(BaseModel):
    codigo: str
    expira_en: datetime
    segundos: int
    necesidad_id: int
    necesidad_titulo: str | None = None


class ValidarIn(BaseModel):
    codigo: str


class ValidarOut(BaseModel):
    ok: bool
    mensaje: str
    estudiante: str | None = None
    necesidad: str | None = None
    horas: float | None = None
