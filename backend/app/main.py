from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import app.models  # noqa: F401  (registra todas las tablas en Base.metadata)
from app.routers import (
    asistencias,
    auth,
    certificados,
    equipos,
    health,
    indicadores,
    necesidades,
    organizaciones,
    postulaciones,
    reportes,
    simulacion,
    usuarios,
)

app = FastAPI(
    title="NexoIA API",
    description="Backend de la plataforma de voluntariado NexoIA.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(usuarios.router)
app.include_router(organizaciones.router)
app.include_router(necesidades.router)
app.include_router(postulaciones.router)
app.include_router(asistencias.router)
app.include_router(certificados.router)
app.include_router(equipos.router)
app.include_router(reportes.router)
app.include_router(simulacion.router)
app.include_router(indicadores.router)


@app.get("/", tags=["sistema"])
def root():
    return {"app": "NexoIA API", "docs": "/docs"}
