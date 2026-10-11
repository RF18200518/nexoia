import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/coordinador/coordinador_shell.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/organizacion/organizacion_shell.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const NexoIaApp());
}

class NexoIaApp extends StatelessWidget {
  const NexoIaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Session()..inicializar(),
      child: MaterialApp(
        title: 'NexoIA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    if (!session.listo) return const SplashScreen();
    if (!session.autenticado) return const LoginScreen();
    if (session.usuario?.rol == 'coordinador') return const CoordinadorShell();
    if (session.usuario?.rol == 'organizacion') return const OrganizacionShell();
    return const HomeShell();
  }
}
