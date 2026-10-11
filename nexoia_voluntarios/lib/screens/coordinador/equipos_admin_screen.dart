import 'package:flutter/material.dart';

import '../../models/equipo.dart';
import '../../models/necesidad.dart';
import '../../services/equipo_service.dart';
import '../../services/necesidad_service.dart';

class EquiposAdminScreen extends StatefulWidget {
  const EquiposAdminScreen({super.key});

  @override
  State<EquiposAdminScreen> createState() => _EquiposAdminScreenState();
}

class _EquiposAdminScreenState extends State<EquiposAdminScreen> {
  final _equipos = EquipoService();
  final _necesidades = NecesidadService();

  List<Equipo> _equiposList = [];
  List<Necesidad> _necesidadesList = [];
  bool _cargando = true;
  String? _error;
  int? _eliminando;

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
      final resultados = await Future.wait([
        _equipos.listar(),
        _necesidades.listar(estado: 'publicada'),
      ]);
      if (!mounted) return;
      setState(() {
        _equiposList = (resultados[0] as List).cast<Equipo>();
        _necesidadesList = (resultados[1] as List).cast<Necesidad>();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos.';
        _cargando = false;
      });
    }
  }

  Future<void> _armar(int necesidadId) async {
    try {
      final equipo = await _equipos.armar(necesidadId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipo ${equipo.id} armado para "${equipo.necesidadTitulo}".')),
      );
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo armar el equipo.')),
      );
    }
  }

  Future<void> _confirmarEliminar(Equipo e) async {
    final titulo = e.necesidadTitulo ?? 'Equipo #${e.id}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: Text('¿Eliminar el equipo de "$titulo"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await _eliminar(e.id);
  }

  Future<void> _eliminar(int equipoId) async {
    setState(() => _eliminando = equipoId);
    try {
      await _equipos.eliminar(equipoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipo eliminado.')),
      );
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar.')),
      );
    } finally {
      if (mounted) setState(() => _eliminando = null);
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
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_necesidadesList.isNotEmpty) ...[
            const Text(
              'Armar equipo automático',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _necesidadesList.map((n) {
                return ActionChip(
                  label: Text(n.titulo),
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                  onPressed: () => _armar(n.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (_equiposList.isEmpty)
            const _Estado(mensaje: 'No hay equipos creados.')
          else ...[
            Text(
              '${_equiposList.length} equipo(s)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._equiposList.map(
              (e) => _TarjetaEquipo(
                equipo: e,
                eliminando: _eliminando == e.id,
                onEliminar: () => _confirmarEliminar(e),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaEquipo extends StatelessWidget {
  const _TarjetaEquipo({
    required this.equipo,
    required this.eliminando,
    required this.onEliminar,
  });

  final Equipo equipo;
  final bool eliminando;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(Icons.groups_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  equipo.necesidadTitulo ?? 'Equipo #${equipo.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: eliminando ? null : onEliminar,
                icon: eliminando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Icon(Icons.delete_outline_rounded),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
          ),
          if (equipo.integrantes.isEmpty) ...[
            const SizedBox(height: 12),
            Text('Sin integrantes', style: TextStyle(color: scheme.onSurfaceVariant)),
          ] else ...[
            const SizedBox(height: 12),
            ...equipo.integrantes.map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      radius: 18,
                      child: Text(i.nombre.isNotEmpty ? i.nombre[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (i.carrera != null && i.carrera!.isNotEmpty)
                            Text(i.carrera!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        i.rol ?? '—',
                        style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (i.compatibilidad != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${i.compatibilidad}%',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
            Icons.groups_outlined,
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