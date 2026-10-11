"""Catálogo de categorías de voluntariado (intereses del estudiante)."""

CATALOGO: list[dict] = [
    {"clave": "ambiental", "label": "Medio ambiente", "emoji": "🌱", "naturaleza": "Ambiental"},
    {"clave": "social", "label": "Ayuda social", "emoji": "🤝", "naturaleza": "Social"},
    {"clave": "educacion", "label": "Educación", "emoji": "📚", "naturaleza": "Educación"},
    {"clave": "tecnologia", "label": "Tecnología", "emoji": "💻", "naturaleza": "Tecnología"},
    {"clave": "salud", "label": "Salud", "emoji": "🩺", "naturaleza": "Salud"},
    {"clave": "animales", "label": "Animales", "emoji": "🐾", "naturaleza": "Animales"},
    {"clave": "deportes", "label": "Deportes", "emoji": "⚽", "naturaleza": "Deportes"},
    {"clave": "cultural", "label": "Cultura y arte", "emoji": "🎨", "naturaleza": "Cultural"},
]

POR_CLAVE = {c["clave"]: c for c in CATALOGO}
