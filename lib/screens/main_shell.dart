import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/session_clock.dart';
import 'active_session_screen.dart';
import '../widgets/common/app_bottom_nav.dart';
import '../widgets/task_form_screen.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'account_flow.dart';
import 'tasks_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  final ActiveSessionRecord? resumeSession;

  const MainShell({super.key, this.initialIndex = 0, this.resumeSession});

  static const int tabTareas = 0;
  static const int tabEnfoque = 1;
  static const int tabHistorial = 2;

  static const int tabNueva = -1;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    final resume = widget.resumeSession;
    if (resume == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) askAnalyticsConsentIfNeeded(context);
      });
    }
    if (resume != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final task = TaskScope.read(context)
            ?.tasks
            .where((t) => t.id == resume.taskId)
            .firstOrNull;
        if (task == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  ActiveSessionScreen(task: task, restored: resume)),
        );
      });
    }
  }

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
      // El FAB va aquí y no en TasksScreen para que suba cuando sale un snackbar
      floatingActionButton: _currentIndex == MainShell.tabTareas
          ? FloatingActionButton.extended(
              onPressed: _openNewTask,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            )
          : null,
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
