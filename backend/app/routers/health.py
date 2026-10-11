from fastapi import APIRouter

router = APIRouter(tags=["sistema"])


@router.get("/health")
def health():
    return {"status": "ok", "servicio": "NexoIA API", "version": "0.1.0"}
