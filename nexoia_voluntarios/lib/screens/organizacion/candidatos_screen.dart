import 'package:flutter/material.dart';

import '../../models/candidato.dart';
import '../../models/necesidad.dart';
import '../../services/necesidad_service.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';

class CandidatosScreen extends StatefulWidget {
  const CandidatosScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<CandidatosScreen> createState() => _CandidatosScreenState();
}

class _CandidatosScreenState extends State<CandidatosScreen> {
  final _service = NecesidadService();
  late Future<List<Candidato>> _future;
  final Set<int> _invitados = {};

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Candidato>> _cargar() async {
    final lista = await _service.candidatos(widget.necesidad.id);
    _invitados
      ..clear()
      ..addAll(lista.where((c) => c.invitado).map((c) => c.estudianteId));
    return lista;
  }

  Future<void> _recargar() async {
    setState(() => _future = _cargar());
    await _future;
  }

  Future<void> _invitar(Candidato c) async {
    setState(() => _invitados.add(c.estudianteId));
    try {
      await _service.invitar(widget.necesidad.id, c.estudianteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitación enviada a ${c.nombre}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _invitados.remove(c.estudianteId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo invitar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.necesidad.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ordenados por compatibilidad',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: FutureBuilder<List<Candidato>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.wifi_off_rounded,
                      titulo: 'No se pudieron cargar',
                      mensaje: 'Revisa tu conexión e intenta de nuevo.',
                      accion: FilledButton.tonal(
                        onPressed: _recargar,
                        child: const Text('Reintentar'),
                      ),
                    );
                  }

                  final lista = snapshot.data ?? [];
                  if (lista.isEmpty) {
                    return const EmptyState(
                      icon: Icons.groups_outlined,
                      titulo: 'Sin candidatos',
                      mensaje: 'Aún no hay estudiantes con perfil registrado.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final c = lista[i];
                      final invitado = _invitados.contains(c.estudianteId);
                      return _TarjetaCandidato(
                        candidato: c,
                        invitado: invitado,
                        onInvitar: () => _invitar(c),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCandidato extends StatelessWidget {
  const _TarjetaCandidato({
    required this.candidato,
    required this.invitado,
    required this.onInvitar,
  });

  final Candidato candidato;
  final bool invitado;
  final VoidCallback onInvitar;

  Color _colorMatch(int v) {
    if (v >= 70) return const Color(0xFF1B9E77);
    if (v >= 40) return const Color(0xFFE08A00);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = candidato;
    final color = _colorMatch(c.compatibilidad);
    final iniciales = c.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    iniciales.isEmpty ? '?' : iniciales,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (c.carrera != null) c.carrera!,
                          if (c.anio != null) '${c.anio}º año',
                        ].join(' · '),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${c.compatibilidad}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (c.habilidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.habilidades
                    .map((h) => TagChip(label: h, icon: Icons.check_circle_outline_rounded))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            TagChip(
              label: '${c.horasAcumuladas} h acumuladas',
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: invitado
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Invitación enviada'),
                    )
                  : FilledButton.icon(
                      onPressed: onInvitar,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Invitar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
