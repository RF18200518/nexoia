"""Motor de compatibilidad (match) estudiante ↔ necesidad.

Versión v1 **heurística** (base del futuro modelo de IA). Combina los intereses
del estudiante con las habilidades requeridas por la necesidad y devuelve un
porcentaje 0–100. La decisión final siempre es humana: la IA solo apoya.
"""

from app.models import Necesidad, PerfilEstudiante
from app.services.catalogo import POR_CLAVE

PESO_INTERES = 75
PESO_HABILIDADES = 25
BONO_SIN_REQUISITOS = 15


def _norm(texto: str | None) -> str:
    return (texto or "").strip().lower()


def puntaje(perfil: PerfilEstudiante | None, necesidad: Necesidad) -> int:
    intereses = list(perfil.intereses) if perfil and perfil.intereses else []
    habilidades = list(perfil.habilidades) if perfil and perfil.habilidades else []

    naturaleza = _norm(necesidad.naturaleza)
    naturalezas_interes = {
        _norm(POR_CLAVE[c]["naturaleza"]) for c in intereses if c in POR_CLAVE
    }

    score = 0

    if naturaleza and naturaleza in naturalezas_interes:
        score += PESO_INTERES

    requeridas = {_norm(h) for h in (necesidad.habilidades_requeridas or []) if h}
    tiene = {_norm(h) for h in habilidades if h}
    if requeridas:
        coincidencias = len(requeridas & tiene)
        score += round(PESO_HABILIDADES * coincidencias / len(requeridas))
    else:
        score += BONO_SIN_REQUISITOS

    return max(0, min(100, score))


def aplicar(perfil: PerfilEstudiante | None, necesidades: list[Necesidad]) -> list[Necesidad]:
    """Adjunta el atributo dinámico `compatibilidad` a cada necesidad."""
    for n in necesidades:
        n.compatibilidad = puntaje(perfil, n)
    return necesidades
