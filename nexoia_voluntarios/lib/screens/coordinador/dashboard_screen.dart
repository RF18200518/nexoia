import 'package:flutter/material.dart';

import '../../models/indicador.dart';
import '../../services/indicador_service.dart';
import '../../widgets/badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/soft_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = IndicadorService();
  late Future<Indicadores> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.obtener();
  }

  Future<void> _recargar() async {
    setState(() => _future = _service.obtener());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _recargar,
      child: FutureBuilder<Indicadores>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              titulo: 'No se pudo cargar el dashboard',
              mensaje: 'Revisa tu conexión o credenciales.',
              accion: FilledButton.tonal(
                onPressed: _recargar,
                child: const Text('Reintentar'),
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _kpiGrid(data, scheme),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horas por carrera',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (data.porCarrera.isEmpty)
                      Text('Sin datos aún.', style: TextStyle(color: scheme.onSurfaceVariant))
                    else
                      Column(
                        children: data.porCarrera
                            .map((c) => _carreraRow(c, scheme))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiGrid(Indicadores d, ColorScheme scheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _kpiCard('Horas totales', d.horasTotal.toString(), Icons.hourglass_bottom_rounded, scheme),
        _kpiCard('Estudiantes', d.estudiantes.toString(), Icons.people_rounded, scheme),
        _kpiCard('Organizaciones aprobadas', d.organizacionesAprobadas.toString(), Icons.apartment_rounded, scheme),
        _kpiCard('Postulaciones', d.postulaciones.toString(), Icons.post_add_rounded, scheme),
        _kpiCard('Necesidades totales', d.necesidades.total.toString(), Icons.assignment_rounded, scheme),
        _kpiCard('Publicadas / Finalizadas', '${d.necesidades.publicadas} / ${d.necesidades.finalizadas}', Icons.flag_rounded, scheme),
      ],
    );
  }

  Widget _kpiCard(String titulo, String valor, IconData icon, ColorScheme scheme) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.primary.withValues(alpha: 0.72)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _carreraRow(IndicadorPorCarrera c, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.carrera, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${c.cantidad} estudiantes · ${c.horas} horas',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          TagChip(label: '${c.horas}h', icon: Icons.timer_outlined),
        ],
      ),
    );
  }
}
