import '../core/api_client.dart';
import '../models/estudiante_resumen.dart';

class EstudianteService {
  final ApiClient _api = ApiClient.instance;

  Future<List<EstudianteResumen>> listar() async {
    final data = await _api.get('/usuarios/estudiantes') as List;
    return data
        .map((e) => EstudianteResumen.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
