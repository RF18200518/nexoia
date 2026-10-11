import '../core/api_client.dart';
import '../models/equipo.dart';

class EquipoService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Equipo>> listar() async {
    final data = await _api.get('/equipos') as List;
    return data
        .map((e) => Equipo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Equipo> crear(List<int> estudianteIds, int necesidadId) async {
    final data = await _api.post('/equipos', body: {
      'necesidad_id': necesidadId,
      'estudiante_ids': estudianteIds,
    });
    return Equipo.fromJson(data as Map<String, dynamic>);
  }

  Future<Equipo> armar(int necesidadId, {int? maxIntegrantes}) async {
    final body = <String, dynamic>{'necesidad_id': necesidadId};
    if (maxIntegrantes != null) body['max_integrantes'] = maxIntegrantes;
    final data = await _api.post('/equipos/armar', body: body);
    return Equipo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminar(int equipoId) async {
    await _api.delete('/equipos/$equipoId');
  }
}