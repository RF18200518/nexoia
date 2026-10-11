import csv
import io

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import (
    Asistencia,
    Certificado,
    EstadoNecesidad,
    Necesidad,
    Organizacion,
    PerfilEstudiante,
    Postulacion,
    Rol,
    Usuario,
)

router = APIRouter(prefix="/reportes", tags=["reportes"])

LIMITE_SOBRECARGA = 100


@router.get("/resumen")
def resumen(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    """Resumen agregado para reportes del panel coordinador."""
    estudiantes = db.query(func.count(Usuario.id)).filter(Usuario.rol == Rol.estudiante).scalar()
    organizaciones = db.query(func.count(Organizacion.id)).scalar()
    necesidades = db.query(func.count(Necesidad.id)).scalar()
    necesidades_publicadas = (
        db.query(func.count(Necesidad.id))
        .filter(Necesidad.estado == EstadoNecesidad.publicada)
        .scalar()
    )
    postulaciones = db.query(func.count(Postulacion.id)).scalar()
    validaciones = (
        db.query(func.count(Asistencia.id))
        .filter(Asistencia.validado.is_(True))
        .scalar()
    )
    horas_totales = (
        db.query(func.coalesce(func.sum(PerfilEstudiante.horas_acumuladas), 0)).scalar()
    )
    certificados = db.query(func.count(Certificado.id)).scalar()
    sobrecarga = (
        db.query(func.count(PerfilEstudiante.usuario_id))
        .filter(PerfilEstudiante.horas_acumuladas >= LIMITE_SOBRECARGA)
        .scalar()
    )

    por_carrera = (
        db.query(
            PerfilEstudiante.carrera,
            func.count(PerfilEstudiante.usuario_id).label("cantidad"),
            func.coalesce(func.sum(PerfilEstudiante.horas_acumuladas), 0).label("horas"),
        )
        .filter(PerfilEstudiante.carrera.isnot(None))
        .group_by(PerfilEstudiante.carrera)
        .order_by(func.coalesce(func.sum(PerfilEstudiante.horas_acumuladas), 0).desc())
        .all()
    )

    top_organizaciones = (
        db.query(
            Organizacion.id,
            Organizacion.nombre,
            func.count(Necesidad.id).label("necesidades"),
        )
        .join(Necesidad, Necesidad.organizacion_id == Organizacion.id, isouter=True)
        .group_by(Organizacion.id, Organizacion.nombre)
        .order_by(func.count(Necesidad.id).desc())
        .limit(5)
        .all()
    )

    return {
        "totales": {
            "estudiantes": int(estudiantes or 0),
            "organizaciones": int(organizaciones or 0),
            "necesidades": int(necesidades or 0),
            "necesidades_publicadas": int(necesidades_publicadas or 0),
            "postulaciones": int(postulaciones or 0),
            "validaciones": int(validaciones or 0),
            "horas_totales": int(horas_totales or 0),
            "certificados": int(certificados or 0),
            "sobrecarga": int(sobrecarga or 0),
        },
        "por_carrera": [
            {"carrera": r[0], "cantidad": int(r[1] or 0), "horas": int(r[2] or 0)}
            for r in por_carrera
        ],
        "top_organizaciones": [
            {"id": r[0], "nombre": r[1], "necesidades": int(r[2] or 0)}
            for r in top_organizaciones
        ],
    }


@router.get("/horas.csv")
def horas_csv(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    """Exporta en CSV las horas y certificados por estudiante."""
    conteos = dict(
        db.query(Certificado.estudiante_id, func.count(Certificado.id))
        .group_by(Certificado.estudiante_id)
        .all()
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(
        ["nombre", "correo", "carrera", "anio", "horas_acumuladas", "certificados", "sobrecarga"]
    )
    for perfil in db.query(PerfilEstudiante).all():
        u = db.get(Usuario, perfil.usuario_id)
        if not u or not u.activo:
            continue
        horas = perfil.horas_acumuladas or 0
        writer.writerow(
            [
                u.nombre,
                u.correo,
                perfil.carrera or "",
                perfil.anio or "",
                horas,
                int(conteos.get(u.id, 0)),
                "si" if horas >= LIMITE_SOBRECARGA else "no",
            ]
        )

    contenido = buffer.getvalue().encode("utf-8-sig")
    return StreamingResponse(
        io.BytesIO(contenido),
        media_type="text/csv",
        headers={"Content-Disposition": 'attachment; filename="horas_estudiantes.csv"'},
    )
