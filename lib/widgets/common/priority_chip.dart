import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, icon) = switch (priority) {
      'Alta' => (
          p.tertiaryFixed,
          p.onTertiaryFixed,
          Icons.keyboard_double_arrow_up
        ),
      'Media' => (
          p.secondaryFixed,
          p.onSecondaryFixedVariant,
          Icons.drag_handle
        ),
      _ => (
          p.surfaceContainerHigh,
          p.onSurfaceVariant,
          Icons.keyboard_arrow_down
        ),
    };

    return Semantics(
      label: 'Prioridad ${priority.toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 3),
            Text(
              priority,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
