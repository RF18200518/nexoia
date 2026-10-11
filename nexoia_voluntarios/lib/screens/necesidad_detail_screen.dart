import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../models/necesidad.dart';
import '../models/postulacion.dart';
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
  final _session = Session();

  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  Postulacion? _miPostulacion;
  int _cuposDisponibles = 0;
  int _inscritosCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    setState(() => _cargando = true);
    try {
      // Verificar si el usuario ya tiene postulación en esta necesidad
      final user = _session.usuario;
      if (user != null) {
        final postulaciones = await _service.misPostulaciones();
        _miPostulacion = postulaciones
            .where((p) => p.necesidadId == widget.necesidad.id)
            .firstOrNull;
      }

      // Obtener conteo de inscritos y cupos disponibles
      final inscritos = await _service.obtenerInscritos(widget.necesidad.id);
      _inscritosCount = inscritos.length;
      _cuposDisponibles = (widget.necesidad.cupos - _inscritosCount).clamp(0, widget.necesidad.cupos);

      if (mounted) setState(() => _cargando = false);
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.necesidad;
    final heroImage = _getHeroImage(n.naturaleza);
    final esEstudiante = _session.usuario?.rol == 'estudiante';
    final yaInscrito = _miPostulacion != null;
    final estadoPostulacion = _miPostulacion?.estado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de oportunidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        actions: [
          if (yaInscrito)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _cargarEstado,
              tooltip: 'Actualizar estado',
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                        Image.network(
                          _getHeroImage(widget.necesidad.naturaleza),
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            ),
                          ),
                        ),
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
                                    shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))],
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
                                    _TagMini(
                                      label: _cuposDisponibles > 0 ? '$_cuposDisponibles disponibles' : 'Cupo lleno',
                                      icon: _cuposDisponibles > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                                    ),
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
                        // Estado de inscripción prominente
                        if (esEstudiante) _buildEstadoInscripcion(),
                        const SizedBox(height: 20),

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

                        // Cuándo y dónde
                        _InfoCard(
                          title: 'Cuándo y dónde',
                          children: [
                            if (widget.necesidad.fecha != null)
                              _InfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Fecha',
                                value: DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es_ES').format(widget.necesidad.fecha!),
                              ),
                            if (widget.necesidad.fecha != null)
                              _InfoRow(
                                icon: Icons.access_time_rounded,
                                label: 'Hora',
                                value: DateFormat('HH:mm', 'es_ES').format(widget.necesidad.fecha!),
                              ),
                            if (widget.necesidad.duracion != null)
                              _InfoRow(icon: Icons.schedule_rounded, label: 'Duración', value: '${widget.necesidad.duracion} horas'),
                            if (widget.necesidad.ubicacion != null)
                              _InfoRow(icon: Icons.place_outlined, label: 'Ubicación', value: widget.necesidad.ubicacion!),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Cupos y disponibilidad
                        _InfoCard(
                          title: 'Cupos y disponibilidad',
                          children: [
                            _InfoRow(icon: Icons.groups_outlined, label: 'Cupos totales', value: '${widget.necesidad.cupos}'),
                            _InfoRow(icon: Icons.people_rounded, label: 'Inscritos', value: '$_inscritosCount'),
                            _InfoRow(
                              icon: _cuposDisponibles > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                              label: 'Disponibles',
                              value: _cuposDisponibles > 0 ? '$_cuposDisponibles cupos' : 'Cupo completo',
                            ),
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

                        // Organizador info
                        _InfoCard(
                          title: 'Organizador',
                          children: [
                            _InfoRow(icon: Icons.apartment_outlined, label: 'Organización', value: widget.necesidad.organizacionNombre ?? 'Organización asociada'),
                          ],
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
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

                        const SizedBox(height: 100), // espacio para bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEstadoInscripcion() {
    if (_miPostulacion == null) {
      return _EstadoCard(
        icon: Icons.event_available_rounded,
        color: Colors.blue,
        titulo: 'No inscrito',
        subtitulo: 'Esta oportunidad está disponible para ti',
        accion: FilledButton.icon(
          onPressed: _cuposDisponibles > 0 ? _aceptar : null,
          icon: const Icon(Icons.volunteer_activism_rounded),
          label: Text(_cuposDisponibles > 0 ? 'Quiero ir' : 'Cupo completo'),
        ),
      );
    }

    final estado = _miPostulacion!.estado;
    switch (estado) {
      case 'sugerido':
        return _EstadoCard(
          icon: Icons.mail_outline_rounded,
          color: Colors.orange,
          titulo: 'Invitación recibida',
          subtitulo: 'Una organización te invitó a participar',
          accion: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rechazar,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _aceptar,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Aceptar invitación'),
                ),
              ),
            ],
          ),
        );
      case 'aceptado':
        return _EstadoCard(
          icon: Icons.check_circle_outline_rounded,
          color: Colors.green,
          titulo: 'Inscrito - Pendiente de asistir',
          subtitulo: 'Tu plaza está confirmada. Genera tu QR el día de la actividad.',
          accion: FilledButton.icon(
            onPressed: _verQr,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Ver mi código QR'),
          ),
        );
      case 'validado':
        return _EstadoCard(
          icon: Icons.verified_rounded,
          color: Colors.blue,
          titulo: 'Asistencia validada',
          subtitulo: '¡Completaste esta actividad! Se sumaron ${_miPostulacion!.horas.toStringAsFixed(0)} horas a tu perfil.',
          accion: OutlinedButton.icon(
            onPressed: _verQr,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Ver certificado'),
          ),
        );
      case 'rechazado':
        return _EstadoCard(
          icon: Icons.cancel_outlined,
          color: Colors.grey,
          titulo: 'Descartada',
          subtitulo: 'Rechazaste o descartaste esta oportunidad',
          accion: FilledButton.icon(
            onPressed: () => _aceptar(),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reconsiderar'),
          ),
        );
      default:
        return _EstadoCard(
          icon: Icons.help_outline,
          color: Colors.grey,
          titulo: 'Estado: $estado',
          subtitulo: 'Estado desconocido',
          accion: const SizedBox.shrink(),
        );
    }
  }

  Future<void> _aceptar() async {
    HapticFeedback.mediumImpact();
    setState(() { _enviando = true; _error = null; });
    try {
      await _service.postular(widget.necesidad.id);
      if (!mounted) return;
      _analytics.trackAction('aceptar_necesidad', params: {'necesidad_id': widget.necesidad.id});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Te inscribiste! Tu plaza está confirmada.')));
      await _cargarEstado();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo inscribir. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _rechazar() async {
    HapticFeedback.lightImpact();
    setState(() { _enviando = true; _error = null; });
    try {
      await _service.rechazar(widget.necesidad.id);
      if (!mounted) return;
      _analytics.trackAction('rechazar_necesidad', params: {'necesidad_id': widget.necesidad.id});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oportunidad descartada.')));
      await _cargarEstado();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo descartar. Intenta nuevamente.');
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewPadding.bottom + 20,
          top: 8,
        ),
        child: _miPostulacion == null
            ? FilledButton.icon(
                onPressed: _cuposDisponibles > 0 && !_enviando ? _aceptar : null,
                icon: _enviando
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.volunteer_activism_rounded),
                label: Text(_cuposDisponibles > 0 ? 'Inscribirme ahora' : 'Cupo completo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  String _getHeroImage(String? naturaleza) {
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
    if (naturaleza == null) return 'https://images.unsplash.com/photo-1529156069898-49953e39f3ac?w=800&q=80';
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  const _EstadoCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.accion,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final Widget accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        if (accion is! SizedBox) ...[
          const SizedBox(height: 12),
          accion,
        ],
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
            width: 36, height: 36,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 18)),
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