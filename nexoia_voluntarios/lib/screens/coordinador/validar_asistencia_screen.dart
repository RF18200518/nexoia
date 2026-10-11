import 'package:flutter/material.dart';

import '../../models/asistencia.dart';
import '../../services/asistencia_service.dart';

class ValidarAsistenciaScreen extends StatefulWidget {
  const ValidarAsistenciaScreen({super.key});

  @override
  State<ValidarAsistenciaScreen> createState() => _ValidarAsistenciaScreenState();
}

class _ValidarAsistenciaScreenState extends State<ValidarAsistenciaScreen> {
  final _controller = TextEditingController();
  final _service = AsistenciaService();

  bool _enviando = false;
  ValidarResultado? _resultado;
  final List<ValidarResultado> _historial = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _resultado = null;
    });
    try {
      final r = await _service.validar(codigo);
      if (!mounted) return;
      setState(() => _resultado = r);
      if (r.ok) {
        _controller.clear();
        _historial.insert(0, r);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultado = ValidarResultado(
            ok: false,
            mensaje: 'No se pudo validar. Revisa tu conexión.',
          ));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Validar asistencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código que muestra el voluntario para sumar sus horas.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _enviarConEnter(),
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'NX-XXXXXXXX',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _enviando ? null : _validar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Validar'),
              ),
            ],
          ),
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 18),
          _TarjetaResultado(resultado: _resultado!),
        ],
        if (_historial.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Validaciones recientes (${_historial.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._historial.take(10).map((r) => _FilaHistorial(resultado: r)),
        ],
      ],
    );
  }

  void _enviarConEnter() {
    if (!_enviando) _validar();
  }
}

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({required this.resultado});

  final ValidarResultado resultado;

  @override
  Widget build(BuildContext context) {
    final ok = resultado.ok;
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? const Color(0xFF1B9E77) : scheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  resultado.mensaje,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          if (ok) ...[
            const SizedBox(height: 14),
            if (resultado.estudiante != null)
              _fila('Voluntario', resultado.estudiante!),
            if (resultado.necesidad != null)
              _fila('Actividad', resultado.necesidad!),
            if (resultado.horas != null)
              _fila('Horas sumadas', '${resultado.horas!.toStringAsFixed(0)} h'),
          ],
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.resultado});

  final ValidarResultado resultado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: const Color(0xFF1B9E77), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.estudiante ?? 'Voluntario',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (resultado.necesidad != null)
                  Text(
                    resultado.necesidad!,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (resultado.horas != null)
            Text(
              '+${resultado.horas!.toStringAsFixed(0)} h',
              style: TextStyle(color: const Color(0xFF1B9E77), fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}
