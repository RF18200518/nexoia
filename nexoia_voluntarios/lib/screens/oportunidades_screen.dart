import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/necesidad.dart';
import '../services/necesidad_service.dart';
import '../services/simulacion_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/feed_propuestas.dart';
import '../widgets/logo_ucn.dart';
import '../widgets/necesidad_card.dart';
import 'necesidad_detail_screen.dart';

class OportunidadesScreen extends StatefulWidget {
  const OportunidadesScreen({super.key});

  @override
  State<OportunidadesScreen> createState() => _OportunidadesScreenState();
}

class _OportunidadesScreenState extends State<OportunidadesScreen> {
  final _service = NecesidadService();
  final _simService = SimulacionService();
  final _busqueda = TextEditingController();

  late Future<List<Necesidad>> _future;
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    _future = _service.recomendadas();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    setState(() {
      _future = _service.recomendadas();
    });
    await _future;
  }

  Future<void> _reiniciarFeed() async {
    await _simService.reiniciar();
    _recargar();
  }

  List<Necesidad> _aplicarFiltros(List<Necesidad> lista) {
    final q = _busqueda.text.trim().toLowerCase();
    return lista.where((n) {
      final coincideFiltro =
          _filtro == 'Todas' || (n.naturaleza ?? 'Otras') == _filtro;
      final coincideTexto = q.isEmpty ||
          n.titulo.toLowerCase().contains(q) ||
          (n.descripcion ?? '').toLowerCase().contains(q);
      return coincideFiltro && coincideTexto;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nombre = context.watch<Session>().usuario?.nombre.split(' ').first ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recargar,
          child: FutureBuilder<List<Necesidad>>(
            future: _future,
            builder: (context, snapshot) {
              final cargando = snapshot.connectionState == ConnectionState.waiting;
              final error = snapshot.hasError;
              final data = snapshot.data ?? [];

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _encabezado(scheme, nombre)),
                  // FEED PROTAGÓNICO: "Propuestas para ti" - spec screen 2 principal
                  const SliverToBoxAdapter(child: FeedPropuestas()),
                  // Acciones del feed
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reiniciarFeed,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Nuevas propuestas'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _recargar,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('Actualizar'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!error && data.isNotEmpty)
                    SliverToBoxAdapter(child: _filtros(data)),
                  if (cargando)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        titulo: 'Sin conexión',
                        mensaje: 'No se pudieron cargar las oportunidades.\nDesliza hacia abajo para reintentar.',
                        accion: FilledButton.tonal(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    )
                  else
                    _lista(_aplicarFiltros(data)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _encabezado(ColorScheme scheme, String nombre) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.32),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LogoUcn(height: 34),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nombre.isEmpty ? 'Oportunidades' : 'Hola, $nombre',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encuentra un voluntariado que encaje contigo',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar oportunidades...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros(List<Necesidad> data) {
    final naturezas = <String>{
      'Todas',
      ...data.map((n) => n.naturaleza ?? 'Otras'),
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text(
            'Todas las oportunidades',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: naturezas.map((n) {
              final activo = n == _filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(n),
                  selected: activo,
                  onSelected: (_) => setState(() => _filtro = n),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _lista(List<Necesidad> lista) {
    if (lista.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          titulo: 'Nada por aquí',
          mensaje: 'No hay oportunidades que coincidan con tu búsqueda.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      sliver: SliverList.builder(
        itemCount: lista.length,
        itemBuilder: (context, i) {
          final n = lista[i];
          return NecesidadCard(
            necesidad: n,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NecesidadDetailScreen(necesidad: n),
              ),
            ),
          );
        },
      ),
    );
  }
}
