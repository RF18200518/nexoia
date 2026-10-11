import 'package:flutter/material.dart';

Color colorEstado(String estado) {
  switch (estado) {
    case 'validado':
    case 'publicada':
    case 'aprobada':
    case 'finalizada':
      return const Color(0xFF1B9E77);
    case 'aceptado':
    case 'en_curso':
      return const Color(0xFF2F6FED);
    case 'sugerido':
    case 'borrador':
    case 'pendiente':
      return const Color(0xFFE08A00);
    case 'rechazado':
    case 'cancelada':
      return const Color(0xFFD64545);
    default:
      return const Color(0xFF6B7280);
  }
}

class EstadoBadge extends StatelessWidget {
  const EstadoBadge({super.key, required this.estado, this.icon});

  final String estado;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    final texto = estado.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            texto[0].toUpperCase() + texto.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: scheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
