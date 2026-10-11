import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/simulacion.dart';
import '../services/simulacion_service.dart';
import '../widgets/logo_ucn.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _sim = SimulacionService();

  String _rol = 'estudiante';
  String? _error;
  List<Interes> _catalogo = const [];
  final Set<String> _intereses = {};
  bool _cargandoCatalogo = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final lista = await _sim.intereses();
      if (mounted) {
        setState(() {
          _catalogo = lista;
          _cargandoCatalogo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoCatalogo = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rol == 'estudiante' && _intereses.isEmpty) {
      setState(() => _error =
          'Elegí al menos una categoría para que te lleguen propuestas.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      await context.read<Session>().registrar(
            nombre: _nombre.text.trim(),
            correo: _correo.text.trim(),
            contrasena: _pass.text,
            rol: _rol,
            intereses: _intereses.toList(),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar con el servidor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cargando = context.watch<Session>().cargando;
    final esEstudiante = _rol == 'estudiante';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.softGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecera(scheme),
                    const SizedBox(height: 20),
                    _tarjetaFormulario(scheme, cargando, esEstudiante),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecera(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          const LogoUcn(height: 34),
        ],
      ),
    );
  }

  Widget _tarjetaFormulario(
      ColorScheme scheme, bool cargando, bool esEstudiante) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: -12,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crea tu cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Únete a la red de voluntariado de la UCN',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
                if (!v.trim().toLowerCase().endsWith('@gmail.com')) {
                  return 'Debe ser un correo @gmail.com';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 14),
            DropdownMenu<String>(
              initialSelection: _rol,
              expandedInsets: EdgeInsets.zero,
              label: const Text('Tipo de cuenta'),
              leadingIcon: const Icon(Icons.badge_outlined),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'estudiante', label: 'Estudiante'),
                DropdownMenuEntry(value: 'organizacion', label: 'Organización'),
                DropdownMenuEntry(value: 'coordinador', label: 'Coordinador'),
              ],
              onSelected: (v) => setState(() => _rol = v ?? 'estudiante'),
            ),
            if (esEstudiante) ...[
              const SizedBox(height: 24),
              _selectorIntereses(scheme),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: scheme.onErrorContainer, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: cargando ? null : _crear,
              child: cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorIntereses(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.interests_rounded, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '¿En qué te gustaría participar?',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Con esto te llegarán propuestas hechas para ti.',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_cargandoCatalogo)
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
            children: _catalogo.map((i) {
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
    );
  }
}
