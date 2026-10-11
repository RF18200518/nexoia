import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/necesidad.dart';
import '../../services/necesidad_service.dart';
import '../../services/organizacion_service.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/soft_card.dart';

class EvaluacionOrganizacionScreen extends StatefulWidget {
  const EvaluacionOrganizacionScreen({super.key});

  @override
  State<EvaluacionOrganizacionScreen> createState() => _EvaluacionOrganizacionScreenState();
}

class _EvaluacionOrganizacionScreenState extends State<EvaluacionOrganizacionScreen> {
  final _necService = NecesidadService();
  final _orgService = OrganizacionService();

  late Future<List<Necesidad>> _future;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final org = await _orgService.mia();
      setState(() => _future = _necService.listar(organizacionId: org.id));
    } catch (_) {
      setState(() => _future = Future.value([]));
    }
  }

  Future<void> _recargar() async {
    await _cargar();
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación / Mis horas'),
        actions: [
          IconButton(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
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
                titulo: 'No se pudo cargar',
                mensaje: 'Revisa tu conexión e intenta de nuevo.',
                accion: FilledButton.tonal(
                  onPressed: _recargar,
                  child: const Text('Reintentar'),
                ),
              );
            }

            final lista = snapshot.data ?? [];
            final publicadas = lista.where((n) => n.estado == 'publicada').length;
            final totalCupos = lista.fold<int>(0, (sum, n) => sum + n.cupos);
            final horasEstimadas = lista.fold<int>(0, (sum, n) => sum + (n.duracion ?? 4) * n.cupos);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      children: [
                        _ImpactMetricsCardOrg(
                          necesidadesPublicadas: publicadas,
                          totalCupos: totalCupos,
                          horasEstimadas: horasEstimadas,
                          satisfaccion: 4.8,
                          beneficiarios: totalCupos * 12,
                        ),
                        const SizedBox(height: 16),
                        _SolicitarSeguimientoCardOrg(onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Solicitud de seguimiento enviada')),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (lista.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.assignment_outlined,
                      titulo: 'Aún no has publicado necesidades',
                      mensaje: 'Ve a la pestaña "Publicar" y crea tu primera actividad.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) => _TarjetaNecesidadOrg(
                        necesidad: lista[i],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ImpactMetricsCardOrg extends StatelessWidget {
  final int necesidadesPublicadas;
  final int totalCupos;
  final int horasEstimadas;
  final double satisfaccion;
  final int beneficiarios;

  const _ImpactMetricsCardOrg({
    required this.necesidadesPublicadas,
    required this.totalCupos,
    required this.horasEstimadas,
    required this.satisfaccion,
    required this.beneficiarios,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impacto de tus actividades',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    Text(
                      '$necesidadesPublicadas necesidades · $totalCupos cupos totales',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MetricItemOrg(label: 'Beneficiarios', value: beneficiarios.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF1B9E77))),
              Expanded(child: _MetricItemOrg(label: 'Satisfacción', value: satisfaccion.toStringAsFixed(1), icon: Icons.star_rounded, color: const Color(0xFFE08A00), suffix: '/5')),
              Expanded(child: _MetricItemOrg(label: 'Horas estimadas', value: horasEstimadas.toString(), icon: Icons.schedule_rounded, color: const Color(0xFF0E7C66), suffix: ' h')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItemOrg extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _MetricItemOrg({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value + (suffix ?? ''),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SolicitarSeguimientoCardOrg extends StatelessWidget {
  final VoidCallback onPressed;

  const _SolicitarSeguimientoCardOrg({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Necesitas seguimiento?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicita acompañamiento para tus actividades.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
            label: const Text('Solicitar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaNecesidadOrg extends StatelessWidget {
  const _TarjetaNecesidadOrg({required this.necesidad});

  final Necesidad necesidad;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final scheme = Theme.of(context).colorScheme;
    final fechaFormateada = necesidad.fecha != null
        ? '${necesidad.fecha!.day}/${necesidad.fecha!.month}/${necesidad.fecha!.year}'
        : 'Sin fecha';
    final duracion = necesidad.duracion != null ? '${necesidad.duracion} h' : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    necesidad.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EstadoBadge(estado: necesidad.estado),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (necesidad.naturaleza != null)
                  TagChip(label: necesidad.naturaleza!, icon: Icons.category_outlined),
                if (necesidad.ubicacion != null)
                  TagChip(label: necesidad.ubicacion!, icon: Icons.place_outlined),
                TagChip(label: fechaFormateada, icon: Icons.calendar_today_rounded),
                TagChip(label: duracion, icon: Icons.schedule_rounded),
                TagChip(label: '${necesidad.cupos} cupos', icon: Icons.groups_outlined),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ver candidatos próximamente')),
                      );
                    },
                    icon: const Icon(Icons.people_outline_rounded, size: 18),
                    label: const Text('Ver candidatos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Evaluar resultados próximamente')),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Evaluar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}