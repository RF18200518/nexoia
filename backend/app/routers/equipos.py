from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import (
    Equipo,
    Necesidad,
    PerfilEstudiante,
    Postulacion,
    Rol,
    Usuario,
)
from app.schemas.equipo import (
    ArmarEquipoIn,
    CrearEquipoIn,
    EquipoOut,
    IntegranteOut,
)
from app.services import match

router = APIRouter(prefix="/equipos", tags=["equipos"])


def _perfil(db: Session, usuario_id: int) -> PerfilEstudiante | None:
    return db.get(PerfilEstudiante, usuario_id)


def _rol(perfil: PerfilEstudiante | None, necesidad: Necesidad) -> str:
    requeridas = [h for h in (necesidad.habilidades_requeridas or []) if h]
    tiene = [h for h in (perfil.habilidades or []) if h] if perfil else []
    for habilidad in tiene:
        if habilidad in requeridas:
            return habilidad
    return "Apoyo"


def _integrante(db: Session, usuario_id: int, necesidad: Necesidad) -> dict | None:
    u = db.get(Usuario, usuario_id)
    if not u:
        return None
    perfil = _perfil(db, usuario_id)
    return {
        "estudiante_id": u.id,
        "nombre": u.nombre,
        "correo": u.correo,
        "carrera": perfil.carrera if perfil else None,
        "rol": _rol(perfil, necesidad),
        "compatibilidad": match.puntaje(perfil, necesidad),
    }


def _out(db: Session, equipo: Equipo) -> EquipoOut:
    necesidad = db.get(Necesidad, equipo.necesidad_id)
    return EquipoOut(
        id=equipo.id,
        necesidad_id=equipo.necesidad_id,
        necesidad_titulo=necesidad.titulo if necesidad else None,
        integrantes=[IntegranteOut(**i) for i in (equipo.integrantes or [])],
    )


def _candidatos(db: Session, necesidad: Necesidad) -> list[Usuario]:
    ids = [
        eid
        for (eid,) in db.query(Postulacion.estudiante_id)
        .filter(Postulacion.necesidad_id == necesidad.id)
        .all()
    ]
    if ids:
        return (
            db.query(Usuario)
            .filter(Usuario.id.in_(ids), Usuario.rol == Rol.estudiante)
            .all()
        )
    return (
        db.query(Usuario)
        .filter(Usuario.rol == Rol.estudiante, Usuario.activo.is_(True))
        .all()
    )


@router.get("", response_model=list[EquipoOut])
def listar(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    equipos = db.query(Equipo).order_by(Equipo.id.desc()).all()
    return [_out(db, e) for e in equipos]


@router.post("", response_model=EquipoOut, status_code=status.HTTP_201_CREATED)
def crear(
    data: CrearEquipoIn,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    necesidad = db.get(Necesidad, data.necesidad_id)
    if not necesidad:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")

    integrantes = []
    for uid in dict.fromkeys(data.estudiante_ids):
        info = _integrante(db, uid, necesidad)
        if info:
            integrantes.append(info)
    if not integrantes:
        raise HTTPException(status_code=400, detail="Indica al menos un estudiante válido")

    equipo = Equipo(necesidad_id=necesidad.id, integrantes=integrantes)
    db.add(equipo)
    db.commit()
    db.refresh(equipo)
    return _out(db, equipo)


@router.post("/armar", response_model=EquipoOut, status_code=status.HTTP_201_CREATED)
def armar(
    data: ArmarEquipoIn,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    """Arma automáticamente un equipo multidisciplinario para una necesidad.

    Prioriza cubrir las habilidades requeridas y la diversidad de carreras,
    ordenando candidatos por compatibilidad (match).
    """
    necesidad = db.get(Necesidad, data.necesidad_id)
    if not necesidad:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")

    candidatos = _candidatos(db, necesidad)
    if not candidatos:
        raise HTTPException(status_code=400, detail="No hay estudiantes candidatos")

    limite = data.max_integrantes or necesidad.cupos or 1
    requeridas = {h for h in (necesidad.habilidades_requeridas or []) if h}

    evaluados = []
    for u in candidatos:
        perfil = _perfil(db, u.id)
        evaluados.append((match.puntaje(perfil, necesidad), u, perfil))
    evaluados.sort(key=lambda t: t[0], reverse=True)

    elegidos: list[Usuario] = []
    carreras: set[str] = set()
    cubiertas: set[str] = set()

    for _, u, perfil in evaluados:
        if len(elegidos) >= limite:
            break
        tiene = {h for h in (perfil.habilidades or []) if h} if perfil else set()
        nuevas = (tiene & requeridas) - cubiertas
        carrera = perfil.carrera if perfil else None
        if nuevas or (carrera and carrera not in carreras):
            elegidos.append(u)
            cubiertas |= nuevas
            if carrera:
                carreras.add(carrera)

    for _, u, _ in evaluados:
        if len(elegidos) >= limite:
            break
        if u.id not in {e.id for e in elegidos}:
            elegidos.append(u)

    integrantes = [
        info
        for info in (_integrante(db, u.id, necesidad) for u in elegidos)
        if info
    ]

    equipo = Equipo(necesidad_id=necesidad.id, integrantes=integrantes)
    db.add(equipo)
    db.commit()
    db.refresh(equipo)
    return _out(db, equipo)


@router.delete("/{equipo_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar(
    equipo_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    equipo = db.get(Equipo, equipo_id)
    if not equipo:
        raise HTTPException(status_code=404, detail="Equipo no encontrado")
    db.delete(equipo)
    db.commit()
    return None
