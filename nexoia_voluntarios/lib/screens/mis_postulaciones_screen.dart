import 'package:flutter/material.dart';

import '../models/postulacion.dart';
import '../services/necesidad_service.dart';
import '../widgets/badges.dart';
import '../widgets/empty_state.dart';
import 'asistencia_screen.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
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
      appBar: AppBar(
        title: const Text('Mis horas / Postulaciones'),
      ),
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
            if (lista.isEmpty) {
              return const EmptyState(
                icon: Icons.event_note_outlined,
                titulo: 'Aún no te has postulado',
                mensaje: 'Explora las oportunidades y acepta la que más te motive.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: lista.length,
              itemBuilder: (context, i) => _TarjetaPostulacion(
                postulacion: lista[i],
                onVerQr: () => _abrirQr(lista[i]),
                onAceptar: () => _decidir(lista[i], aceptar: true),
                onRechazar: () => _decidir(lista[i], aceptar: false),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaPostulacion extends StatelessWidget {
  const _TarjetaPostulacion({
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
