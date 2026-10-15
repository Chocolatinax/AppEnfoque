import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Muestra un aviso flotante (SnackBar) con el estilo de la app.
/// Se usa en los botones que todavía no tienen funcionalidad real.
void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_rounded,
  Color? backgroundColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: AppColors.primaryFixedDim, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? AppColors.inverseSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 2400),
    ),
  );
}

/// Aviso estándar para acciones que se implementarán más adelante.
void showComingSoon(BuildContext context, [String feature = 'Esta función']) {
  showAppSnackBar(
    context,
    '$feature estará disponible próximamente',
    icon: Icons.schedule_rounded,
  );
}
