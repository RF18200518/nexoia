import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import 'certificados_admin_screen.dart';
import 'dashboard_screen.dart';
import 'equipos_admin_screen.dart';
import 'estudiantes_admin_screen.dart';
import 'necesidades_coord_screen.dart';
import 'organizaciones_screen.dart';
import 'reportes_admin_screen.dart';
import 'validar_asistencia_screen.dart';

class CoordinadorShell extends StatefulWidget {
  const CoordinadorShell({super.key});

  @override
  State<CoordinadorShell> createState() => _CoordinadorShellState();
}

class _CoordinadorShellState extends State<CoordinadorShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  static const List<_Seccion> _secciones = [
    _Seccion('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _Seccion('Validar asistencia', Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded),
    _Seccion('Estudiantes', Icons.groups_outlined, Icons.groups_rounded),
    _Seccion('Organizaciones', Icons.apartment_outlined, Icons.apartment_rounded),
    _Seccion('Certificados', Icons.card_membership_outlined, Icons.card_membership_rounded),
    _Seccion('Equipos', Icons.people_alt_outlined, Icons.people_alt_rounded),
    _Seccion('Reportes', Icons.assessment_outlined, Icons.assessment_rounded),
    _Seccion('Necesidades', Icons.assignment_outlined, Icons.assignment_rounded),
  ];

  static const List<Widget> _paginas = [
    DashboardScreen(),
    ValidarAsistenciaScreen(),
    EstudiantesAdminScreen(),
    OrganizacionesScreen(),
    CertificadosAdminScreen(),
    EquiposAdminScreen(),
    ReportesAdminScreen(),
    NecesidadesCoordScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final actual = _secciones[_index];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(actual.titulo),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(
              context.watch<ThemeController>().isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => context.read<ThemeController>().toggle(),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _proximamente('Centro de notificaciones'),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: _paginas),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index <= 3 ? _index : 3,
              onDestinationSelected: (i) {
                if (i == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _index = i);
                }
              },
              destinations: [
                ..._secciones.take(4).map(
                      (s) => NavigationDestination(
                        icon: Icon(s.icono),
                        selectedIcon: Icon(s.iconoActivo),
                        label: s.titulo.split(' ').first,
                      ),
                    ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  selectedIcon: Icon(Icons.more_horiz_rounded),
                  label: 'Menú',
                ),
              ],
            ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _accionesRapidas(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Acciones'),
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = context.watch<ThemeController>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                        child: Icon(Icons.volunteer_activism_rounded, color: scheme.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Panel Coordinador',
                                style: TextStyle(color: scheme.onPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                            Text('NexoIA · UCN',
                                style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const _DrawerLabel('GESTIÓN'),
                  ..._secciones.take(4).toList().asMap().entries.map((e) => _drawerTile(e.key, e.value)),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  const _DrawerLabel('HERRAMIENTAS'),
                  ..._secciones.skip(4).toList().asMap().entries.map((e) => _drawerTile(e.key + 4, e.value)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(
                    theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    theme.isDark ? 'Modo oscuro' : 'Modo claro',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(value: theme.isDark, onChanged: (_) => theme.toggle()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(int i, _Seccion s) {
    final scheme = Theme.of(context).colorScheme;
    final sel = i == _index;
    return ListTile(
      leading: Icon(sel ? s.iconoActivo : s.icono, color: sel ? scheme.primary : null),
      title: Text(s.titulo, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      selected: sel,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        setState(() => _index = i);
        Navigator.pop(context);
      },
    );
  }

  void _accionesRapidas(BuildContext context) {
    final acciones = [
      _Accion(Icons.add_task_rounded, 'Nueva necesidad', 7),
      _Accion(Icons.group_add_rounded, 'Crear equipo', 5),
      _Accion(Icons.assignment_turned_in_rounded, 'Emitir certificado', 4),
      _Accion(Icons.analytics_rounded, 'Ver reportes', 6),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acciones rápidas',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...acciones.map(
                    (a) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(ctx).colorScheme.onPrimaryContainer,
                        child: Icon(a.icono),
                      ),
                      title: Text(a.label),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _index = a.index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir del panel de coordinador?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<Session>().logout();
    }
  }

  void _proximamente(String que) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Próximamente: $que')));
  }
}

class _DrawerLabel extends StatelessWidget {
  const _DrawerLabel(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Seccion {
  const _Seccion(this.titulo, this.icono, this.iconoActivo);
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
}

class _Accion {
  const _Accion(this.icono, this.label, this.index);
  final IconData icono;
  final String label;
  final int index;
}