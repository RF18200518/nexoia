from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_roles
from app.models import Rol, Usuario
from app.schemas.simulacion import FeedSimulacionOut, InteresOut
from app.services import simulacion

router = APIRouter(prefix="/simulacion", tags=["simulación"])


@router.get("/intereses", response_model=list[InteresOut])
def intereses():
    """Catálogo de categorías en las que un estudiante puede participar."""
    return simulacion.CATALOGO


@router.get("/mis-propuestas", response_model=FeedSimulacionOut)
def mis_propuestas(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Feed en vivo: propuestas que ya 'llegaron' para este estudiante."""
    return simulacion.estado_feed(db, user)


@router.post("/reiniciar", response_model=FeedSimulacionOut)
def reiniciar(
    db: Session = Depends(get_db),
    user: Usuario = Depends(require_roles(Rol.estudiante)),
):
    """Vuelve a generar la simulación según los intereses actuales."""
    intereses = list(user.perfil.intereses) if user.perfil else None
    simulacion.generar(db, user, intereses=intereses)
    return simulacion.estado_feed(db, user)
