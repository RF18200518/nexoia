class EstudianteResumen {
  EstudianteResumen({
    required this.id,
    required this.nombre,
    required this.correo,
    this.carrera,
    this.anio,
    this.habilidades = const [],
    this.horasAcumuladas = 0,
    this.certificados = 0,
    this.sobrecarga = false,
  });

  final int id;
  final String nombre;
  final String correo;
  final String? carrera;
  final int? anio;
  final List<String> habilidades;
  final int horasAcumuladas;
  final int certificados;
  final bool sobrecarga;

  factory EstudianteResumen.fromJson(Map<String, dynamic> json) =>
      EstudianteResumen(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        carrera: json['carrera'] as String?,
        anio: (json['anio'] as num?)?.toInt(),
        habilidades: (json['habilidades'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        horasAcumuladas: (json['horas_acumuladas'] as num?)?.toInt() ?? 0,
        certificados: (json['certificados'] as num?)?.toInt() ?? 0,
        sobrecarga: json['sobrecarga'] as bool? ?? false,
      );
}
