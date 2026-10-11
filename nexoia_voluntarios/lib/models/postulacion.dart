class Postulacion {
  Postulacion({
    required this.id,
    required this.estudianteId,
    required this.necesidadId,
    required this.estado,
    this.necesidadTitulo,
    this.necesidadNaturaleza,
    this.necesidadUbicacion,
    this.horas = 0,
  });

  final int id;
  final int estudianteId;
  final int necesidadId;
  final String estado;
  final String? necesidadTitulo;
  final String? necesidadNaturaleza;
  final String? necesidadUbicacion;
  final double horas;

  factory Postulacion.fromJson(Map<String, dynamic> json) => Postulacion(
        id: (json['id'] as num).toInt(),
        estudianteId: (json['estudiante_id'] as num).toInt(),
        necesidadId: (json['necesidad_id'] as num).toInt(),
        estado: json['estado'] as String? ?? 'sugerido',
        necesidadTitulo: json['necesidad_titulo'] as String?,
        necesidadNaturaleza: json['necesidad_naturaleza'] as String?,
        necesidadUbicacion: json['necesidad_ubicacion'] as String?,
        horas: (json['horas'] as num?)?.toDouble() ?? 0,
      );
}
