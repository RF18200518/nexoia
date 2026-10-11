import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../models/certificado.dart';
import '../models/simulacion.dart';
import '../services/certificado_service.dart';
import '../services/simulacion_service.dart';
import '../widgets/badges.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _habilidadCtrl = TextEditingController();
  List<String> _habilidades = [];
  final _carreraCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  final _certService = CertificadoService();
  List<Certificado> _certificados = [];
  bool _cargandoCerts = true;
  int? _descargando;

  // Intereses
  final _simService = SimulacionService();
  List<Interes> _catalogoIntereses = const [];
  final Set<String> _intereses = {};
  bool _cargandoIntereses = true;

  @override
  void initState() {
    super.initState();
    final u = context.read<Session>().usuario;
    _habilidades = List<String>.from(u?.perfil?.habilidades ?? []);
    _intereses.addAll(u?.perfil?.intereses ?? []);
    _carreraCtrl.text = u?.perfil?.carrera ?? '';
    _anioCtrl.text = u?.perfil?.anio?.toString() ?? '';
    _cargarCertificados();
    _cargarCatalogoIntereses();
  }

  Future<void> _cargarCatalogoIntereses() async {
    try {
      final lista = await _simService.intereses();
      if (!mounted) return;
      setState(() {
        _catalogoIntereses = lista;
        _cargandoIntereses = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoIntereses = false);
    }
  }

  Future<void> _cargarCertificados() async {
    try {
      final data = await _certService.mios();
      if (!mounted) return;
      setState(() {
        _certificados = data;
        _cargandoCerts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoCerts = false);
    }
  }

  Future<void> _descargarCertificado(Certificado c) async {
    setState(() => _descargando = c.id);
    try {
      await _certService.descargarPdf(c);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descarga no disponible en esta plataforma.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _descargando = null);
    }
  }

  @override
  void dispose() {
    _habilidadCtrl.dispose();
    _carreraCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  void _agregarHabilidad() {
    final v = _habilidadCtrl.text.trim();
    if (v.isEmpty) return;
    if (!_habilidades.contains(v)) {
      setState(() => _habilidades.add(v));
    }
    _habilidadCtrl.clear();
  }

  void _quitarHabilidad(String h) {
    setState(() => _habilidades.remove(h));
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await context.read<Session>().actualizarPerfil(
            carrera: _carreraCtrl.text.trim().isEmpty ? null : _carreraCtrl.text.trim(),
            anio: int.tryParse(_anioCtrl.text.trim()),
            habilidades: _habilidades,
            intereses: _intereses.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado correctamente')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo guardar el perfil.');
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = context.watch<Session>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<Session>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Salir'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primary,
                    child: Icon(Icons.person_rounded, color: scheme.onPrimary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u?.nombre ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(u?.correo ?? '', style: TextStyle(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        TagChip(label: 'Horas acumuladas: ${u?.perfil?.horasAcumuladas ?? 0}', icon: Icons.hourglass_bottom_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                    'Datos académicos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _carreraCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Carrera',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _anioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Año (1-5)',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_membership_rounded, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Mis certificados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_cargandoCerts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_certificados.isEmpty)
                    Text(
                      'Aún no tienes certificados. ¡Sigue participando!',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    ..._certificados.map(
                      (c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.workspace_premium_rounded,
                          color: scheme.primary,
                        ),
                        title: Text(c.codigoVerificacion),
                        subtitle: Text(
                          '${c.horas.toStringAsFixed(0)} horas · '
                          '${c.fecha.day}/${c.fecha.month}/${c.fecha.year}',
                        ),
                        trailing: _descargando == c.id
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : IconButton(
                                tooltip: 'Descargar PDF',
                                icon: const Icon(Icons.download_rounded),
                                onPressed: () => _descargarCertificado(c),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                    'Habilidades',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _habilidadCtrl,
                          onFieldSubmitted: (_) => _agregarHabilidad(),
                          decoration: const InputDecoration(
                            labelText: 'Agregar habilidad',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _agregarHabilidad,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _habilidades.map((h) {
                      return InputChip(
                        label: Text(h),
                        onDeleted: () => _quitarHabilidad(h),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.interests_rounded, color: scheme.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Intereses',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus categorías para recibir propuestas personalizadas.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  if (_cargandoIntereses)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _catalogoIntereses.map((i) {
                        final seleccionado = _intereses.contains(i.clave);
                        return FilterChip(
                          selected: seleccionado,
                          showCheckmark: false,
                          avatar: Text(i.emoji, style: const TextStyle(fontSize: 16)),
                          label: Text(i.label),
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            color: seleccionado ? Colors.white : scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _intereses.add(i.clave);
                            } else {
                              _intereses.remove(i.clave);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
