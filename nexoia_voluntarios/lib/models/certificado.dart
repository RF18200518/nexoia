class Certificado {
  Certificado({
    required this.id,
    required this.estudianteId,
    this.estudianteNombre,
    required this.horas,
    required this.codigoVerificacion,
    required this.fecha,
  });

  final int id;
  final int estudianteId;
  final String? estudianteNombre;
  final double horas;
  final String codigoVerificacion;
  final DateTime fecha;

  factory Certificado.fromJson(Map<String, dynamic> json) => Certificado(
        id: (json['id'] as num).toInt(),
        estudianteId: (json['estudiante_id'] as num).toInt(),
        estudianteNombre: json['estudiante_nombre'] as String?,
        horas: (json['horas'] as num?)?.toDouble() ?? 0,
        codigoVerificacion: json['codigo_verificacion'] as String,
        fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      );
}
