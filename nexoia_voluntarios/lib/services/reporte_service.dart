import '../core/api_client.dart';
import '../core/descarga/descarga.dart';

class ReporteService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> resumen() async {
    return await _api.get('/reportes/resumen') as Map<String, dynamic>;
  }

  Future<void> descargarHorasCsv() async {
    final bytes = await _api.getBytes('/reportes/horas.csv');
    await descargarArchivo('horas_estudiantes.csv', bytes);
  }
}