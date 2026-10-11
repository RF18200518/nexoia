import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/necesidad.dart';
import '../../services/necesidad_service.dart';
import '../../services/organizacion_service.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import 'candidatos_screen.dart';
import 'publicar_necesidad_screen.dart';

class MisNecesidadesScreen extends StatefulWidget {
  const MisNecesidadesScreen({super.key});

  @override
  State<MisNecesidadesScreen> createState() => _MisNecesidadesScreenState();
}

class _MisNecesidadesScreenState extends State<MisNecesidadesScreen> {
  final _necService = NecesidadService();
  final _orgService = OrganizacionService();
  late Future<List<Necesidad>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Necesidad>> _cargar() async {
    final org = await _orgService.mia();
    return _necService.listar(organizacionId: org.id);
  }

  Future<void> _recargar() async {
    setState(() => _future = _cargar());
    await _future;
  }

  void _verCandidatos(Necesidad n) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CandidatosScreen(necesidad: n)),
    );
  }

  Future<void> _editarNecesidad(Necesidad n) async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicarNecesidadScreen(necesidadEditar: n)),
    );
    if (resultado == true) _recargar();
  }

  Future<void> _eliminarNecesidad(Necesidad n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar necesidad'),
        content: Text('¿Eliminar "${n.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // TODO: Implementar endpoint DELETE en backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Función en desarrollo')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: FutureBuilder<List<Necesidad>>(
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
              icon: Icons.assignment_outlined,
              titulo: 'Aún no publicas necesidades',
              mensaje: 'Usa la pestaña Publicar para crear tu primera oportunidad.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: lista.length,
            itemBuilder: (context, i) => _TarjetaNecesidad(
              necesidad: lista[i],
              onVerCandidatos: () => _verCandidatos(lista[i]),
              onEditar: () => _editarNecesidad(lista[i]),
              onEliminar: () => _eliminarNecesidad(lista[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaNecesidad extends StatelessWidget {
  const _TarjetaNecesidad({
    required this.necesidad,
    required this.onVerCandidatos,
    required this.onEditar,
    required this.onEliminar,
  });

  final Necesidad necesidad;
  final VoidCallback onVerCandidatos;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final n = necesidad;
    final scheme = Theme.of(context).colorScheme;
    final fechaStr = n.fecha != null
        ? DateFormat('d MMM yyyy HH:mm', 'es').format(n.fecha!)
        : 'Sin fecha definida';
    final cuposDisponibles = n.cupos; // TODO: calcular disponibles desde backend

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
                Expanded(
                  child: Text(
                    n.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EstadoBadge(estado: n.estado),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (n.naturaleza != null)
                  TagChip(label: n.naturaleza!, icon: Icons.category_outlined),
                if (n.ubicacion != null)
                  TagChip(label: n.ubicacion!, icon: Icons.place_outlined),
                TagChip(label: '$cuposDisponibles cupos', icon: Icons.groups_outlined),
                TagChip(label: n.fecha != null ? DateFormat('d MMM HH:mm', 'es').format(n.fecha!) : 'Sin fecha', icon: Icons.calendar_today_outlined),
                TagChip(label: '${n.cupos} cupos totales', icon: Icons.groups_outlined),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onVerCandidatos,
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('Ver candidatos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}