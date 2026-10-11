import '../core/api_client.dart';
import '../models/organizacion.dart';

class OrganizacionService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Organizacion>> listar({String? estado}) async {
    final query = estado != null ? '?estado=$estado' : '';
    final data = await _api.get('/organizaciones$query') as List;
    return data.map((e) => Organizacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Organizacion> mia() async {
    final data = await _api.get('/organizaciones/mia');
    return Organizacion.fromJson(data as Map<String, dynamic>);
  }

  Future<Organizacion> cambiarEstado(int id, String estado) async {
    final data = await _api.patch('/organizaciones/$id/estado', body: {'estado': estado});
    return Organizacion.fromJson(data as Map<String, dynamic>);
  }
}
