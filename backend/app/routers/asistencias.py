import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import (
    Asistencia,
    EstadoPostulacion,
    Necesidad,
    PerfilEstudiante,
    Postulacion,
    Rol,
    Usuario,
)
from app.schemas.asistencia import (
    AsistenciaGenerarIn,
    AsistenciaOut,
    QrGeneradoOut,
    ValidarIn,
    ValidarOut,
)

router = APIRouter(prefix="/asistencias", tags=["asistencias"])

HORAS_ACTIVIDAD = 4.0
QR_SEGUNDOS = 120


def _nuevo_codigo() -> str:
    return "NX-" + secrets.token_hex(4).upper()


@router.get("/mias", response_model=list[AsistenciaOut])
def mias(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    return (
        db.query(Asistencia)
        .filter(Asistencia.estudiante_id == user.id)
        .order_by(Asistencia.id.desc())
        .all()
    )


@router.post("/generar", response_model=QrGeneradoOut)
def generar(
    data: AsistenciaGenerarIn,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Genera (o reutiliza) un código QR temporal para marcar asistencia."""
    necesidad = db.get(Necesidad, data.necesidad_id)
    if not necesidad:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")

    aceptada = (
        db.query(Postulacion)
        .filter(
            Postulacion.estudiante_id == user.id,
            Postulacion.necesidad_id == data.necesidad_id,
            Postulacion.estado.in_(
                [EstadoPostulacion.aceptado, EstadoPostulacion.validado]
            ),
        )
        .first()
    )
    if not aceptada:
        raise HTTPException(
            status_code=400, detail="Primero debes aceptar esta oportunidad"
        )

    ahora = datetime.now()
    asistencia = (
        db.query(Asistencia)
        .filter(
            Asistencia.estudiante_id == user.id,
            Asistencia.necesidad_id == data.necesidad_id,
            Asistencia.validado.is_(False),
        )
        .order_by(Asistencia.id.desc())
        .first()
    )

    if asistencia and asistencia.expira_en and asistencia.expira_en > ahora:
        codigo = asistencia.codigo_qr
        expira = asistencia.expira_en
    else:
        codigo = _nuevo_codigo()
        expira = ahora + timedelta(seconds=QR_SEGUNDOS)
        if asistencia is None:
            asistencia = Asistencia(
                estudiante_id=user.id,
                necesidad_id=data.necesidad_id,
                codigo_qr=codigo,
                expira_en=expira,
                horas=0,
                validado=False,
            )
            db.add(asistencia)
        else:
            asistencia.codigo_qr = codigo
            asistencia.expira_en = expira
        db.commit()

    restante = max(0, int((expira - datetime.now()).total_seconds()))
    return QrGeneradoOut(
        codigo=codigo,
        expira_en=expira,
        segundos=restante,
        necesidad_id=data.necesidad_id,
        necesidad_titulo=necesidad.titulo,
    )


@router.post("/validar", response_model=ValidarOut)
def validar(
    data: ValidarIn,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    """El coordinador/organización valida el código escaneado y suma horas."""
    codigo = data.codigo.strip().upper()
    asistencia = (
        db.query(Asistencia)
        .filter(Asistencia.codigo_qr == codigo)
        .order_by(Asistencia.id.desc())
        .first()
    )
    if not asistencia:
        return ValidarOut(ok=False, mensaje="Código no encontrado")
    if asistencia.validado:
        return ValidarOut(ok=False, mensaje="Este código ya fue validado")
    if asistencia.expira_en and asistencia.expira_en < datetime.now():
        return ValidarOut(ok=False, mensaje="El código expiró, pídele uno nuevo")

    estudiante = db.get(Usuario, asistencia.estudiante_id)
    necesidad = db.get(Necesidad, asistencia.necesidad_id)

    asistencia.validado = True
    asistencia.horas = HORAS_ACTIVIDAD
    asistencia.fecha = datetime.now()

    perfil = db.get(PerfilEstudiante, asistencia.estudiante_id)
    if perfil:
        perfil.horas_acumuladas = (perfil.horas_acumuladas or 0) + int(HORAS_ACTIVIDAD)

    postulacion = (
        db.query(Postulacion)
        .filter(
            Postulacion.estudiante_id == asistencia.estudiante_id,
            Postulacion.necesidad_id == asistencia.necesidad_id,
        )
        .first()
    )
    if postulacion:
        postulacion.estado = EstadoPostulacion.validado

    db.commit()

    return ValidarOut(
        ok=True,
        mensaje="Asistencia validada correctamente",
        estudiante=estudiante.nombre if estudiante else None,
        necesidad=necesidad.titulo if necesidad else None,
        horas=HORAS_ACTIVIDAD,
    )
