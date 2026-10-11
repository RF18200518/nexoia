import 'package:flutter/material.dart';

import '../../models/estudiante_resumen.dart';
import '../../services/certificado_service.dart';
import '../../services/estudiante_service.dart';

class EstudiantesAdminScreen extends StatefulWidget {
  const EstudiantesAdminScreen({super.key});

  @override
  State<EstudiantesAdminScreen> createState() => _EstudiantesAdminScreenState();
}

class _EstudiantesAdminScreenState extends State<EstudiantesAdminScreen> {
  final _estudiantes = EstudianteService();
  final _certificados = CertificadoService();

  List<EstudianteResumen> _items = [];
  bool _cargando = true;
  String? _error;
  int? _emitiendo;

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
      final data = await _estudiantes.listar();
      if (!mounted) return;
      setState(() {
        _items = data;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los estudiantes.';
        _cargando = false;
      });
    }
  }

  Future<void> _emitir(EstudianteResumen e) async {
    setState(() => _emitiendo = e.id);
    try {
      final cert = await _certificados.emitir(e.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Certificado ${cert.codigoVerificacion} emitido a ${e.nombre}.',
          ),
        ),
      );
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo emitir el certificado.')),
      );
    } finally {
      if (mounted) setState(() => _emitiendo = null);
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
      return const _Estado(mensaje: 'Aún no hay estudiantes registrados.');
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _TarjetaEstudiante(
          estudiante: _items[i],
          emitiendo: _emitiendo == _items[i].id,
          onEmitir: () => _emitir(_items[i]),
        ),
      ),
    );
  }
}

class _TarjetaEstudiante extends StatelessWidget {
  const _TarjetaEstudiante({
    required this.estudiante,
    required this.emitiendo,
    required this.onEmitir,
  });

  final EstudianteResumen estudiante;
  final bool emitiendo;
  final VoidCallback onEmitir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = estudiante;
    final subtitulo = [
      if (e.carrera != null) e.carrera,
      if (e.anio != null) '${e.anio}° año',
    ].join(' · ');

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
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(_iniciales(e.nombre)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    if (subtitulo.isNotEmpty)
                      Text(
                        subtitulo,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (e.sobrecarga)
                _Badge(
                  texto: 'Sobrecarga',
                  color: scheme.error,
                  icono: Icons.warning_amber_rounded,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                texto: '${e.horasAcumuladas} h',
                color: scheme.primary,
                icono: Icons.schedule_rounded,
              ),
              _Badge(
                texto: '${e.certificados} certificado(s)',
                color: const Color(0xFF7C3AED),
                icono: Icons.card_membership_rounded,
              ),
            ],
          ),
          if (e.habilidades.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              e.habilidades.take(4).join(' · '),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: emitiendo ? null : onEmitir,
              icon: emitiendo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.workspace_premium_rounded),
              label: const Text('Emitir certificado'),
            ),
          ),
        ],
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.texto, required this.color, required this.icono});

  final String texto;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
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
            Icons.groups_outlined,
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
