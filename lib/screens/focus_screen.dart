import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common/enfoque_app_bar.dart';
import 'main_shell.dart';

/// Pestaña "Enfoque".
/// TODO: todavía no hay diseño para esta pantalla; por ahora es un
/// marcador de posición para que la navegación funcione completa.
class FocusScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenProfile;

  const FocusScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: EnfoqueAppBar(title: 'Enfoque', onAvatarTap: onOpenProfile),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.adjust_rounded,
                      color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Modo Enfoque',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aquí irá la sesión de enfoque con temporizador y bloqueo de apps. '
                  'Esta pantalla se diseñará en el siguiente paso.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => onNavigate(MainShell.tabTareas),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Ver mis tareas',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
