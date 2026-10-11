"""Motor de simulación de propuestas.

Genera un conjunto acotado de propuestas (necesidades) para cada estudiante,
elegidas a partir de las categorías en las que dijo querer participar. Cada
propuesta se "publica" de forma escalonada: aparece de golpe la primera y luego
las demás llegan una cada ``sim_intervalo_segundos`` segundos (por defecto 2
minutos). El total está limitado por ``sim_total_propuestas`` (por defecto 5).
"""

from datetime import datetime, timedelta

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import (
    EstadoNecesidad,
    EstadoOrganizacion,
    Necesidad,
    Organizacion,
    PerfilEstudiante,
    Postulacion,
    Usuario,
)
from app.services.catalogo import CATALOGO, POR_CLAVE
from app.services.match import aplicar

__all__ = ["CATALOGO", "POR_CLAVE", "generar", "estado_feed"]

# (titulo, descripcion, habilidades, ubicacion, cupos, duracion)
PLANTILLAS: dict[str, list[tuple]] = {
    "ambiental": [
        ("Jornada de reforestación", "Sembra y cuidá árboles en el vivero de la comunidad.", ["trabajo en equipo", "esfuerzo físico"], "Managua", 12, 4),
        ("Limpieza de playa", "Recolectemos residuos y clasifiquemos para reciclar.", ["trabajo en equipo"], "Poneloya", 20, 3),
        ("Huerto comunitario", "Apoya el cuido de un huerto urbano y su cosecha.", ["compromiso"], "León", 8, 4),
    ],
    "social": [
        ("Apoyo en comedor infantil", "Serví comidas y acompañá a los niños en sus actividades.", ["empatía", "docencia"], "León", 6, 4),
        ("Entrega de víveres", "Organizá y repartí canastas básicas en barrios.", ["organización", "esfuerzo físico"], "Managua", 15, 3),
        ("Visita a hogar de ancianos", "Compartí una tarde de compañía y actividades.", ["empatía", "paciencia"], "Masaya", 10, 3),
    ],
    "educacion": [
        ("Refuerzo escolar para niños", "Acompañá a niños con sus tareas y lectoescritura.", ["docencia", "paciencia"], "Managua", 8, 3),
        ("Taller de lectura", "Dinamizá un club de lectura semanal.", ["docencia", "creatividad"], "Granada", 6, 2),
        ("Alfabetización de adultos", "Enseñá a leer y escribir a personas adultas.", ["docencia", "empatía"], "León", 6, 3),
    ],
    "tecnologia": [
        ("Página web para la fundación", "Creá un sitio informativo sencillo y su contenido.", ["programación", "diseño"], "Remoto", 3, 6),
        ("Digitalización de archivos", "Organizá y digitalizá documentos históricos.", ["atención al detalle"], "Remoto", 5, 4),
        ("Soporte técnico comunitario", "Ayudá a reparar equipos y resolver dudas digitales.", ["informática"], "Managua", 4, 3),
    ],
    "salud": [
        ("Brigada médica comunitaria", "Apoyá logística en una brigada de salud.", ["organización", "empatía"], "Estelí", 10, 5),
        ("Campaña de vacunación", "Colaborá con el registro de pacientes.", ["atención al detalle"], "Managua", 8, 4),
        ("Charlas de salud preventiva", "Impartí charlas sobre hábitos saludables.", ["comunicación"], "Masaya", 5, 2),
    ],
    "animales": [
        ("Cuidado en refugio de animales", "Alimentá y paseá a los animalitos rescatados.", ["empatía", "responsabilidad"], "Managua", 10, 4),
        ("Jornada de adopción", "Apoyá la organización de una feria de adopción.", ["organización", "empatía"], "Granada", 8, 4),
        ("Rescate de animales en riesgo", "Colaborá con rescates y traslados.", ["esfuerzo físico", "empatía"], "Managua", 6, 3),
    ],
    "deportes": [
        ("Entrenamiento de fútbol infantil", "Sé entrenador auxiliar de una liga barrial.", ["liderazgo", "deporte"], "Managua", 8, 3),
        ("Carrera benéfica", "Apoyá logística e hidratación en la carrera.", ["organización"], "León", 20, 4),
        ("Taller de básquet para jóvenes", "Acompañá entrenamientos y torneos.", ["deporte", "liderazgo"], "Masaya", 6, 3),
    ],
    "cultural": [
        ("Mural comunitario", "Pintá un mural que cuente la historia del barrio.", ["creatividad", "pintura"], "Managua", 10, 5),
        ("Festival cultural barrial", "Apoyá la producción de un festival artístico.", ["organización", "creatividad"], "Granada", 12, 6),
        ("Taller de música para niños", "Enseñá iniciación musical a niños.", ["música", "docencia"], "León", 6, 2),
    ],
}

_PRIORIDADES = ["Alta", "Media", "Media", "Alta", "Media"]


def _organizacion(db: Session, naturaleza: str) -> Organizacion:
    orgs = (
        db.query(Organizacion)
        .filter(Organizacion.estado == EstadoOrganizacion.aprobada)
        .all()
    )
    for o in orgs:
        if o.tipo and naturaleza.lower() in o.tipo.lower():
            return o
    if orgs:
        return orgs[abs(hash(naturaleza)) % len(orgs)]

    org = Organizacion(
        nombre="Red de Voluntariado NexoIA",
        tipo="General",
        contacto="+505 0000 0000",
        estado=EstadoOrganizacion.aprobada,
        sitio="Nacional",
    )
    db.add(org)
    db.flush()
    return org


def generar(
    db: Session,
    estudiante: Usuario,
    intervalo: int | None = None,
    total: int | None = None,
    intereses: list[str] | None = None,
) -> None:
    intervalo = intervalo or settings.sim_intervalo_segundos
    total = total or settings.sim_total_propuestas

    perfil = db.get(PerfilEstudiante, estudiante.id)
    if perfil is None:
        perfil = PerfilEstudiante(usuario_id=estudiante.id)
        db.add(perfil)

    claves = intereses if intereses is not None else (perfil.intereses or [])
    claves = [c for c in claves if c in POR_CLAVE]
    if not claves:
        claves = ["ambiental", "social", "educacion", "tecnologia"]

    # Limpiamos la simulación anterior del estudiante.
    viejas = (
        db.query(Necesidad)
        .filter(Necesidad.simulacion_estudiante_id == estudiante.id)
        .all()
    )
    ids = [n.id for n in viejas]
    if ids:
        db.query(Postulacion).filter(Postulacion.necesidad_id.in_(ids)).delete(
            synchronize_session=False
        )
    for n in viejas:
        db.delete(n)
    db.flush()

    ahora = datetime.now()
    usos: dict[str, int] = {}
    for i in range(total):
        clave = claves[i % len(claves)]
        cat = POR_CLAVE[clave]
        idx = usos.get(clave, 0)
        usos[clave] = idx + 1
        titulo, desc, habilidades, ubicacion, cupos, duracion = PLANTILLAS[clave][
            idx % len(PLANTILLAS[clave])
        ]
        org = _organizacion(db, cat["naturaleza"])
        db.add(
            Necesidad(
                organizacion_id=org.id,
                titulo=titulo,
                descripcion=desc,
                naturaleza=cat["naturaleza"],
                prioridad=_PRIORIDADES[i % len(_PRIORIDADES)],
                habilidades_requeridas=list(habilidades),
                cupos=cupos,
                ubicacion=ubicacion,
                fecha=ahora + timedelta(days=i + 1, hours=8),
                duracion=duracion,
                estado=EstadoNecesidad.publicada,
                visible_desde=ahora + timedelta(seconds=i * intervalo),
                simulacion_estudiante_id=estudiante.id,
            )
        )

    perfil.intereses = claves
    perfil.simulacion_inicio = ahora
    perfil.simulacion_intervalo = intervalo
    db.commit()


def estado_feed(db: Session, estudiante: Usuario) -> dict:
    total_actual = (
        db.query(func.count(Necesidad.id))
        .filter(Necesidad.simulacion_estudiante_id == estudiante.id)
        .scalar()
        or 0
    )
    if total_actual == 0:
        generar(db, estudiante)

    perfil = db.get(PerfilEstudiante, estudiante.id)
    ahora = datetime.now()
    todas = (
        db.query(Necesidad)
        .filter(Necesidad.simulacion_estudiante_id == estudiante.id)
        .order_by(Necesidad.visible_desde.asc())
        .all()
    )
    decididas = {
        nid
        for (nid,) in db.query(Postulacion.necesidad_id)
        .filter(Postulacion.estudiante_id == estudiante.id)
        .all()
    }
    llegadas = [
        n
        for n in todas
        if (n.visible_desde is None or n.visible_desde <= ahora) and n.id not in decididas
    ]
    pendientes = [n for n in todas if n.visible_desde and n.visible_desde > ahora]
    aplicar(perfil, llegadas)

    siguiente_en = None
    if pendientes:
        siguiente_en = max(0, int((pendientes[0].visible_desde - ahora).total_seconds()))

    intervalo = (
        (perfil.simulacion_intervalo if perfil else None)
        or settings.sim_intervalo_segundos
    )

    return {
        "activa": len(pendientes) > 0,
        "total": len(todas),
        "recibidas": len(llegadas),
        "siguiente_en": siguiente_en,
        "intervalo": intervalo,
        "propuestas": llegadas,
    }
