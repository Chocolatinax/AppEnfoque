import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/enfoque_app_bar.dart';
import '../widgets/common/priority_chip.dart';
import 'active_session_screen.dart';
import 'main_shell.dart';

/// Pestaña "Enfoque": elegir una tarea pendiente y empezar la sesión.
///
/// Muestra cuánto llevas enfocado hoy y la lista de tareas pendientes,
/// cada una con su botón para iniciar (2 toques desde la barra inferior).
class FocusScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSettings;

  const FocusScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenSettings,
  });

  void _start(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActiveSessionScreen(task: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final pending = TaskScope.of(context).pendingTasks;

    // Resumen de hoy desde el historial
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySessions = SessionScope.of(context).between(today, today.add(const Duration(days: 1)));
    final todayMinutes = todaySessions.fold<int>(0, (sum, s) => sum + s.focusSeconds) ~/ 60;
    final todayCompleted = todaySessions.where((s) => s.isCompleted).length;

    return Scaffold(
      appBar: EnfoqueAppBar(title: 'Enfoque', onSettingsTap: onOpenSettings),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
        children: [
          // Resumen del día
          AppCard(
            color: p.primaryFixed,
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.spa_outlined, color: p.onPrimaryFixed, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoy', style: t.labelMedium!.copyWith(color: p.onPrimaryFixed)),
                        Text(
                          todayMinutes == 0 ? 'Aún no empiezas' : '$todayMinutes min de enfoque',
                          style: t.titleLarge!.copyWith(color: p.onPrimaryFixed),
                        ),
                        if (todaySessions.isNotEmpty)
                          Text(
                            '$todayCompleted ${todayCompleted == 1 ? 'sesión completada' : 'sesiones completadas'}',
                            style: t.bodyMedium!.copyWith(color: p.onPrimaryFixed),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Semantics(header: true, child: Text('¿En qué te vas a enfocar?', style: t.titleLarge)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Elige una tarea. Mientras dure la sesión, tus apps distractoras estarán bloqueadas.',
            style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (pending.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Text('No tienes tareas pendientes', style: t.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Crea una tarea para empezar una sesión de enfoque.',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => onNavigate(MainShell.tabNueva),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear tarea'),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final task in pending) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(task.goal, style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        PriorityChip(priority: task.priority),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(task.durationLabel, style: t.bodySmall)),
                        FilledButton.tonalIcon(
                          onPressed: () => _start(context, task),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.primaryFixed,
                            foregroundColor: p.onPrimaryFixed,
                            minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Iniciar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
