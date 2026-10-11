import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/necesidad.dart';
import '../models/simulacion.dart';
import '../services/simulacion_service.dart';
import '../screens/necesidad_detail_screen.dart';
import 'necesidad_card.dart';

class FeedPropuestas extends StatefulWidget {
  const FeedPropuestas({super.key});

  @override
  State<FeedPropuestas> createState() => _FeedPropuestasState();
}

class _FeedPropuestasState extends State<FeedPropuestas> {
  final _service = SimulacionService();

  FeedSimulacion? _feed;
  bool _cargando = true;
  String? _error;
  int _restante = 0;

  Timer? _poll;
  Timer? _tick;

  final Set<int> _idsAnteriores = {};
  final Set<int> _ultimosNuevos = {};
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    _cargar(mostrarAviso: false);
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _cargar());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_restante > 0) {
        setState(() => _restante--);
      } else if (_ultimosNuevos.isNotEmpty) {
        setState(() => _ultimosNuevos.clear());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool mostrarAviso = true}) async {
    try {
      final feed = await _service.misPropuestas();
      if (!mounted) return;

      final actuales = feed.propuestas.map((p) => p.id).toSet();
      final nuevos = actuales.difference(_idsAnteriores);

      setState(() {
        _feed = feed;
        _error = null;
        _cargando = false;
        _restante = feed.siguienteEn ?? 0;
        _ultimosNuevos
          ..clear()
          ..addAll(nuevos);
      });
      _idsAnteriores
        ..clear()
        ..addAll(actuales);

      if (mostrarAviso && !_primeraCarga && nuevos.isNotEmpty) {
        _avisarLlegada();
      }
      _primeraCarga = false;
    } catch (e) {
      if (!mounted) return;
      if (_feed == null) {
        setState(() {
          _cargando = false;
          _error = 'No se pudieron cargar tus propuestas.';
        });
      }
    }
  }

  void _avisarLlegada() {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E7C66),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Llegó una nueva propuesta para ti!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reiniciar() async {
    setState(() => _cargando = true);
    try {
      final feed = await _service.reiniciar();
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _restante = feed.siguienteEn ?? 0;
        _ultimosNuevos.clear();
        _cargando = false;
      });
      _idsAnteriores
        ..clear()
        ..addAll(feed.propuestas.map((p) => p.id));
      _primeraCarga = false;
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feed = _feed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecera(scheme, feed),
          const SizedBox(height: 12),
          if (_cargando && feed == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _mensaje(scheme, Icons.wifi_off_rounded, _error!, onRetry: true)
          else if (feed != null) ...[
            if (feed.activa && _restante > 0) _contador(scheme),
            ..._tarjetas(feed),
            if (feed.terminada) _estadoFinal(scheme, feed),
          ],
        ],
      ),
    );
  }

  Widget _cabecera(ColorScheme scheme, FeedSimulacion? feed) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB020), Color(0xFFFF7A00)],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Propuestas para ti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feed == null
                    ? 'Basadas en tus intereses'
                    : 'Según tus intereses · ${feed.recibidas}/${feed.total} recibidas',
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (feed != null && feed.activa) const _LiveDot(),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Volver a generar',
          onPressed: _cargando ? null : _reiniciar,
          icon: Icon(Icons.refresh_rounded, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _contador(ColorScheme scheme) {
    final m = (_restante ~/ 60).toString().padLeft(1, '0');
    final s = (_restante % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Próxima propuesta en camino…',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            '$m:$s',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _tarjetas(FeedSimulacion feed) {
    return feed.propuestas.map((n) {
      return NecesidadCard(
        necesidad: n,
        nueva: _ultimosNuevos.contains(n.id),
        onTap: () => _abrir(n),
      );
    }).toList();
  }

  void _abrir(Necesidad n) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NecesidadDetailScreen(necesidad: n)),
    );
  }

  Widget _estadoFinal(ColorScheme scheme, FeedSimulacion feed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Por ahora no hay más propuestas para ti. '
              'Postúlate a las que te interesen y vuelve más tarde.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensaje(ColorScheme scheme, IconData icon, String texto,
      {bool onRetry = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
          if (onRetry)
            TextButton(
              onPressed: () => _cargar(mostrarAviso: false),
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B9E77).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1B9E77),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'EN VIVO',
            style: TextStyle(
              color: Color(0xFF1B9E77),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
