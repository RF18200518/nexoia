import 'package:flutter/material.dart';

import '../../models/organizacion.dart';
import '../../services/organizacion_service.dart';
import '../../widgets/empty_state.dart';

class OrganizacionesScreen extends StatefulWidget {
  const OrganizacionesScreen({super.key});

  @override
  State<OrganizacionesScreen> createState() => _OrganizacionesScreenState();
}

class _OrganizacionesScreenState extends State<OrganizacionesScreen> {
  final _service = OrganizacionService();
  late Future<List<Organizacion>> _future;
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    _future = _service.listar();
  }

  Future<void> _recargar() async {
    setState(() => _future = _service.listar(estado: _estadoQuery()));
    await _future;
  }

  String? _estadoQuery() {
    if (_filtro == 'Pendientes') return 'pendiente';
    if (_filtro == 'Aprobadas') return 'aprobada';
    return null;
  }

  Future<void> _cambiarEstado(Organizacion o, String nuevo) async {
    try {
      await _service.cambiarEstado(o.id, nuevo);
      await _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Organización actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: ['Todas', 'Pendientes', 'Aprobadas'].map((f) {
              final activo = f == _filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: activo,
                  onSelected: (_) {
                    setState(() => _filtro = f);
                    _future = _service.listar(estado: _estadoQuery());
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _recargar,
            child: FutureBuilder<List<Organizacion>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.wifi_off_rounded,
                    titulo: 'No se pudieron cargar',
                    mensaje: 'Reintenta deslizando hacia abajo.',
                    accion: FilledButton.tonal(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  );
                }

                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const EmptyState(
                    icon: Icons.apartment_outlined,
                    titulo: 'Sin organizaciones',
                    mensaje: 'No hay resultados para este filtro.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final o = lista[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    o.nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (o.estado == 'aprobada'
                                            ? scheme.primaryContainer
                                            : scheme.tertiaryContainer)
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    o.estado[0].toUpperCase() + o.estado.substring(1),
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                            if (o.tipo != null) ...[
                              const SizedBox(height: 6),
                              Text(o.tipo!,
                                  style: TextStyle(color: scheme.onSurfaceVariant)),
                            ],
                            if (o.contacto != null) ...[
                              const SizedBox(height: 6),
                              Text(o.contacto!,
                                  style: TextStyle(color: scheme.onSurfaceVariant)),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (o.estado == 'pendiente')
                                  OutlinedButton(
                                    onPressed: () => _cambiarEstado(o, 'aprobada'),
                                    child: const Text('Aprobar'),
                                  ),
                                if (o.estado == 'aprobada')
                                  FilledButton.tonal(
                                    onPressed: () => _cambiarEstado(o, 'pendiente'),
                                    child: const Text('Marcar como pendiente'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
