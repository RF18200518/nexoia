import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import 'mis_necesidades_screen.dart';
import 'publicar_necesidad_screen.dart';

class OrganizacionShell extends StatefulWidget {
  const OrganizacionShell({super.key});

  @override
  State<OrganizacionShell> createState() => _OrganizacionShellState();
}

class _OrganizacionShellState extends State<OrganizacionShell> {
  int _index = 0;

  static const _pages = [
    MisNecesidadesScreen(),
    PublicarNecesidadScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Organización'),
        actions: [
          IconButton(
            tooltip: themeController.isDark ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(themeController.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => themeController.toggle(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<Session>().logout(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Mis necesidades',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Publicar',
          ),
        ],
      ),
    );
  }
}