import 'package:flutter/material.dart';

import '../../services/reporte_service.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  final _service = ReporteService();

  Map<String, dynamic>? _resumen;
  bool _cargando = true;
  bool _descargando = false;
  String? _error;

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
      final data = await _service.resumen();
      if (!mounted) return;
      setState(() {
        _resumen = data;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el resumen.';
        _cargando = false;
      });
    }
  }

  Future<void> _descargarCsv() async {
    setState(() => _descargando = true);
    try {
      await _service.descargarHorasCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV de horas descargado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga no disponible en esta plataforma.')),
      );
    } finally {
      if (mounted) setState(() => _descargando = false);
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
    final r = _resumen!;
    final tot = r['totales'] as Map<String, dynamic>;
    final porCarrera = (r['por_carrera'] as List? ?? []).cast<Map<String, dynamic>>();
    final topOrgs = (r['top_organizaciones'] as List? ?? []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _TituloAccion(
            titulo: 'Resumen general',
            accion: FilledButton.icon(
              onPressed: _descargando ? null : _descargarCsv,
              icon: _descargando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.download_rounded),
              label: const Text('Descargar CSV horas'),
            ),
          ),
          const SizedBox(height: 12),
          _GridTarjetas(
            items: [
              _Dato('Estudiantes', '${tot['estudiantes']}'),
              _Dato('Organizaciones', '${tot['organizaciones']}'),
              _Dato('Necesidades', '${tot['necesidades']} (${tot['necesidades_publicadas']} publicadas)'),
              _Dato('Postulaciones', '${tot['postulaciones']}'),
              _Dato('Validaciones', '${tot['validaciones']}'),
              _Dato('Horas totales', '${tot['horas_totales']} h'),
              _Dato('Certificados', '${tot['certificados']}'),
              _Dato('Sobrecarga (≥100 h)', '${tot['sobrecarga']}'),
            ],
          ),
          const SizedBox(height: 24),
          if (porCarrera.isNotEmpty) ...[
            const Text('Horas por carrera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...porCarrera.map(
              (c) => _FilaTabla(c['carrera'] as String, '${c['cantidad']} est.', '${c['horas']} h'),
            ),
            const SizedBox(height: 24),
          ],
          if (topOrgs.isNotEmpty) ...[
            const Text('Top organizaciones (por necesidades)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...topOrgs.map(
              (o) => _FilaTabla(o['nombre'] as String, '${o['necesidades']} necesidades', ''),
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloAccion extends StatelessWidget {
  const _TituloAccion({required this.titulo, required this.accion});

  final String titulo;
  final Widget accion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        accion,
      ],
    );
  }
}

class _GridTarjetas extends StatelessWidget {
  const _GridTarjetas({required this.items});

  final List<_Dato> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final d = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(d.label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text(d.valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        );
      },
    );
  }
}

class _Dato {
  const _Dato(this.label, this.valor);

  final String label;
  final String valor;
}

class _FilaTabla extends StatelessWidget {
  const _FilaTabla(this.col1, this.col2, this.col3);

  final String col1;
  final String col2;
  final String col3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(col1, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(col2, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (col3.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(col3, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
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
            Icons.assessment_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(mensaje),
          if (onReintentar != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}