import 'package:flutter/material.dart';

/// Barra de navegación inferior de Floria (3 pestañas).
///
/// Usa el `NavigationBar` de Material 3, que ya cumple con áreas táctiles
/// de 48 dp, etiquetas visibles y lectura correcta en TalkBack / VoiceOver.
/// Sus colores vienen del tema (claro u oscuro).
///
/// Índices: 0 = Tareas, 1 = Enfoque, 2 = Historial.
/// "Nueva tarea" ya no es pestaña: se abre con el botón "+" de Tareas.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: 'Tareas',
        ),
        NavigationDestination(
          icon: Icon(Icons.adjust_outlined),
          selectedIcon: Icon(Icons.adjust),
          label: 'Enfoque',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Historial',
        ),
      ],
    );
  }
}
