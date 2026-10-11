import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/postulacion.dart';
import '../services/necesidad_service.dart';
import '../widgets/badges.dart';
import '../widgets/empty_state.dart';
import '../widgets/soft_card.dart';
import 'asistencia_screen.dart';

class MisHorasScreen extends StatefulWidget {
  const MisHorasScreen({super.key});

  @override
  State<MisHorasScreen> createState() => _MisHorasScreenState();
}

class _MisHorasScreenState extends State<MisHorasScreen> {
  final _service = NecesidadService();
  late Future<List<Postulacion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.misPostulaciones();
  }

  Future<void> _recargar() async {
    setState(() => _future = _service.misPostulaciones());
    await _future;
  }

  void _abrirQr(Postulacion p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AsistenciaScreen(
          necesidadId: p.necesidadId,
          necesidadTitulo: p.necesidadTitulo,
        ),
      ),
    );
  }

  Future<void> _decidir(Postulacion p, {required bool aceptar}) async {
    try {
      if (aceptar) {
        await _service.postular(p.necesidadId);
      } else {
        await _service.rechazar(p.necesidadId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceptar ? '¡Invitación aceptada!' : 'Invitación rechazada.'),
        ),
      );
      await _recargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis horas')),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<Postulacion>>(
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
            final validadas = lista.where((p) => p.estado == 'validado').toList();
            final totalHoras = validadas.fold<double>(0, (sum, p) => sum + p.horas);
            final countValidados = validadas.length;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      children: [
                        _ImpactMetricsCard(
                          totalHoras: totalHoras,
                          actividadesValidadas: countValidados,
                          beneficiarios: countValidados * 12,
                          satisfaccion: 4.8,
                          logrosObjetivo: countValidados > 0 ? (countValidados / lista.length * 100).round() : 0,
                        ),
                        const SizedBox(height: 16),
                        _SolicitarSeguimientoCard(onPressed: () {
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
                      icon: Icons.event_note_outlined,
                      titulo: 'Aún no tienes horas registradas',
                      mensaje: 'Explora las oportunidades y acepta la que más te motive.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) => _TarjetaActividad(
                        postulacion: lista[i],
                        onVerQr: () => _abrirQr(lista[i]),
                        onAceptar: () => _decidir(lista[i], aceptar: true),
                        onRechazar: () => _decidir(lista[i], aceptar: false),
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

class _ImpactMetricsCard extends StatelessWidget {
  final double totalHoras;
  final int actividadesValidadas;
  final int beneficiarios;
  final double satisfaccion;
  final int logrosObjetivo;

  const _ImpactMetricsCard({
    required this.totalHoras,
    required this.actividadesValidadas,
    required this.beneficiarios,
    required this.satisfaccion,
    required this.logrosObjetivo,
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
                      'Tu impacto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    Text(
                      '$actividadesValidadas actividades · ${totalHoras.toStringAsFixed(totalHoras % 1 == 0 ? 0 : 1)} horas',
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
              Expanded(child: _MetricItem(label: 'Beneficiarios', value: beneficiarios.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF1B9E77))),
              Expanded(child: _MetricItem(label: 'Satisfacción', value: satisfaccion.toStringAsFixed(1), icon: Icons.star_rounded, color: const Color(0xFFE08A00), suffix: '/5')),
              Expanded(child: _MetricItem(label: 'Logro objetivo', value: '$logrosObjetivo%', icon: Icons.flag_rounded, color: const Color(0xFF0E7C66))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _MetricItem({
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

class _SolicitarSeguimientoCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _SolicitarSeguimientoCard({required this.onPressed});

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
                  'Solicita acompañamiento para tus actividades validadas.',
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

class _TarjetaActividad extends StatelessWidget {
  const _TarjetaActividad({
    required this.postulacion,
    required this.onVerQr,
    required this.onAceptar,
    required this.onRechazar,
  });

  final Postulacion postulacion;
  final VoidCallback onVerQr;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = postulacion;
    final titulo = p.necesidadTitulo ?? 'Oportunidad #${p.necesidadId}';

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
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EstadoBadge(estado: p.estado),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.necesidadNaturaleza != null)
                  TagChip(label: p.necesidadNaturaleza!, icon: Icons.category_outlined),
                if (p.necesidadUbicacion != null)
                  TagChip(label: p.necesidadUbicacion!, icon: Icons.place_outlined),
                TagChip(
                  label: '${p.horas.toStringAsFixed(p.horas % 1 == 0 ? 0 : 1)} h',
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            if (p.estado == 'sugerido') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRechazar,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onAceptar,
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (p.estado == 'aceptado' || p.estado == 'validado') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: p.estado == 'aceptado'
                    ? FilledButton.tonalIcon(
                        onPressed: onVerQr,
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Mostrar QR de asistencia'),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Asistencia validada',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}