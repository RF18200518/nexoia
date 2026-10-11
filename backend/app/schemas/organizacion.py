from pydantic import BaseModel, ConfigDict

from app.models.enums import EstadoOrganizacion


class OrganizacionBase(BaseModel):
    nombre: str
    tipo: str | None = None
    contacto: str | None = None
    sitio: str | None = None


class OrganizacionCreate(OrganizacionBase):
    pass


class OrganizacionUpdate(BaseModel):
    nombre: str | None = None
    tipo: str | None = None
    contacto: str | None = None
    sitio: str | None = None
    estado: EstadoOrganizacion | None = None


class EstadoUpdate(BaseModel):
    estado: EstadoOrganizacion


class OrganizacionOut(OrganizacionBase):
    id: int
    usuario_id: int | None = None
    estado: EstadoOrganizacion
    model_config = ConfigDict(from_attributes=True)
