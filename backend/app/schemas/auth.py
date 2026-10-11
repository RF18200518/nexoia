from pydantic import BaseModel, EmailStr, field_validator

from app.models.enums import Rol

DOMINIOS_PERMITIDOS = ("@gmail.com",)


def validar_gmail(correo: str) -> str:
    correo = correo.strip().lower()
    if not correo.endswith(DOMINIOS_PERMITIDOS):
        raise ValueError("El correo debe ser obligatoriamente @gmail.com")
    return correo


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    correo: str | None = None
    rol: Rol | None = None


class RegisterIn(BaseModel):
    nombre: str
    correo: EmailStr
    contrasena: str
    rol: Rol = Rol.estudiante
    intereses: list[str] = []

    @field_validator("correo")
    @classmethod
    def correo_gmail(cls, v: str) -> str:
        return validar_gmail(str(v))

    @field_validator("contrasena")
    @classmethod
    def contrasena_minima(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("La contraseña debe tener al menos 6 caracteres")
        return v


class LoginIn(BaseModel):
    correo: EmailStr
    contrasena: str
