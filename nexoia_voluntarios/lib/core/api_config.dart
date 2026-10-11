import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Cambia esta IP por la de TU PC en la red WiFi (para probar en el celular).
  /// En Windows: ejecuta `ipconfig` y busca "Dirección IPv4".
  static const String lanIp = '192.168.1.5';

  static String get baseUrl => kIsWeb ? 'http://127.0.0.1:8000' : 'http://$lanIp:8000';
}
