import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/necesidad.dart';
import '../services/necesidad_service.dart';
import '../widgets/badges.dart';
import 'asistencia_screen.dart';

class NecesidadDetailScreen extends StatefulWidget {
  const NecesidadDetailScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<NecesidadDetailScreen> createState() => _NecesidadDetailScreenState();
}

class _NecesidadDetailScreenState extends State<NecesidadDetailScreen> {
  final _service = NecesidadService();
  bool _enviando = false;
  String? _error;
  bool _aceptada = false;
  bool _rechazada = false;

  Future<void> _aceptar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await _service.postular(widget.necesidad.id);
      if (!mounted) return;
      setState(() => _aceptada = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Aceptaste esta oportunidad!')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo aceptar. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _rechazar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await _service.rechazar(widget.necesidad.id);
      if (!mounted) return;
      setState(() => _rechazada = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oportunidad descartada.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo descartar. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _verQr() {
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
    final scheme = Theme.of(context).colorScheme;
    final fechaFormateada = n.fecha != null
        ? DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es').format(n.fecha!)
        : null;
    final duracionTexto = n.duracion != null ? '${n.duracion} horas' : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de oportunidad')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _acciones(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (n.naturaleza != null)
                  TagChip(label: n.naturaleza!, icon: Icons.category_outlined),
                if (n.ubicacion != null)
                  TagChip(label: n.ubicacion!, icon: Icons.place_outlined),
                if (fechaFormateada != null)
                  TagChip(label: fechaFormateada, icon: Icons.calendar_today_rounded),
                if (duracionTexto != null)
                  TagChip(label: duracionTexto, icon: Icons.schedule_rounded),
                TagChip(label: '${n.cupos} cupos', icon: Icons.groups_outlined),
                EstadoBadge(estado: n.estado),
              ],
            ),
            if (n.descripcion != null && n.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(n.descripcion!, style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface)),
            ],
            if (n.habilidadesRequeridas.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Habilidades requeridas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: n.habilidadesRequeridas
                    .map((h) => TagChip(label: h, icon: Icons.check_circle_outline_rounded))
                    .toList(),
              ),
            ],
            if (n.prioridad != null) ...[
              const SizedBox(height: 18),
              TagChip(label: 'Prioridad: ${n.prioridad}', icon: Icons.flag_outlined),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _acciones() {
    if (_aceptada) {
      return FilledButton.icon(
        onPressed: _verQr,
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text('Ver mi código QR'),
      );
    }

    if (_rechazada) {
      return const OutlinedButton(
        onPressed: null,
        child: Text('Oportunidad descartada'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _enviando ? null : _rechazar,
            child: const Text('Rechazar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _enviando ? null : _aceptar,
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Aceptar'),
          ),
        ),
      ],
    );
  }
}
