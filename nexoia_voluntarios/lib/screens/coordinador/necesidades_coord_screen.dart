import 'package:flutter/material.dart';

import '../../models/necesidad.dart';
import '../../services/necesidad_service.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';

class NecesidadesCoordScreen extends StatefulWidget {
  const NecesidadesCoordScreen({super.key});

  @override
  State<NecesidadesCoordScreen> createState() => _NecesidadesCoordScreenState();
}

class _NecesidadesCoordScreenState extends State<NecesidadesCoordScreen> {
  final _service = NecesidadService();
  late Future<List<Necesidad>> _future;
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    _future = _service.listar();
  }

  Future<void> _recargar() async {
    setState(() => _future = _service.listar(estado: _query()));
    await _future;
  }

  String? _query() {
    if (_filtro == 'Publicadas') return 'publicada';
    if (_filtro == 'Borradores') return 'borrador';
    if (_filtro == 'En curso') return 'en_curso';
    if (_filtro == 'Finalizadas') return 'finalizada';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: ['Todas', 'Borradores', 'Publicadas', 'En curso', 'Finalizadas'].map((f) {
              final activo = f == _filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: activo,
                  onSelected: (_) {
                    setState(() => _filtro = f);
                    _future = _service.listar(estado: _query());
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
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
                    icon: Icons.assignment_outlined,
                    titulo: 'Sin necesidades',
                    mensaje: 'No hay resultados para este filtro.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final n = lista[i];
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
                                    n.titulo,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                EstadoBadge(estado: n.estado),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (n.naturaleza != null)
                                  TagChip(label: n.naturaleza!, icon: Icons.category_outlined),
                                if (n.ubicacion != null)
                                  TagChip(label: n.ubicacion!, icon: Icons.place_outlined),
                                TagChip(label: '${n.cupos} cupos', icon: Icons.groups_outlined),
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
