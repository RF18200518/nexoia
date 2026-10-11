import '../core/api_client.dart';
import '../core/descarga/descarga.dart';
import '../models/certificado.dart';

class CertificadoService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Certificado>> listar() async {
    final data = await _api.get('/certificados') as List;
    return data
        .map((e) => Certificado.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Certificado>> mios() async {
    final data = await _api.get('/certificados/mios') as List;
    return data
        .map((e) => Certificado.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Certificado> emitir(int estudianteId) async {
    final data = await _api.post('/certificados', body: {
      'estudiante_id': estudianteId,
    });
    return Certificado.fromJson(data as Map<String, dynamic>);
  }

  Future<void> descargarPdf(Certificado certificado) async {
    final bytes = await _api.getBytes('/certificados/${certificado.id}/pdf');
    await descargarArchivo(
      'certificado-${certificado.codigoVerificacion}.pdf',
      bytes,
    );
  }
}
