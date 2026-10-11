import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/indicador.dart';
import '../../services/indicador_service.dart';
import '../../services/reporte_service.dart';
import '../../services/analytics_service.dart';
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
  final _reporteService = ReporteService();
  final _analytics = AnalyticsService();
  late Future<Indicadores> _future;
  late Future<Map<String, dynamic>> _resumenFuture;
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _future = _service.obtener();
    _resumenFuture = _reporteService.resumen();
    _analytics.trackScreenView('dashboard_coordinador');
  }

  Future<void> _recargar() async {
    setState(() {
      _future = _service.obtener();
      _resumenFuture = _reporteService.resumen();
    });
    await _future;
    _analytics.trackAction('refresh_dashboard');
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
              _header(scheme),
              const SizedBox(height: 16),
              _kpiGrid(data, scheme),
              const SizedBox(height: 20),
              if (_showChart) ...[
                _chartCard(data, scheme),
                const SizedBox(height: 20),
              ],
              _horasCarreraCard(data, scheme),
              const SizedBox(height: 20),
              _topOrgsCard(scheme),
              const SizedBox(height: 12),
              _actionsRow(scheme),
            ],
          );
        },
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vista general del programa',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: _showChart ? 'Ocultar gráficos' : 'Mostrar gráficos',
              onPressed: () => setState(() => _showChart = !_showChart),
              icon: Icon(_showChart ? Icons.bar_chart_rounded : Icons.view_list_rounded),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _recargar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiGrid(Indicadores d, ColorScheme scheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _kpiCard('Horas totales', d.horasTotal.toString(), Icons.hourglass_bottom_rounded, scheme, const Color(0xFF0E7C66)),
        _kpiCard('Estudiantes', d.estudiantes.toString(), Icons.people_rounded, scheme, const Color(0xFF3B82F6)),
        _kpiCard('Organizaciones', d.organizacionesAprobadas.toString(), Icons.apartment_rounded, scheme, const Color(0xFF8B5CF6)),
        _kpiCard('Postulaciones', d.postulaciones.toString(), Icons.post_add_rounded, scheme, const Color(0xFFF59E0B)),
        _kpiCard('Necesidades', d.necesidades.total.toString(), Icons.assignment_rounded, scheme, const Color(0xFFEC4899)),
        _kpiCard('Publicadas', '${d.necesidades.publicadas}', Icons.flag_rounded, scheme, const Color(0xFF06B6D4)),
      ],
    );
  }

  Widget _kpiCard(String titulo, String valor, IconData icon, ColorScheme scheme, Color accent) {
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
                colors: [accent, accent.withValues(alpha: 0.72)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(Indicadores d, ColorScheme scheme) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Horas por carrera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Barras'), icon: Icon(Icons.bar_chart_rounded)),
                  ButtonSegment(value: false, label: Text('Línea'), icon: Icon(Icons.show_chart_rounded)),
                ],
                selected: {_showChart},
                onSelectionChanged: (s) => setState(() => _showChart = s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: d.porCarrera.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_rounded, size: 48, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Sin datos de horas por carrera', style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : _BarLineChart(data: d.porCarrera, showBars: _showChart, scheme: scheme),
          ),
        ],
      ),
    );
  }

  Widget _horasCarreraCard(Indicadores d, ColorScheme scheme) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalle por carrera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
              ),
              Text(
                '${d.porCarrera.length} carreras',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (d.porCarrera.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Sin datos', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            )
          else
            Column(
              children: d.porCarrera.map((c) => _carreraRow(c, scheme)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _carreraRow(IndicadorPorCarrera c, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                c.carrera.isNotEmpty ? c.carrera[0].toUpperCase() : '?',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.carrera, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${c.cantidad} estudiantes · ${c.horas} horas',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
              ],
            ),
          ),
          TagChip(label: '${c.horas}h', icon: Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _topOrgsCard(ColorScheme scheme) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top organizaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _resumenFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final lista = (snapshot.data?['top_organizaciones'] as List? ?? [])
                  .cast<Map<String, dynamic>>();
              if (lista.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Sin datos de organizaciones',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                );
              }
              return Column(
                children: lista.asMap().entries.map((e) {
                  final o = e.value;
                  return _orgRow(
                    '${e.key + 1}',
                    o['nombre'] as String? ?? 'Organización',
                    (o['necesidades'] as num?)?.toInt() ?? 0,
                    scheme,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _orgRow(String rank, String nombre, int necesidades, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600))),
          TagChip(label: '$necesidades necesidades', icon: Icons.assignment_rounded),
        ],
      ),
    );
  }

  Widget _actionsRow(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _analytics.trackAction('export_pdf'),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Exportar PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _analytics.trackAction('export_csv'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Descargar CSV'),
          ),
        ),
      ],
    );
  }
}

class _BarLineChart extends StatelessWidget {
  const _BarLineChart({
    required this.data,
    required this.showBars,
    required this.scheme,
  });

  final List<IndicadorPorCarrera> data;
  final bool showBars;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.horas.toDouble());
    }).toList();

    if (showBars) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.map((e) => e.horas).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${item.carrera}\n${item.horas} horas',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].carrera,
                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.horas.toDouble(),
                  width: 28,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (data.map((x) => x.horas).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                    color: scheme.outlineVariant.withValues(alpha: 0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      return LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: (data.map((e) => e.horas).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final item = data[spot.x.toInt()];
                return LineTooltipItem(
                  '${item.carrera}\n${item.horas} horas',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].carrera,
                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: scheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 5,
                  color: scheme.primary,
                  strokeWidth: 2,
                  strokeColor: scheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.3),
                    scheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}