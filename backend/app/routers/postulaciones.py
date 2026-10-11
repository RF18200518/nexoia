from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import (
    Asistencia,
    EstadoPostulacion,
    Necesidad,
    Postulacion,
    Rol,
    Usuario,
)
from app.schemas.postulacion import (
    FeedUnificadoItem,
    PostulacionCreate,
    PostulacionDetalleOut,
    PostulacionOut,
    PostulacionUpdate,
)

router = APIRouter(prefix="/postulaciones", tags=["postulaciones"])


def _detalle(db: Session, p: Postulacion) -> PostulacionDetalleOut:
    necesidad = db.get(Necesidad, p.necesidad_id)
    horas = (
        db.query(func.coalesce(func.sum(Asistencia.horas), 0))
        .filter(
            Asistencia.estudiante_id == p.estudiante_id,
            Asistencia.necesidad_id == p.necesidad_id,
            Asistencia.validado.is_(True),
        )
        .scalar()
    )
    return PostulacionDetalleOut(
        id=p.id,
        estudiante_id=p.estudiante_id,
        necesidad_id=p.necesidad_id,
        estado=p.estado,
        necesidad_titulo=necesidad.titulo if necesidad else None,
        necesidad_naturaleza=necesidad.naturaleza if necesidad else None,
        necesidad_ubicacion=necesidad.ubicacion if necesidad else None,
        horas=float(horas or 0),
    )


def _decidir(
    db: Session, user: Usuario, necesidad_id: int, estado: EstadoPostulacion
) -> Postulacion:
    necesidad = db.get(Necesidad, necesidad_id)
    if not necesidad:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")

    p = (
        db.query(Postulacion)
        .filter(
            Postulacion.estudiante_id == user.id,
            Postulacion.necesidad_id == necesidad_id,
        )
        .first()
    )
    if p is None:
        p = Postulacion(
            estudiante_id=user.id, necesidad_id=necesidad_id, estado=estado
        )
        db.add(p)
    else:
        p.estado = estado
    db.commit()
    db.refresh(p)
    return p


@router.get("/mias", response_model=list[PostulacionDetalleOut])
def mias(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    postulaciones = (
        db.query(Postulacion)
        .filter(Postulacion.estudiante_id == user.id)
        .order_by(Postulacion.id.desc())
        .all()
    )
    return [_detalle(db, p) for p in postulaciones]


@router.get("/feed", response_model=list[FeedUnificadoItem])
def feed_unificado(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Feed unificado: propuestas simuladas + invitaciones reales (sugerido/aceptado)."""
    # 1. Invitaciones reales del estudiante (sugerido, aceptado)
    postulaciones = (
        db.query(Postulacion)
        .filter(
            Postulacion.estudiante_id == user.id,
            Postulacion.estado.in_([EstadoPostulacion.sugerido, EstadoPostulacion.aceptado]),
        )
        .order_by(Postulacion.id.desc())
        .all()
    )
    items: list[FeedUnificadoItem] = []
    for p in postulaciones:
        n = db.get(Necesidad, p.necesidad_id)
        if n and n.estado == "publicada":
            items.append(
                FeedUnificadoItem(
                    id=p.id,
                    tipo="invitacion",
                    necesidad_id=n.id,
                    titulo=n.titulo,
                    naturaleza=n.naturaleza,
                    ubicacion=n.ubicacion,
                    compatibilidad=None,
                    estado=p.estado.value,
                )
            )

    # 2. Propuestas simuladas (solo si no hay invitación para esa necesidad)
    from app.services.simulacion import get_propuestas_para_estudiante
    simuladas = get_propuestas_para_estudiante(db, user.id)
    ids_invitados = {item.necesidad_id for item in items}
    for s in simuladas:
        if s.id not in ids_invitados:
            items.append(
                FeedUnificadoItem(
                    id=s.id,
                    tipo="simulada",
                    necesidad_id=s.id,
                    titulo=s.titulo,
                    naturaleza=s.naturaleza,
                    ubicacion=s.ubicacion,
                    compatibilidad=s.compatibilidad,
                    estado=None,
                )
            )

    # Ordenar: invitaciones primero, luego simuladas por compatibilidad
    items.sort(key=lambda x: (x.tipo == "simulada", -(x.compatibilidad or 0)))
    return items


@router.post("", response_model=PostulacionDetalleOut, status_code=status.HTTP_201_CREATED)
def postular(
    data: PostulacionCreate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Aceptar una oportunidad."""
    p = _decidir(db, user, data.necesidad_id, EstadoPostulacion.aceptado)
    return _detalle(db, p)


@router.post("/rechazar", response_model=PostulacionDetalleOut)
def rechazar(
    data: PostulacionCreate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Rechazar / descartar una oportunidad."""
    p = _decidir(db, user, data.necesidad_id, EstadoPostulacion.rechazado)
    return _detalle(db, p)


@router.patch("/{postulacion_id}", response_model=PostulacionOut)
def cambiar_estado(
    postulacion_id: int,
    data: PostulacionUpdate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    p = db.get(Postulacion, postulacion_id)
    if not p:
        raise HTTPException(status_code=404, detail="Postulación no encontrada")
    p.estado = data.estado
    db.commit()
    db.refresh(p)
    return p
