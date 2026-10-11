from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models import Certificado, PerfilEstudiante, Rol, Usuario
from app.schemas.usuario import EstudianteResumen, PerfilUpdate, UsuarioOut

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

LIMITE_SOBRECARGA = 100


@router.get("/estudiantes", response_model=list[EstudianteResumen])
def estudiantes(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador)),
):
    """Lista de estudiantes con horas, certificados y alerta de sobrecarga."""
    conteos = dict(
        db.query(Certificado.estudiante_id, func.count(Certificado.id))
        .group_by(Certificado.estudiante_id)
        .all()
    )
    resultado: list[EstudianteResumen] = []
    for perfil in db.query(PerfilEstudiante).all():
        u = db.get(Usuario, perfil.usuario_id)
        if not u or not u.activo:
            continue
        horas = perfil.horas_acumuladas or 0
        resultado.append(
            EstudianteResumen(
                id=u.id,
                nombre=u.nombre,
                correo=u.correo,
                carrera=perfil.carrera,
                anio=perfil.anio,
                habilidades=list(perfil.habilidades or []),
                horas_acumuladas=horas,
                certificados=int(conteos.get(u.id, 0)),
                sobrecarga=horas >= LIMITE_SOBRECARGA,
            )
        )
    resultado.sort(key=lambda e: e.horas_acumuladas, reverse=True)
    return resultado


@router.get("/{usuario_id}", response_model=UsuarioOut)
def obtener(usuario_id: int, db: Session = Depends(get_db), user: Usuario = Depends(get_current_user)):
    u = db.get(Usuario, usuario_id)
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return u


@router.put("/me/perfil", response_model=UsuarioOut)
def actualizar_mi_perfil(
    data: PerfilUpdate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(get_current_user),
):
    if user.rol != Rol.estudiante:
        raise HTTPException(status_code=400, detail="Solo los estudiantes tienen perfil")

    perfil = db.get(PerfilEstudiante, user.id)
    if not perfil:
        perfil = PerfilEstudiante(usuario_id=user.id)
        db.add(perfil)

    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(perfil, campo, valor)

    db.commit()
    db.refresh(user)
    return user
