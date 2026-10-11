import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../models/asistencia.dart';
import '../services/asistencia_service.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({
    super.key,
    required this.necesidadId,
    this.necesidadTitulo,
  });

  final int necesidadId;
  final String? necesidadTitulo;

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final _service = AsistenciaService();

  QrGenerado? _qr;
  bool _cargando = true;
  String? _error;
  int _restante = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generar() async {
    _timer?.cancel();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final qr = await _service.generar(widget.necesidadId);
      if (!mounted) return;
      setState(() {
        _qr = qr;
        _restante = qr.segundos;
        _cargando = false;
      });
      _iniciarConteo();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo generar el código. Intenta de nuevo.';
      });
    }
  }

  void _iniciarConteo() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restante <= 1) {
        t.cancel();
        setState(() => _restante = 0);
      } else {
        setState(() => _restante--);
      }
    });
  }

  String get _mmss {
    final m = (_restante ~/ 60).toString().padLeft(2, '0');
    final s = (_restante % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expirado = _qr != null && _restante <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi asistencia')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.softGradient),
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.necesidadTitulo != null) ...[
                Text(
                  widget.necesidadTitulo!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'Muestra este código al coordinador para registrar tus horas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _cuerpo(expirado, scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(bool expirado, ColorScheme scheme) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _generar, child: const Text('Reintentar')),
        ],
      );
    }

    final qr = _qr!;
    return Column(
      children: [
        Opacity(
          opacity: expirado ? 0.25 : 1,
          child: QrImageView(
            data: qr.codigo,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          qr.codigo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        if (expirado)
          Column(
            children: [
              Text(
                'El código expiró',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _generar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Generar nuevo código'),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Válido por $_mmss',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
