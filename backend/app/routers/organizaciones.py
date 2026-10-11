from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models import (
    Asistencia,
    EstadoNecesidad,
    EstadoOrganizacion,
    Necesidad,
    Organizacion,
    Postulacion,
    Rol,
    Usuario,
)
from app.schemas.organizacion import (
    EstadoUpdate,
    OrganizacionCreate,
    OrganizacionOut,
    OrganizacionUpdate,
)

router = APIRouter(prefix="/organizaciones", tags=["organizaciones"])


@router.get("", response_model=list[OrganizacionOut])
def listar(
    estado: EstadoOrganizacion | None = None,
    db: Session = Depends(get_db),
    user: Usuario = Depends(get_current_user),
):
    q = db.query(Organizacion)
    if estado:
        q = q.filter(Organizacion.estado == estado)
    return q.order_by(Organizacion.nombre).all()


@router.get("/mia", response_model=OrganizacionOut)
def mi_organizacion(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.organizacion)),
):
    org = (
        db.query(Organizacion)
        .filter(Organizacion.usuario_id == user.id)
        .first()
    )
    if not org:
        raise HTTPException(
            status_code=404, detail="No tienes una organización asociada"
        )
    return org


@router.post("", response_model=OrganizacionOut, status_code=status.HTTP_201_CREATED)
def crear(
    data: OrganizacionCreate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    org = Organizacion(**data.model_dump())
    db.add(org)
    db.commit()
    db.refresh(org)
    return org


@router.patch("/{org_id}/estado", response_model=OrganizacionOut)
def cambiar_estado(
    org_id: int,
    data: EstadoUpdate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    org = db.get(Organizacion, org_id)
    if not org:
        raise HTTPException(status_code=404, detail="Organización no encontrada")
    org.estado = data.estado
    db.commit()
    db.refresh(org)
    return org


@router.get("/{org_id}/indicadores")
def indicadores_org(
    org_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.organizacion, Rol.coordinador)),
):
    """KPIs de impacto de una organización."""
    org = db.get(Organizacion, org_id)
    if not org:
        raise HTTPException(status_code=404, detail="Organización no encontrada")
    if user.rol == Rol.organizacion and org.usuario_id != user.id:
        raise HTTPException(status_code=403, detail="No puedes ver esta organización")

    necesidad_ids = [
        nid
        for (nid,) in db.query(Necesidad.id)
        .filter(Necesidad.organizacion_id == org_id)
        .all()
    ]

    total = len(necesidad_ids)
    publicadas = (
        db.query(func.count(Necesidad.id))
        .filter(
            Necesidad.organizacion_id == org_id,
            Necesidad.estado == EstadoNecesidad.publicada,
        )
        .scalar()
    )
    finalizadas = (
        db.query(func.count(Necesidad.id))
        .filter(
            Necesidad.organizacion_id == org_id,
            Necesidad.estado == EstadoNecesidad.finalizada,
        )
        .scalar()
    )
    postulaciones = (
        db.query(func.count(Postulacion.id))
        .filter(Postulacion.necesidad_id.in_(necesidad_ids))
        .scalar()
        if necesidad_ids
        else 0
    )
    voluntarios = (
        db.query(func.count(func.distinct(Postulacion.estudiante_id)))
        .filter(Postulacion.necesidad_id.in_(necesidad_ids))
        .scalar()
        if necesidad_ids
        else 0
    )
    horas = (
        db.query(func.coalesce(func.sum(Asistencia.horas), 0))
        .filter(
            Asistencia.necesidad_id.in_(necesidad_ids),
            Asistencia.validado.is_(True),
        )
        .scalar()
        if necesidad_ids
        else 0
    )

    return {
        "organizacion_id": org_id,
        "nombre": org.nombre,
        "necesidades": {
            "total": int(total or 0),
            "publicadas": int(publicadas or 0),
            "finalizadas": int(finalizadas or 0),
        },
        "postulaciones": int(postulaciones or 0),
        "voluntarios": int(voluntarios or 0),
        "horas": int(horas or 0),
    }
