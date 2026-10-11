from pydantic import BaseModel, ConfigDict


class IntegranteOut(BaseModel):
    estudiante_id: int
    nombre: str
    correo: str | None = None
    carrera: str | None = None
    rol: str | None = None
    compatibilidad: int | None = None


class EquipoOut(BaseModel):
    id: int
    necesidad_id: int
    necesidad_titulo: str | None = None
    integrantes: list[IntegranteOut] = []
    model_config = ConfigDict(from_attributes=True)


class CrearEquipoIn(BaseModel):
    necesidad_id: int
    estudiante_ids: list[int]


class ArmarEquipoIn(BaseModel):
    necesidad_id: int
    max_integrantes: int | None = None
