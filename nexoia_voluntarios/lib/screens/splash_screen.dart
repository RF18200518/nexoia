import 'package:flutter/material.dart';

import '../widgets/logo_ucn.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    spreadRadius: -10,
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const LogoUcn(height: 90),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'NexoIA',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Voluntariado con propósito',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
