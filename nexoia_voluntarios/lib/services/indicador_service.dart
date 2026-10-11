import '../core/api_client.dart';
import '../models/indicador.dart';

class IndicadorService {
  final ApiClient _api = ApiClient.instance;

  Future<Indicadores> obtener() async {
    final data = await _api.get('/indicadores');
    return Indicadores.fromJson(data as Map<String, dynamic>);
  }
}
