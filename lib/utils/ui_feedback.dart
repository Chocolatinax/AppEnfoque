import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Muestra un aviso flotante (SnackBar) con el estilo de la app.
/// Los colores salen del tema, así funciona en modo claro y oscuro.
void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_rounded,
  bool isError = false,
}) {
  final p = context.palette;
  final messenger = ScaffoldMessenger.of(context);
  // Error: fondo de error suave con texto oscuro (contraste AA en claro y oscuro)
  final backgroundColor = isError ? p.errorContainer : null;
  final foreground = isError ? p.onErrorContainer : p.inverseOnSurface;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: foreground),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(milliseconds: 2800),
    ),
  );
}

/// Aviso estándar para funciones en alcance que aún no están conectadas.
void showComingSoon(BuildContext context, [String feature = 'Esta función']) {
  showAppSnackBar(
    context,
    '$feature se conectará en una próxima etapa',
    icon: Icons.schedule_rounded,
  );
}
