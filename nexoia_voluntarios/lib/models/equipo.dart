class Integrante {
  Integrante({
    required this.estudianteId,
    required this.nombre,
    this.correo,
    this.carrera,
    this.rol,
    this.compatibilidad,
  });

  final int estudianteId;
  final String nombre;
  final String? correo;
  final String? carrera;
  final String? rol;
  final int? compatibilidad;

  factory Integrante.fromJson(Map<String, dynamic> json) => Integrante(
        estudianteId: (json['estudiante_id'] as num).toInt(),
        nombre: json['nombre'] as String,
        correo: json['correo'] as String?,
        carrera: json['carrera'] as String?,
        rol: json['rol'] as String?,
        compatibilidad: (json['compatibilidad'] as num?)?.toInt(),
      );
}

class Equipo {
  Equipo({
    required this.id,
    required this.necesidadId,
    this.necesidadTitulo,
    this.integrantes = const [],
  });

  final int id;
  final int necesidadId;
  final String? necesidadTitulo;
  final List<Integrante> integrantes;

  factory Equipo.fromJson(Map<String, dynamic> json) => Equipo(
        id: (json['id'] as num).toInt(),
        necesidadId: (json['necesidad_id'] as num).toInt(),
        necesidadTitulo: json['necesidad_titulo'] as String?,
        integrantes: (json['integrantes'] as List? ?? [])
            .map((e) => Integrante.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}