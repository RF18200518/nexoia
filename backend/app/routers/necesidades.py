from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.models import (
    EstadoNecesidad,
    EstadoPostulacion,
    Necesidad,
    Organizacion,
    PerfilEstudiante,
    Postulacion,
    Rol,
    Usuario,
)
from app.schemas.necesidad import (
    CandidatoOut,
    InvitarIn,
    NecesidadCreate,
    NecesidadOut,
    NecesidadRecomendadaOut,
    NecesidadUpdate,
)
from app.schemas.postulacion import PostulacionOut
from app.services import match

router = APIRouter(prefix="/necesidades", tags=["necesidades"])


@router.get("", response_model=list[NecesidadOut])
def listar(
    estado: EstadoNecesidad | None = None,
    organizacion_id: int | None = None,
    db: Session = Depends(get_db),
    user: Usuario = Depends(get_current_user),
):
    q = db.query(Necesidad).filter(Necesidad.simulacion_estudiante_id.is_(None))
    if estado:
        q = q.filter(Necesidad.estado == estado)
    if organizacion_id:
        q = q.filter(Necesidad.organizacion_id == organizacion_id)
    return q.order_by(Necesidad.id.desc()).all()


@router.get("/recomendadas", response_model=list[NecesidadRecomendadaOut])
def recomendadas(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Oportunidades ordenadas por compatibilidad con el perfil del estudiante."""
    perfil = db.get(PerfilEstudiante, user.id)
    decididas = db.query(Postulacion.necesidad_id).filter(
        Postulacion.estudiante_id == user.id
    )
    necesidades = (
        db.query(Necesidad)
        .filter(
            Necesidad.simulacion_estudiante_id.is_(None),
            Necesidad.estado == EstadoNecesidad.publicada,
            ~Necesidad.id.in_(decididas),
        )
        .all()
    )
    match.aplicar(perfil, necesidades)
    necesidades.sort(key=lambda n: n.compatibilidad, reverse=True)
    return necesidades


@router.get("/{necesidad_id}", response_model=NecesidadOut)
def obtener(
    necesidad_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(get_current_user),
):
    n = db.get(Necesidad, necesidad_id)
    if not n:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")
    return n


@router.post("", response_model=NecesidadOut, status_code=status.HTTP_201_CREATED)
def crear(
    data: NecesidadCreate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    org = db.get(Organizacion, data.organizacion_id)
    if not org:
        raise HTTPException(status_code=404, detail="Organización no encontrada")

    datos = data.model_dump()
    estado = datos.pop("estado", None)
    necesidad = Necesidad(**datos)
    if estado:
        necesidad.estado = estado
    db.add(necesidad)
    db.commit()
    db.refresh(necesidad)
    return necesidad


def _verificar_dueno(db: Session, necesidad: Necesidad, user: Usuario) -> None:
    if user.rol == Rol.organizacion:
        org = db.get(Organizacion, necesidad.organizacion_id)
        if not org or org.usuario_id != user.id:
            raise HTTPException(
                status_code=403, detail="No puedes gestionar esta necesidad"
            )


@router.get("/{necesidad_id}/candidatos", response_model=list[CandidatoOut])
def candidatos(
    necesidad_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    """Estudiantes ordenados por compatibilidad con la necesidad."""
    n = db.get(Necesidad, necesidad_id)
    if not n:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")
    _verificar_dueno(db, n, user)

    invitados = {
        eid
        for (eid,) in db.query(Postulacion.estudiante_id)
        .filter(Postulacion.necesidad_id == necesidad_id)
        .all()
    }

    resultado: list[CandidatoOut] = []
    for perfil in db.query(PerfilEstudiante).all():
        u = db.get(Usuario, perfil.usuario_id)
        if not u or not u.activo:
            continue
        resultado.append(
            CandidatoOut(
                estudiante_id=u.id,
                nombre=u.nombre,
                correo=u.correo,
                carrera=perfil.carrera,
                anio=perfil.anio,
                habilidades=list(perfil.habilidades or []),
                horas_acumuladas=perfil.horas_acumuladas or 0,
                compatibilidad=match.puntaje(perfil, n),
                invitado=u.id in invitados,
            )
        )
    resultado.sort(key=lambda c: c.compatibilidad, reverse=True)
    return resultado


@router.post("/{necesidad_id}/invitar", response_model=PostulacionOut)
def invitar(
    necesidad_id: int,
    data: InvitarIn,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    """Invita a un estudiante a la necesidad (crea postulación en estado `sugerido`)."""
    n = db.get(Necesidad, necesidad_id)
    if not n:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")
    _verificar_dueno(db, n, user)

    estudiante = db.get(Usuario, data.estudiante_id)
    if not estudiante or estudiante.rol != Rol.estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    p = (
        db.query(Postulacion)
        .filter(
            Postulacion.estudiante_id == data.estudiante_id,
            Postulacion.necesidad_id == necesidad_id,
        )
        .first()
    )
    if p is None:
        p = Postulacion(
            estudiante_id=data.estudiante_id,
            necesidad_id=necesidad_id,
            estado=EstadoPostulacion.sugerido,
        )
        db.add(p)
    elif p.estado not in (EstadoPostulacion.aceptado, EstadoPostulacion.validado):
        p.estado = EstadoPostulacion.sugerido
    db.commit()
    db.refresh(p)
    return p


@router.get("/{necesidad_id}/inscritos", response_model=list[PostulacionOut])
def inscritos(
    necesidad_id: int,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    """Lista de estudiantes inscritos en una necesidad (aceptado/sugerido/validado)."""
    n = db.get(Necesidad, necesidad_id)
    if not n:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")
    if user.rol == Rol.organizacion:
        org = db.get(Organizacion, n.organizacion_id)
        if not org or org.usuario_id != user.id:
            raise HTTPException(status_code=403, detail="No puedes ver inscritos de esta necesidad")

    postulaciones = (
        db.query(Postulacion)
        .filter(
            Postulacion.necesidad_id == necesidad_id,
            Postulacion.estado.in_([EstadoPostulacion.sugerido, EstadoPostulacion.aceptado, EstadoPostulacion.validado]),
        )
        .order_by(Postulacion.id.desc())
        .all()
    )

    resultado = []
    for p in postulaciones:
        estudiante = db.get(Usuario, p.estudiante_id)
        necesidad = db.get(Necesidad, p.necesidad_id)
        resultado.append(
            PostulacionOut(
                id=p.id,
                estudiante_id=p.estudiante_id,
                necesidad_id=p.necesidad_id,
                estado=p.estado,
                estudiante_nombre=estudiante.nombre if estudiante else None,
                estudiante_correo=estudiante.correo if estudiante else None,
                necesidad_titulo=necesidad.titulo if necesidad else None,
                necesidad_naturaleza=necesidad.naturaleza if necesidad else None,
                necesidad_ubicacion=necesidad.ubicacion if necesidad else None,
                horas=0,  # Postulacion no tiene horas, se calcula desde asistencias
            )
        )
    return resultado


@router.put("/{necesidad_id}", response_model=NecesidadOut)
def actualizar(
    necesidad_id: int,
    data: NecesidadUpdate,
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.coordinador, Rol.organizacion)),
):
    n = db.get(Necesidad, necesidad_id)
    if not n:
        raise HTTPException(status_code=404, detail="Necesidad no encontrada")
    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(n, campo, valor)
    db.commit()
    db.refresh(n)
    return n
