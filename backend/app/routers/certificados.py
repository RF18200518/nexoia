import secrets

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models import Certificado, PerfilEstudiante, Rol, Usuario
from app.schemas.certificado import (
    CertificadoCreate,
    CertificadoOut,
    VerificacionOut,
)
from app.services import certificado_pdf

router = APIRouter(prefix="/certificados", tags=["certificados"])


def _codigo() -> str:
    return "CERT-" + secrets.token_hex(4).upper()


def _out(db: Session, cert: Certificado) -> CertificadoOut:
    u = db.get(Usuario, cert.estudiante_id)
    return CertificadoOut(
        id=cert.id,
        estudiante_id=cert.estudiante_id,
        estudiante_nombre=u.nombre if u else None,
        horas=cert.horas,
        codigo_verificacion=cert.codigo_verificacion,
        fecha=cert.fecha,
    )


@router.get("", response_model=list[CertificadoOut])
def listar(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    certs = db.query(Certificado).order_by(Certificado.id.desc()).all()
    return [_out(db, c) for c in certs]


@router.post("", response_model=CertificadoOut, status_code=status.HTTP_201_CREATED)
def emitir(
    data: CertificadoCreate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    estudiante = db.get(Usuario, data.estudiante_id)
    if not estudiante or estudiante.rol != Rol.estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    horas = data.horas
    if horas is None:
        perfil = db.get(PerfilEstudiante, data.estudiante_id)
        horas = float(perfil.horas_acumuladas) if perfil else 0.0

    cert = Certificado(
        estudiante_id=data.estudiante_id,
        horas=horas,
        codigo_verificacion=_codigo(),
    )
    db.add(cert)
    db.commit()
    db.refresh(cert)
    return _out(db, cert)


@router.get("/mios", response_model=list[CertificadoOut])
def mios(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    certs = (
        db.query(Certificado)
        .filter(Certificado.estudiante_id == user.id)
        .order_by(Certificado.id.desc())
        .all()
    )
    return [_out(db, c) for c in certs]


@router.get("/verificar/{codigo}", response_model=VerificacionOut)
def verificar(codigo: str, db: Session = Depends(get_db)):
    cert = (
        db.query(Certificado)
        .filter(Certificado.codigo_verificacion == codigo.strip().upper())
        .first()
    )
    if not cert:
        return VerificacionOut(valido=False)
    u = db.get(Usuario, cert.estudiante_id)
    return VerificacionOut(
        valido=True,
        estudiante=u.nombre if u else None,
        horas=cert.horas,
        fecha=cert.fecha,
    )


@router.get("/{certificado_id}/pdf")
def pdf(
    certificado_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(get_current_user),
):
    cert = db.get(Certificado, certificado_id)
    if not cert:
        raise HTTPException(status_code=404, detail="Certificado no encontrado")
    if user.rol != Rol.coordinador and user.id != cert.estudiante_id:
        raise HTTPException(status_code=403, detail="No puedes ver este certificado")

    u = db.get(Usuario, cert.estudiante_id)
    contenido = certificado_pdf.generar_pdf(
        nombre=u.nombre if u else "Voluntario",
        horas=cert.horas,
        codigo=cert.codigo_verificacion,
        fecha=cert.fecha,
    )
    return Response(
        content=contenido,
        media_type="application/pdf",
        headers={
            "Content-Disposition": (
                f'attachment; filename="certificado-{cert.codigo_verificacion}.pdf"'
            )
        },
    )
