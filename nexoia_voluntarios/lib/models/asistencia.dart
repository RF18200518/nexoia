class Asistencia {
  Asistencia({
    required this.id,
    required this.necesidadId,
    required this.estudianteId,
    required this.validado,
    required this.horas,
    this.fecha,
  });

  final int id;
  final int necesidadId;
  final int estudianteId;
  final bool validado;
  final double horas;
  final DateTime? fecha;

  factory Asistencia.fromJson(Map<String, dynamic> json) => Asistencia(
        id: (json['id'] as num).toInt(),
        necesidadId: (json['necesidad_id'] as num).toInt(),
        estudianteId: (json['estudiante_id'] as num).toInt(),
        validado: json['validado'] as bool? ?? false,
        horas: (json['horas'] as num?)?.toDouble() ?? 0,
        fecha: json['fecha'] != null
            ? DateTime.tryParse(json['fecha'] as String)
            : null,
      );
}

class QrGenerado {
  QrGenerado({
    required this.codigo,
    required this.expiraEn,
    required this.segundos,
    required this.necesidadId,
    this.necesidadTitulo,
  });

  final String codigo;
  final DateTime expiraEn;
  final int segundos;
  final int necesidadId;
  final String? necesidadTitulo;

  factory QrGenerado.fromJson(Map<String, dynamic> json) => QrGenerado(
        codigo: json['codigo'] as String,
        expiraEn: DateTime.parse(json['expira_en'] as String),
        segundos: (json['segundos'] as num).toInt(),
        necesidadId: (json['necesidad_id'] as num).toInt(),
        necesidadTitulo: json['necesidad_titulo'] as String?,
      );
}

class ValidarResultado {
  ValidarResultado({
    required this.ok,
    required this.mensaje,
    this.estudiante,
    this.necesidad,
    this.horas,
  });

  final bool ok;
  final String mensaje;
  final String? estudiante;
  final String? necesidad;
  final double? horas;

  factory ValidarResultado.fromJson(Map<String, dynamic> json) =>
      ValidarResultado(
        ok: json['ok'] as bool? ?? false,
        mensaje: json['mensaje'] as String? ?? '',
        estudiante: json['estudiante'] as String?,
        necesidad: json['necesidad'] as String?,
        horas: (json['horas'] as num?)?.toDouble(),
      );
}
