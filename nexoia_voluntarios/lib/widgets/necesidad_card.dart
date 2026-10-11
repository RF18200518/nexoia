import 'package:flutter/material.dart';

import '../models/necesidad.dart';
import 'badges.dart';
import 'soft_card.dart';

class NecesidadCard extends StatelessWidget {
  const NecesidadCard({
    super.key,
    required this.necesidad,
    required this.onTap,
    this.nueva = false,
  });

  final Necesidad necesidad;
  final VoidCallback onTap;
  final bool nueva;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _icono(scheme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (nueva) ...[
                            _NuevaPill(),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              necesidad.titulo,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (necesidad.naturaleza != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          necesidad.naturaleza!,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ],
            ),
            if (necesidad.descripcion != null) ...[
              const SizedBox(height: 12),
              Text(
                necesidad.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (necesidad.compatibilidad > 0)
                  _MatchChip(porcentaje: necesidad.compatibilidad),
                if (necesidad.ubicacion != null)
                  TagChip(label: necesidad.ubicacion!, icon: Icons.place_outlined),
                TagChip(label: '${necesidad.cupos} cupos', icon: Icons.groups_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icono(ColorScheme scheme) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_iconoNaturaleza(necesidad.naturaleza), color: Colors.white, size: 24),
    );
  }

  IconData _iconoNaturaleza(String? n) {
    switch ((n ?? '').toLowerCase()) {
      case 'ambiental':
        return Icons.eco_rounded;
      case 'social':
        return Icons.favorite_rounded;
      case 'tecnología':
      case 'tecnologia':
        return Icons.computer_rounded;
      case 'educación':
      case 'educacion':
        return Icons.school_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({required this.porcentaje});

  final int porcentaje;

  Color get _color {
    if (porcentaje >= 85) return const Color(0xFF1B9E77);
    if (porcentaje >= 60) return const Color(0xFFE08A00);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: _color),
          const SizedBox(width: 6),
          Text(
            '$porcentaje% match',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NuevaPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B9E77), Color(0xFF0E7C66)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'NUEVA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
