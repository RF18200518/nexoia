from pydantic import BaseModel, ConfigDict, EmailStr

from app.models.enums import Rol


class PerfilEstudianteBase(BaseModel):
    carrera: str | None = None
    anio: int | None = None
    habilidades: list[str] = []
    intereses: list[str] = []
    disponibilidad: dict | None = None


class PerfilEstudianteOut(PerfilEstudianteBase):
    horas_acumuladas: int = 0
    model_config = ConfigDict(from_attributes=True)


class PerfilUpdate(BaseModel):
    carrera: str | None = None
    anio: int | None = None
    habilidades: list[str] | None = None
    intereses: list[str] | None = None
    disponibilidad: dict | None = None


class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: EmailStr
    rol: Rol
    activo: bool
    perfil: PerfilEstudianteOut | None = None
    model_config = ConfigDict(from_attributes=True)


class EstudianteResumen(BaseModel):
    id: int
    nombre: str
    correo: EmailStr
    carrera: str | None = None
    anio: int | None = None
    habilidades: list[str] = []
    horas_acumuladas: int = 0
    certificados: int = 0
    sobrecarga: bool = False
