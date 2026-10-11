import 'necesidad.dart';

class Interes {
  Interes({required this.clave, required this.label, required this.emoji});

  final String clave;
  final String label;
  final String emoji;

  factory Interes.fromJson(Map<String, dynamic> json) => Interes(
        clave: json['clave'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String? ?? '⭐',
      );
}

class FeedSimulacion {
  FeedSimulacion({
    required this.activa,
    required this.total,
    required this.recibidas,
    this.siguienteEn,
    required this.intervalo,
    required this.propuestas,
  });

  final bool activa;
  final int total;
  final int recibidas;
  final int? siguienteEn;
  final int intervalo;
  final List<Necesidad> propuestas;

  bool get terminada => !activa;

  factory FeedSimulacion.fromJson(Map<String, dynamic> json) => FeedSimulacion(
        activa: json['activa'] as bool? ?? false,
        total: (json['total'] as num?)?.toInt() ?? 0,
        recibidas: (json['recibidas'] as num?)?.toInt() ?? 0,
        siguienteEn: (json['siguiente_en'] as num?)?.toInt(),
        intervalo: (json['intervalo'] as num?)?.toInt() ?? 120,
        propuestas: (json['propuestas'] as List?)
                ?.map((e) => Necesidad.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
