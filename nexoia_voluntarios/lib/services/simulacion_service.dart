import '../core/api_client.dart';
import '../models/feed_unificado.dart';
import '../models/simulacion.dart';

class SimulacionService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Interes>> intereses() async {
    final data = await _api.get('/simulacion/intereses') as List;
    return data
        .map((e) => Interes.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedSimulacion> misPropuestas() async {
    final data = await _api.get('/simulacion/mis-propuestas');
    return FeedSimulacion.fromJson(data as Map<String, dynamic>);
  }

  Future<List<FeedUnificadoItem>> feedUnificado() async {
    final data = await _api.get('/postulaciones/feed') as List;
    return data
        .map((e) => FeedUnificadoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeedSimulacion> reiniciar() async {
    final data = await _api.post('/simulacion/reiniciar');
    return FeedSimulacion.fromJson(data as Map<String, dynamic>);
  }
}
