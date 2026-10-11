from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models import (
    EstadoNecesidad,
    Necesidad,
    Organizacion,
    PerfilEstudiante,
    Postulacion,
    Rol,
    Usuario,
)

router = APIRouter(prefix="/indicadores", tags=["indicadores"])


@router.get("")
def indicadores(db: Session = Depends(get_db), user=Depends(require_roles(Rol.coordinador))):
    horas_total = db.query(func.coalesce(func.sum(PerfilEstudiante.horas_acumuladas), 0)).scalar()
    necesidades_total = db.query(func.count(Necesidad.id)).scalar()
    necesidades_publicadas = db.query(func.count(Necesidad.id)).filter(Necesidad.estado == EstadoNecesidad.publicada).scalar()
    necesidades_finalizadas = db.query(func.count(Necesidad.id)).filter(Necesidad.estado == EstadoNecesidad.finalizada).scalar()
    organizaciones_aprobadas = db.query(func.count(Organizacion.id)).filter(Organizacion.estado == "aprobada").scalar()
    estudiantes = db.query(func.count(Usuario.id)).filter(Usuario.rol == Rol.estudiante).scalar()
    postulaciones = db.query(func.count(Postulacion.id)).scalar()

    por_carrera = (
        db.query(
            PerfilEstudiante.carrera,
            func.count(PerfilEstudiante.usuario_id).label("cantidad"),
            func.coalesce(func.sum(PerfilEstudiante.horas_acumuladas), 0).label("horas"),
        )
        .filter(PerfilEstudiante.carrera.isnot(None))
        .group_by(PerfilEstudiante.carrera)
        .all()
    )

    return {
        "horas_total": int(horas_total or 0),
        "necesidades": {
            "total": int(necesidades_total or 0),
            "publicadas": int(necesidades_publicadas or 0),
            "finalizadas": int(necesidades_finalizadas or 0),
        },
        "organizaciones_aprobadas": int(organizaciones_aprobadas or 0),
        "estudiantes": int(estudiantes or 0),
        "postulaciones": int(postulaciones or 0),
        "por_carrera": [
            {
                "carrera": r[0],
                "cantidad": int(r[1] or 0),
                "horas": int(r[2] or 0),
            }
            for r in por_carrera
        ],
    }
