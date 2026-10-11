import '../core/api_client.dart';
import '../models/usuario.dart';

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<String> login(String correo, String contrasena) async {
    final data = await _api.postForm('/auth/login', {
      'username': correo,
      'password': contrasena,
    });
    return (data as Map<String, dynamic>)['access_token'] as String;
  }

  Future<Usuario> me() async {
    final data = await _api.get('/auth/me');
    return Usuario.fromJson(data as Map<String, dynamic>);
  }

  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    String rol = 'estudiante',
    List<String> intereses = const [],
  }) async {
    final data = await _api.post('/auth/register', body: {
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'rol': rol,
      'intereses': intereses,
    });
    return Usuario.fromJson(data as Map<String, dynamic>);
  }

  Future<Usuario> actualizarPerfil({
    String? carrera,
    int? anio,
    List<String>? habilidades,
    List<String>? intereses,
  }) async {
    final body = <String, dynamic>{};
    if (carrera != null) body['carrera'] = carrera;
    if (anio != null) body['anio'] = anio;
    if (habilidades != null) body['habilidades'] = habilidades;
    if (intereses != null) body['intereses'] = intereses;
    final data = await _api.put('/usuarios/me/perfil', body: body);
    return Usuario.fromJson(data as Map<String, dynamic>);
  }
}
