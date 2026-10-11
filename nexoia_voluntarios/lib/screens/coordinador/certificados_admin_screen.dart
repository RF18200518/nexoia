import 'package:flutter/material.dart';

import '../../models/certificado.dart';
import '../../services/certificado_service.dart';

class CertificadosAdminScreen extends StatefulWidget {
  const CertificadosAdminScreen({super.key});

  @override
  State<CertificadosAdminScreen> createState() =>
      _CertificadosAdminScreenState();
}

class _CertificadosAdminScreenState extends State<CertificadosAdminScreen> {
  final _service = CertificadoService();

  List<Certificado> _items = [];
  bool _cargando = true;
  String? _error;
  int? _descargando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _service.listar();
      if (!mounted) return;
      setState(() {
        _items = data;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los certificados.';
        _cargando = false;
      });
    }
  }

  Future<void> _descargar(Certificado c) async {
    setState(() => _descargando = c.id);
    try {
      await _service.descargarPdf(c);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF de ${c.codigoVerificacion} generado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descarga no disponible en esta plataforma.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _descargando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Estado(mensaje: _error!, onReintentar: _cargar);
    }
    if (_items.isEmpty) {
      return const _Estado(mensaje: 'Todavía no se han emitido certificados.');
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _TarjetaCertificado(
          certificado: _items[i],
          descargando: _descargando == _items[i].id,
          onDescargar: () => _descargar(_items[i]),
        ),
      ),
    );
  }
}

class _TarjetaCertificado extends StatelessWidget {
  const _TarjetaCertificado({
    required this.certificado,
    required this.descargando,
    required this.onDescargar,
  });

  final Certificado certificado;
  final bool descargando;
  final VoidCallback onDescargar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = certificado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.estudianteNombre ?? 'Voluntario',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fila(context, 'Código', c.codigoVerificacion),
          _fila(context, 'Horas', '${c.horas.toStringAsFixed(0)} h'),
          _fila(context, 'Fecha', _formatear(c.fecha)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: descargando ? null : onDescargar,
              icon: descargando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Descargar PDF'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatear(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Estado extends StatelessWidget {
  const _Estado({required this.mensaje, this.onReintentar});

  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(mensaje),
          if (onReintentar != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
