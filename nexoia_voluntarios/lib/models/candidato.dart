class Candidato {
  Candidato({
    required this.estudianteId,
    required this.nombre,
    required this.correo,
    this.carrera,
    this.anio,
    this.habilidades = const [],
    this.horasAcumuladas = 0,
    this.compatibilidad = 0,
    this.invitado = false,
  });

  final int estudianteId;
  final String nombre;
  final String correo;
  final String? carrera;
  final int? anio;
  final List<String> habilidades;
  final int horasAcumuladas;
  final int compatibilidad;
  final bool invitado;

  factory Candidato.fromJson(Map<String, dynamic> json) => Candidato(
        estudianteId: (json['estudiante_id'] as num).toInt(),
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        carrera: json['carrera'] as String?,
        anio: (json['anio'] as num?)?.toInt(),
        habilidades: (json['habilidades'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        horasAcumuladas: (json['horas_acumuladas'] as num?)?.toInt() ?? 0,
        compatibilidad: (json['compatibilidad'] as num?)?.toInt() ?? 0,
        invitado: json['invitado'] as bool? ?? false,
      );
}
