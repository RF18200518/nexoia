import '../core/api_client.dart';
import '../models/asistencia.dart';

class AsistenciaService {
  final ApiClient _api = ApiClient.instance;

  Future<QrGenerado> generar(int necesidadId) async {
    final data = await _api.post('/asistencias/generar', body: {
      'necesidad_id': necesidadId,
    });
    return QrGenerado.fromJson(data as Map<String, dynamic>);
  }

  Future<ValidarResultado> validar(String codigo) async {
    final data = await _api.post('/asistencias/validar', body: {
      'codigo': codigo,
    });
    return ValidarResultado.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Asistencia>> mias() async {
    final data = await _api.get('/asistencias/mias') as List;
    return data
        .map((e) => Asistencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
