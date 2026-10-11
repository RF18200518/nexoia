import enum


class Rol(str, enum.Enum):
    estudiante = "estudiante"
    organizacion = "organizacion"
    coordinador = "coordinador"


class EstadoOrganizacion(str, enum.Enum):
    pendiente = "pendiente"
    aprobada = "aprobada"


class EstadoNecesidad(str, enum.Enum):
    borrador = "borrador"
    publicada = "publicada"
    en_curso = "en_curso"
    finalizada = "finalizada"
    cancelada = "cancelada"


class EstadoPostulacion(str, enum.Enum):
    sugerido = "sugerido"
    aceptado = "aceptado"
    rechazado = "rechazado"
    validado = "validado"
