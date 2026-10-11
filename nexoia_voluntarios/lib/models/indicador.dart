class IndicadorPorCarrera {
  IndicadorPorCarrera({required this.carrera, required this.cantidad, required this.horas});

  final String carrera;
  final int cantidad;
  final int horas;

  factory IndicadorPorCarrera.fromJson(Map<String, dynamic> json) => IndicadorPorCarrera(
        carrera: json['carrera'] as String,
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
        horas: (json['horas'] as num?)?.toInt() ?? 0,
      );
}

class Indicadores {
  Indicadores({
    required this.horasTotal,
    required this.necesidades,
    required this.organizacionesAprobadas,
    required this.estudiantes,
    required this.postulaciones,
    required this.porCarrera,
  });

  final int horasTotal;
  final NecesidadesStats necesidades;
  final int organizacionesAprobadas;
  final int estudiantes;
  final int postulaciones;
  final List<IndicadorPorCarrera> porCarrera;

  factory Indicadores.fromJson(Map<String, dynamic> json) => Indicadores(
        horasTotal: (json['horas_total'] as num?)?.toInt() ?? 0,
        necesidades: NecesidadesStats.fromJson(json['necesidades'] as Map<String, dynamic>),
        organizacionesAprobadas: (json['organizaciones_aprobadas'] as num?)?.toInt() ?? 0,
        estudiantes: (json['estudiantes'] as num?)?.toInt() ?? 0,
        postulaciones: (json['postulaciones'] as num?)?.toInt() ?? 0,
        porCarrera: (json['por_carrera'] as List?)
                ?.map((e) => IndicadorPorCarrera.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class NecesidadesStats {
  NecesidadesStats({
    required this.total,
    required this.publicadas,
    required this.finalizadas,
  });

  final int total;
  final int publicadas;
  final int finalizadas;

  factory NecesidadesStats.fromJson(Map<String, dynamic> json) => NecesidadesStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        publicadas: (json['publicadas'] as num?)?.toInt() ?? 0,
        finalizadas: (json['finalizadas'] as num?)?.toInt() ?? 0,
      );
}
