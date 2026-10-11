import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../services/necesidad_service.dart';
import '../../services/organizacion_service.dart';

class PublicarNecesidadScreen extends StatefulWidget {
  const PublicarNecesidadScreen({super.key});

  @override
  State<PublicarNecesidadScreen> createState() => _PublicarNecesidadScreenState();
}

class _PublicarNecesidadScreenState extends State<PublicarNecesidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _necService = NecesidadService();
  final _orgService = OrganizacionService();

  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _ubicacion = TextEditingController();
  final _cupos = TextEditingController(text: '1');
  final _habilidades = TextEditingController();
  DateTime? _fecha;
  int? _duracion;

  String _naturaleza = 'Ambiental';
  String _prioridad = 'Media';
  bool _publicar = true;
  bool _enviando = false;

  static const _naturalezas = [
    'Ambiental',
    'Social',
    'Educación',
    'Tecnología',
    'Salud',
    'Animales',
    'Deportes',
    'Cultural',
  ];
  static const _prioridades = ['Alta', 'Media', 'Baja'];

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _ubicacion.dispose();
    _cupos.dispose();
    _habilidades.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      final org = await _orgService.mia();
      final habilidades = _habilidades.text
          .split(',')
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList();

      await _necService.crear({
        'organizacion_id': org.id,
        'titulo': _titulo.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'naturaleza': _naturaleza,
        'prioridad': _prioridad,
        'cupos': int.tryParse(_cupos.text.trim()) ?? 1,
        'ubicacion': _ubicacion.text.trim(),
        'habilidades_requeridas': habilidades,
        'estado': _publicar ? 'publicada' : 'borrador',
        'fecha': _fecha?.toIso8601String(),
        'duracion': _duracion,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _publicar ? 'Necesidad publicada' : 'Necesidad guardada como borrador',
          ),
        ),
      );
      _titulo.clear();
      _descripcion.clear();
      _ubicacion.clear();
      _habilidades.clear();
      _cupos.text = '1';
      setState(() {
        _fecha = null;
        _duracion = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'Nueva necesidad',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Describe la actividad que necesitas y publica para recibir voluntarios.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titulo,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Título',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descripcion,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _naturaleza,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _naturalezas
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _naturaleza = v ?? _naturaleza),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _prioridad,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: _prioridades
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _prioridad = v ?? _prioridad),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cupos,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cupos'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1) return 'Nº inválido';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: Icon(_fecha != null ? Icons.event_rounded : Icons.calendar_today_outlined),
                  label: Text(
                    _fecha != null
                        ? DateFormat('d MMM yyyy', 'es').format(_fecha!)
                        : 'Fecha (opcional)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duración (horas)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  onChanged: (v) => setState(() => _duracion = int.tryParse(v.trim())),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Nº inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _ubicacion,
            decoration: const InputDecoration(
              labelText: 'Ubicación',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _habilidades,
            decoration: const InputDecoration(
              labelText: 'Habilidades requeridas',
              hintText: 'programación, docencia',
              prefixIcon: Icon(Icons.checklist_rounded),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Publicar ahora'),
            subtitle: const Text('Si lo desactivas, queda como borrador'),
            value: _publicar,
            onChanged: (v) => setState(() => _publicar = v),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_publicar ? 'Publicar necesidad' : 'Guardar borrador'),
          ),
        ],
      ),
    );
  }
}
