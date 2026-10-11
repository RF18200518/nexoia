from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.security import create_access_token, hash_password, verify_password
from app.models import Organizacion, PerfilEstudiante, Rol, Usuario
from app.schemas.auth import RegisterIn, Token
from app.schemas.usuario import UsuarioOut
from app.services import simulacion

router = APIRouter(prefix="/auth", tags=["autenticación"])


@router.post("/register", response_model=UsuarioOut, status_code=status.HTTP_201_CREATED)
def register(data: RegisterIn, db: Session = Depends(get_db)):
    existe = db.query(Usuario).filter(Usuario.correo == data.correo).first()
    if existe:
        raise HTTPException(status_code=400, detail="Ese correo ya está registrado")

    user = Usuario(
        nombre=data.nombre,
        correo=data.correo,
        contrasena_hash=hash_password(data.contrasena),
        rol=data.rol,
    )
    db.add(user)
    db.flush()

    if data.rol == Rol.estudiante:
        perfil = PerfilEstudiante(usuario_id=user.id, intereses=list(data.intereses))
        db.add(perfil)
    elif data.rol == Rol.organizacion:
        db.add(Organizacion(usuario_id=user.id, nombre=data.nombre))

    db.commit()
    db.refresh(user)

    if data.rol == Rol.estudiante:
        # Genera las propuestas simuladas según los intereses elegidos.
        simulacion.generar(db, user, intereses=list(data.intereses))
        db.refresh(user)

    return user


@router.post("/login", response_model=Token)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.correo == form.username).first()
    if not user or not verify_password(form.password, user.contrasena_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )
    if not user.activo:
        raise HTTPException(status_code=403, detail="La cuenta está desactivada")

    token = create_access_token(subject=user.correo, rol=user.rol.value)
    return Token(access_token=token)


@router.get("/me", response_model=UsuarioOut)
def me(user: Usuario = Depends(get_current_user)):
    return user
