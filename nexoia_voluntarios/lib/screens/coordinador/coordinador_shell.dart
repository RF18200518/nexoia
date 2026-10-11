import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import 'certificados_admin_screen.dart';
import 'dashboard_screen.dart';
import 'equipos_admin_screen.dart';
import 'estudiantes_admin_screen.dart';
import 'organizaciones_screen.dart';
import 'necesidades_coord_screen.dart';
import 'reportes_admin_screen.dart';
import 'validar_asistencia_screen.dart';

class CoordinadorShell extends StatefulWidget {
  const CoordinadorShell({super.key});

  @override
  State<CoordinadorShell> createState() => _CoordinadorShellState();
}

class _CoordinadorShellState extends State<CoordinadorShell> {
  int _index = 0;

  static const _secciones = [
    _Seccion('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _Seccion('Validar asistencia', Icons.qr_code_scanner_outlined,
        Icons.qr_code_scanner_rounded),
    _Seccion('Estudiantes', Icons.groups_outlined, Icons.groups_rounded),
    _Seccion('Certificados', Icons.card_membership_outlined,
        Icons.card_membership_rounded),
    _Seccion('Equipos', Icons.people_alt_rounded, Icons.people_alt_rounded),
    _Seccion('Reportes', Icons.assessment_outlined, Icons.assessment_rounded),
    _Seccion('Organizaciones', Icons.apartment_outlined,
        Icons.apartment_rounded),
    _Seccion('Necesidades', Icons.assignment_outlined,
        Icons.assignment_rounded),
  ];

  static const _pages = [
    DashboardScreen(),
    ValidarAsistenciaScreen(),
    EstudiantesAdminScreen(),
    CertificadosAdminScreen(),
    EquiposAdminScreen(),
    ReportesAdminScreen(),
    OrganizacionesScreen(),
    NecesidadesCoordScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final actual = _secciones[_index];
    return Scaffold(
      appBar: AppBar(title: Text(actual.titulo)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const _DrawerHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: _secciones.length,
                  itemBuilder: (context, i) {
                    final s = _secciones[i];
                    return ListTile(
                      leading: Icon(i == _index ? s.iconoActivo : s.icono),
                      title: Text(s.titulo),
                      selected: i == _index,
                      onTap: () {
                        setState(() => _index = i);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Cerrar sesión'),
                onTap: () => context.read<Session>().logout(),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

class _Seccion {
  const _Seccion(this.titulo, this.icono, this.iconoActivo);

  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      color: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.volunteer_activism_rounded,
              color: scheme.onPrimary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Panel Coordinador',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NexoIA · UCN',
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
