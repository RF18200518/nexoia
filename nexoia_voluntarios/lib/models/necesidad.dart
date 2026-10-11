class Necesidad {
  Necesidad({
    required this.id,
    required this.organizacionId,
    required this.titulo,
    this.descripcion,
    this.naturaleza,
    this.prioridad,
    this.habilidadesRequeridas = const [],
    this.cupos = 1,
    this.ubicacion,
    required this.estado,
    this.compatibilidad = 0,
    this.fecha,
    this.duracion,
  });

  final int id;
  final int organizacionId;
  final String titulo;
  final String? descripcion;
  final String? naturaleza;
  final String? prioridad;
  final List<String> habilidadesRequeridas;
  final int cupos;
  final String? ubicacion;
  final String estado;
  final int compatibilidad;
  final DateTime? fecha;
  final int? duracion; // en horas

  factory Necesidad.fromJson(Map<String, dynamic> json) => Necesidad(
        id: (json['id'] as num).toInt(),
        organizacionId: (json['organizacion_id'] as num).toInt(),
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        naturaleza: json['naturaleza'] as String?,
        prioridad: json['prioridad'] as String?,
        habilidadesRequeridas:
            (json['habilidades_requeridas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        cupos: (json['cupos'] as num?)?.toInt() ?? 1,
        ubicacion: json['ubicacion'] as String?,
        estado: json['estado'] as String? ?? 'borrador',
        compatibilidad: (json['compatibilidad'] as num?)?.toInt() ?? 0,
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : null,
        duracion: json['duracion'] as int?,
      );
}
