import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/task_form_screen.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';

/// Contenedor principal después de la bienvenida.
/// Mantiene la barra inferior fija y cambia entre las 4 pestañas.
/// Se usa IndexedStack para que cada pestaña conserve su estado
/// (por ejemplo, el temporizador Pomodoro sigue corriendo al cambiar de pestaña).
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  /// Índices de las pestañas, para no usar "números mágicos".
  static const int tabTareas = 0;
  static const int tabNueva = 1;
  static const int tabEnfoque = 2;
  static const int tabHistorial = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TasksScreen(onNavigate: _goToTab, onOpenProfile: _openProfile),
          TaskFormScreen(showBottomNav: false, onOpenProfile: _openProfile),
          FocusScreen(onNavigate: _goToTab, onOpenProfile: _openProfile),
          HistoryScreen(onOpenProfile: _openProfile),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}
