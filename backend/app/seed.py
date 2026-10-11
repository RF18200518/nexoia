from datetime import datetime, timedelta

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models import (
    EstadoNecesidad,
    EstadoOrganizacion,
    Necesidad,
    Organizacion,
    PerfilEstudiante,
    Rol,
    Usuario,
)
from app.services import simulacion


def run() -> None:
    db = SessionLocal()
    try:
        if db.query(Usuario).count() > 0:
            print("Ya existen datos. No se hizo nada.")
            return

        coord = Usuario(
            nombre="Coordinador UCN",
            correo="coordinador.ucn@gmail.com",
            contrasena_hash=hash_password("coordinador123"),
            rol=Rol.coordinador,
        )
        org_user = Usuario(
            nombre="Fundación Verde",
            correo="fundacion.verde@gmail.com",
            contrasena_hash=hash_password("fundacion123"),
            rol=Rol.organizacion,
        )
        est = Usuario(
            nombre="Rafael Mairena",
            correo="rafael.mairena@gmail.com",
            contrasena_hash=hash_password("rafael123"),
            rol=Rol.estudiante,
        )
        db.add_all([coord, org_user, est])
        db.flush()

        db.add(
            PerfilEstudiante(
                usuario_id=est.id,
                carrera="Ingeniería en Sistemas",
                anio=3,
                habilidades=["programación", "diseño", "docencia"],
                intereses=["ambiental", "educacion", "tecnologia"],
                disponibilidad={"dias": ["sábado", "domingo"], "horas": 6},
                horas_acumuladas=0,
            )
        )

        org1 = Organizacion(
            usuario_id=org_user.id,
            nombre="Fundación Verde",
            tipo="Ambiental",
            contacto="+505 8888 8888",
            estado=EstadoOrganizacion.aprobada,
            sitio="Managua",
        )
        org2 = Organizacion(
            nombre="Comedor Solidario",
            tipo="Social",
            contacto="+505 7777 7777",
            estado=EstadoOrganizacion.aprobada,
            sitio="León",
        )
        db.add_all([org1, org2])
        db.flush()

        manana = datetime.now() + timedelta(days=1)
        proxima_semana = datetime.now() + timedelta(days=7)

        db.add_all(
            [
                Necesidad(
                    organizacion_id=org1.id,
                    titulo="Reforestación en el cerro",
                    descripcion="Sembrar árboles y cuidar el vivero comunitario.",
                    naturaleza="Ambiental",
                    prioridad="Alta",
                    habilidades_requeridas=["trabajo en equipo", "esfuerzo físico"],
                    cupos=10,
                    ubicacion="Managua",
                    fecha=manana.replace(hour=8, minute=0),
                    duracion=4,
                    estado=EstadoNecesidad.publicada,
                ),
                Necesidad(
                    organizacion_id=org2.id,
                    titulo="Apoyo en comedor infantil",
                    descripcion="Servir comidas y apoyar actividades con los niños.",
                    naturaleza="Social",
                    prioridad="Media",
                    habilidades_requeridas=["docencia", "empatía"],
                    cupos=5,
                    ubicacion="León",
                    fecha=proxima_semana.replace(hour=9, minute=0),
                    duracion=4,
                    estado=EstadoNecesidad.publicada,
                ),
                Necesidad(
                    organizacion_id=org1.id,
                    titulo="Página web para la fundación",
                    descripcion="Crear un sitio web informativo sencillo.",
                    naturaleza="Tecnología",
                    prioridad="Media",
                    habilidades_requeridas=["programación", "diseño"],
                    cupos=2,
                    ubicacion="Remoto",
                    fecha=proxima_semana.replace(hour=14, minute=0),
                    duracion=6,
                    estado=EstadoNecesidad.publicada,
                ),
            ]
        )

        db.commit()

        # Genera las propuestas simuladas de Rafael según sus intereses.
        simulacion.generar(
            db, est, intereses=["ambiental", "educacion", "tecnologia"]
        )

        print("Datos de prueba creados.")
        print("  rafael.mairena@gmail.com / rafael123")
        print("  fundacion.verde@gmail.com / fundacion123")
        print("  coordinador.ucn@gmail.com / coordinador123")
    finally:
        db.close()


if __name__ == "__main__":
    run()
