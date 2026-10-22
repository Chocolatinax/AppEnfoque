import 'package:flutter/material.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/task_form_screen.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

/// Contenedor principal después de la bienvenida.
/// Mantiene la barra inferior fija y cambia entre las 3 pestañas
/// (Tareas, Enfoque, Historial). "Nueva tarea" se abre como pantalla aparte.
/// Se usa IndexedStack para que cada pestaña conserve su estado
/// (por ejemplo, el temporizador Pomodoro sigue corriendo al cambiar de pestaña).
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  /// Índices de las pestañas, para no usar "números mágicos".
  static const int tabTareas = 0;
  static const int tabEnfoque = 1;
  static const int tabHistorial = 2;

  /// No es una pestaña: pedir este índice abre el formulario "Nueva tarea".
  static const int tabNueva = -1;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;

  void _goToTab(int index) {
    if (index == MainShell.tabNueva) {
      _openNewTask();
      return;
    }
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _openNewTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TaskFormScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TasksScreen(onNavigate: _goToTab, onOpenSettings: _openSettings),
          FocusScreen(onNavigate: _goToTab, onOpenSettings: _openSettings),
          HistoryScreen(onOpenSettings: _openSettings),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}
