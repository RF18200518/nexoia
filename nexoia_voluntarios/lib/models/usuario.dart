class Perfil {
  Perfil({
    this.carrera,
    this.anio,
    this.habilidades = const [],
    this.intereses = const [],
    this.horasAcumuladas = 0,
  });

  final String? carrera;
  final int? anio;
  final List<String> habilidades;
  final List<String> intereses;
  final int horasAcumuladas;

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        carrera: json['carrera'] as String?,
        anio: json['anio'] as int?,
        habilidades: (json['habilidades'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        intereses: (json['intereses'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        horasAcumuladas: (json['horas_acumuladas'] as num?)?.toInt() ?? 0,
      );
}

class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.activo = true,
    this.perfil,
  });

  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;
  final Perfil? perfil;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        rol: json['rol'] as String,
        activo: json['activo'] as bool? ?? true,
        perfil: json['perfil'] != null
            ? Perfil.fromJson(json['perfil'] as Map<String, dynamic>)
            : null,
      );
}
