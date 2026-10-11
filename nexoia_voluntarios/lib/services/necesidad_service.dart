import '../core/api_client.dart';
import '../models/candidato.dart';
import '../models/necesidad.dart';
import '../models/postulacion.dart';

class NecesidadService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Necesidad>> listar({String? estado, int? organizacionId}) async {
    final params = <String>[
      if (estado != null) 'estado=$estado',
      if (organizacionId != null) 'organizacion_id=$organizacionId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _api.get('/necesidades$query') as List;
    return data
        .map((e) => Necesidad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Necesidad> crear(Map<String, dynamic> body) async {
    final data = await _api.post('/necesidades', body: body);
    return Necesidad.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Candidato>> candidatos(int necesidadId) async {
    final data = await _api.get('/necesidades/$necesidadId/candidatos') as List;
    return data
        .map((e) => Candidato.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Postulacion> invitar(int necesidadId, int estudianteId) async {
    final data = await _api.post('/necesidades/$necesidadId/invitar', body: {
      'estudiante_id': estudianteId,
    });
    return Postulacion.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Necesidad>> recomendadas() async {
    final data = await _api.get('/necesidades/recomendadas') as List;
    return data
        .map((e) => Necesidad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Postulacion> postular(int necesidadId) async {
    final data = await _api.post('/postulaciones', body: {
      'necesidad_id': necesidadId,
    });
    return Postulacion.fromJson(data as Map<String, dynamic>);
  }

  Future<Postulacion> rechazar(int necesidadId) async {
    final data = await _api.post('/postulaciones/rechazar', body: {
      'necesidad_id': necesidadId,
    });
    return Postulacion.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Postulacion>> misPostulaciones() async {
    final data = await _api.get('/postulaciones/mias') as List;
    return data
        .map((e) => Postulacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Postulacion>> obtenerInscritos(int necesidadId) async {
    final data = await _api.get('/necesidades/$necesidadId/inscritos') as List;
    return data
        .map((e) => Postulacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> actualizar(int necesidadId, Map<String, dynamic> body) async {
    await _api.put('/necesidades/$necesidadId', body: body);
  }
}
