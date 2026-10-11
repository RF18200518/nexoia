import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/necesidad.dart';
import '../services/necesidad_service.dart';
import '../services/analytics_service.dart';
import 'asistencia_screen.dart';

class NecesidadDetailScreen extends StatefulWidget {
  const NecesidadDetailScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<NecesidadDetailScreen> createState() => _NecesidadDetailScreenState();
}

class _NecesidadDetailScreenState extends State<NecesidadDetailScreen> {
  final _service = NecesidadService();
  final _analytics = AnalyticsService();
  bool _enviando = false;
  String? _error;
  bool _aceptada = false;
  bool _rechazada = false;

  @override
  void initState() {
    super.initState();
    _analytics.trackScreenView('necesidad_detail_${widget.necesidad.id}');
  }

  Future<void> _aceptar() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await _service.postular(widget.necesidad.id);
      if (!mounted) return;
      setState(() => _aceptada = true);
      _analytics.trackAction('aceptar_necesidad', params: {'necesidad_id': widget.necesidad.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Aceptaste esta oportunidad!')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _analytics.trackError(e.message, screen: 'necesidad_detail');
    } catch (_) {
      setState(() => _error = 'No se pudo aceptar. Intenta nuevamente.');
      _analytics.trackError('unknown', screen: 'necesidad_detail');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _rechazar() async {
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await _service.rechazar(widget.necesidad.id);
      if (!mounted) return;
      setState(() => _rechazada = true);
      _analytics.trackAction('rechazar_necesidad', params: {'necesidad_id': widget.necesidad.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oportunidad descartada.')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _analytics.trackError(e.message, screen: 'necesidad_detail');
    } catch (_) {
      setState(() => _error = 'No se pudo descartar. Intenta nuevamente.');
      _analytics.trackError('unknown', screen: 'necesidad_detail');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _verQr() {
    _analytics.trackAction('ver_qr', params: {'necesidad_id': widget.necesidad.id});
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AsistenciaScreen(
          necesidadId: widget.necesidad.id,
          necesidadTitulo: widget.necesidad.titulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.necesidad;
    final heroImage = _getHeroImage(n.naturaleza);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de oportunidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero image con título
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen hero
                  Image.network(
                    heroImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.volunteer_activism_rounded, size: 64),
                    ),
                  ),
                  // Gradiente overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Título en la parte inferior
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.necesidad.titulo,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (widget.necesidad.naturaleza != null)
                                _TagMini(label: widget.necesidad.naturaleza!, icon: Icons.category_outlined),
                              if (widget.necesidad.ubicacion != null)
                                _TagMini(label: widget.necesidad.ubicacion!, icon: Icons.place_outlined),
                              if (widget.necesidad.fecha != null)
                                _TagMini(
                                  label: DateFormat('d MMM yyyy', 'es').format(widget.necesidad.fecha!),
                                  icon: Icons.calendar_today_rounded,
                                ),
                              _TagMini(label: '${widget.necesidad.cupos} cupos', icon: Icons.groups_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  if (widget.necesidad.descripcion != null && widget.necesidad.descripcion!.isNotEmpty) ...[
                    _sectionTitle('Descripción', Icons.description_outlined),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.necesidad.descripcion!,
                        style: TextStyle(fontSize: 15.5, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Detalles en tarjetas
                  _InfoCard(
                    title: 'Cuándo y dónde',
                    children: [
                      if (widget.necesidad.fecha != null)
                        _InfoRow(icon: Icons.calendar_today_rounded, label: 'Fecha', value: DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es').format(widget.necesidad.fecha!)),
                      if (widget.necesidad.duracion != null)
                        _InfoRow(icon: Icons.schedule_rounded, label: 'Duración', value: '${widget.necesidad.duracion} horas'),
                      if (widget.necesidad.ubicacion != null)
                        _InfoRow(icon: Icons.place_outlined, label: 'Ubicación', value: widget.necesidad.ubicacion!),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _InfoCard(
                    title: 'Cupos y disponibilidad',
                    children: [
                      _InfoRow(icon: Icons.groups_outlined, label: 'Cupos totales', value: '${widget.necesidad.cupos}'),
                      _InfoRow(icon: Icons.flag_outlined, label: 'Prioridad', value: widget.necesidad.prioridad ?? 'Normal'),
                      _InfoRow(icon: Icons.category_outlined, label: 'Categoría', value: widget.necesidad.naturaleza ?? 'General'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Habilidades requeridas
                  if (widget.necesidad.habilidadesRequeridas.isNotEmpty) ...[
                    _sectionTitle('Habilidades requeridas', Icons.psychology_outlined),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.necesidad.habilidadesRequeridas
                          .map((h) => Chip(
                                label: Text(h),
                                avatar: Icon(Icons.check_circle_outline_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 80), // espacio para bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewPadding.bottom + 20,
          top: 8,
        ),
        child: _acciones(),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(title.isNotEmpty ? Icons.description_outlined : Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _acciones() {
    if (_aceptada) {
      return Semantics(
        button: true,
        label: 'Ver código QR de asistencia',
        child: FilledButton.icon(
          onPressed: _verQr,
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Ver mi código QR'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (_rechazada) {
      return Semantics(
        label: 'Oportunidad descartada',
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Oportunidad descartada'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Rechazar esta oportunidad',
            child: OutlinedButton(
              onPressed: _enviando ? null : _rechazar,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Rechazar'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Semantics(
            button: true,
            label: 'Aceptar esta oportunidad de voluntariado',
            child: FilledButton(
              onPressed: _enviando ? null : _aceptar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Aceptar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  String _getHeroImage(String? naturaleza) {
    // Imágenes de Unsplash para actividades de voluntariado en Nicaragua
    final Map<String, String> images = {
      'medio ambiente': 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800&q=80',
      'reforestación': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
      'limpieza': 'https://images.unsplash.com/photo-1581092160607-ee22621dd684?w=800&q=80',
      'educación': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80',
      'tutoría': 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&q=80',
      'apoyo escolar': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80',
      'salud': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80',
      'comunitario': 'https://images.unsplash.com/photo-1529156069898-49953e39f3ac?w=800&q=80',
      'construcción': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&q=80',
      'tecnología': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80',
      'diseño': 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&q=80',
      'programación': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
    };

    if (naturaleza == null) {
      return 'https://images.unsplash.com/photo-1529156069898-49953e39f3ac?w=800&q=80';
    }

    final lower = naturaleza.toLowerCase();
    for (final entry in images.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'https://images.unsplash.com/photo-1529156069898-49953e39f3ac?w=800&q=80';
  }
}

class _TagMini extends StatelessWidget {
  const _TagMini({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, color: scheme.onPrimaryContainer, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}