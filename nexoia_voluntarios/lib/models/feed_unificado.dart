import 'necesidad.dart';

class FeedUnificadoItem {
  FeedUnificadoItem({
    required this.id,
    required this.tipo,
    required this.necesidadId,
    required this.titulo,
    this.naturaleza,
    this.ubicacion,
    this.compatibilidad,
    this.estado,
  });

  final int id;
  final String tipo; // "simulada" | "invitacion"
  final int necesidadId;
  final String titulo;
  final String? naturaleza;
  final String? ubicacion;
  final int? compatibilidad;
  final String? estado;

  factory FeedUnificadoItem.fromJson(Map<String, dynamic> json) => FeedUnificadoItem(
        id: (json['id'] as num).toInt(),
        tipo: json['tipo'] as String,
        necesidadId: (json['necesidad_id'] as num).toInt(),
        titulo: json['titulo'] as String,
        naturaleza: json['naturaleza'] as String?,
        ubicacion: json['ubicacion'] as String?,
        compatibilidad: (json['compatibilidad'] as num?)?.toInt(),
        estado: json['estado'] as String?,
      );
}