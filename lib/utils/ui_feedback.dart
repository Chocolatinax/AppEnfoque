import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_rounded,
  bool isError = false,
}) {
  final p = context.palette;
  final messenger = ScaffoldMessenger.of(context);
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
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: foreground),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(milliseconds: 2800),
    ),
  );
}
