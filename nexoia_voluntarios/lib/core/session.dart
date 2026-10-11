import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'api_client.dart';

class Session extends ChangeNotifier {
  final AuthService _auth = AuthService();

  Usuario? _usuario;
  bool _cargando = false;
  bool _listo = false;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get cargando => _cargando;
  bool get listo => _listo;

  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      ApiClient.instance.setToken(token);
      try {
        _usuario = await _auth.me();
      } catch (_) {
        await prefs.remove('token');
        ApiClient.instance.setToken(null);
      }
    }
    _listo = true;
    notifyListeners();
  }

  Future<void> login(String correo, String contrasena) async {
    _cargando = true;
    notifyListeners();
    try {
      final token = await _auth.login(correo, contrasena);
      ApiClient.instance.setToken(token);
      _usuario = await _auth.me();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    String rol = 'estudiante',
    List<String> intereses = const [],
  }) async {
    await _auth.registrar(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      rol: rol,
      intereses: intereses,
    );
    await login(correo, contrasena);
  }

  Future<void> refrescar() async {
    if (!autenticado) return;
    _usuario = await _auth.me();
    notifyListeners();
  }

  Future<void> actualizarPerfil({
    String? carrera,
    int? anio,
    List<String>? habilidades,
    List<String>? intereses,
  }) async {
    _usuario = await _auth.actualizarPerfil(
      carrera: carrera,
      anio: anio,
      habilidades: habilidades,
      intereses: intereses,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient.instance.setToken(null);
    _usuario = null;
    notifyListeners();
  }
}
