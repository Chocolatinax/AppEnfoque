import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/enfoque_app_bar.dart';
import '../widgets/common/priority_chip.dart';
import '../widgets/common/task_delete.dart';
import '../widgets/task_form_screen.dart';
import 'session_launcher.dart';
import '../data/daily_phrases.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class TasksScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSettings;

  const TasksScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenSettings,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const _filters = ['Todas', 'Baja', 'Media', 'Alta'];
  String _filter = 'Todas';

  void _startSession(Task task) => launchFocusSession(context, task);

  void _editTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskFormScreen(initialTask: task)),
    );
  }

  Future<void> _deleteTask(Task task) async {
    if (!await confirmDeleteTask(context, task)) return;
    if (mounted) await deleteTaskWithUndo(context, task);
  }

  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _todayText {
    final now = DateTime.now();
    final day = _weekdays[now.weekday - 1];
    return '${day[0].toUpperCase()}${day.substring(1)}, ${now.day} de ${_months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    final repo = TaskScope.of(context);
    final name = AuthScope.of(context)?.currentUser?.firstName;
    final all = repo.tasks;
    final pendingCount = repo.pendingTasks.length;
    final next = repo.nextTask;
    final visible = _filter == 'Todas'
        ? all
        : all.where((t) => t.priority == _filter).toList();

    return Scaffold(
      appBar:
          EnfoqueAppBar(title: 'Tareas', onSettingsTap: widget.onOpenSettings),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 112),
        children: [
          Text(
            name == null ? _greeting : '$_greeting, $name',
            style: t.headlineMedium,
          ),
          const SizedBox(height: 2),
          Text(_todayText,
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.spa_outlined, size: 18, color: p.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  DailyPhrases.forDate(DateTime.now()),
                  style: t.bodyMedium!.copyWith(
                    color: p.primary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (all.isEmpty)
            _EmptyTasksCard(
                onCreate: () => widget.onNavigate(MainShell.tabNueva))
          else if (next != null)
            _NextTaskCard(task: next, onStart: () => _startSession(next))
          else
            const _AllDoneCard(),
          if (all.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Tus tareas', style: t.titleLarge)),
                Text(
                  '$pendingCount de ${all.length} pendientes',
                  style: t.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final f in _filters)
                  ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _filter == f ? p.onPrimary : p.onSurface,
                    ),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final task in visible) ...[
              _TaskTile(
                task: task,
                done: task.isDone,
                onToggle: () => repo.toggleDone(task.id),
                onStart: () => _startSession(task),
                onEdit: () => _editTask(task),
                onDelete: () => _deleteTask(task),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'No tienes tareas con prioridad ${_filter.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NextTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onStart;

  const _NextTaskCard({required this.task, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl - 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu siguiente tarea',
              style: t.labelMedium!.copyWith(color: p.primary)),
          const SizedBox(height: AppSpacing.sm),
          Text(task.title, style: t.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(task.goal,
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              PriorityChip(priority: task.priority),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.schedule, size: 16, color: p.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(task.durationLabel,
                      style: t.bodySmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar enfoque'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTasksCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.edit_note_rounded, size: 40, color: p.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Crea tu primera tarea',
              style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escribe qué quieres lograr y cuánto tiempo le dedicarás. Floria te ayuda a enfocarte en ella.',
            textAlign: TextAlign.center,
            style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear tarea'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return AppCard(
      color: p.primaryFixed,
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: p.onPrimaryFixed, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Terminaste todas tus tareas de hoy.',
              style: t.titleMedium!.copyWith(color: p.onPrimaryFixed),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TaskAction { edit, delete }

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.done,
    required this.onToggle,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Semantics(
            label: done
                ? 'Desmarcar ${task.title}'
                : 'Marcar como hecha ${task.title}',
            child: Checkbox(
              value: done,
              onChanged: (_) => onToggle(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: t.titleMedium!.copyWith(
                    color: done ? p.onSurfaceVariant : p.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PriorityChip(priority: task.priority),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                        child: Text(task.durationLabel,
                            style: t.bodySmall,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          if (!done)
            IconButton(
              onPressed: onStart,
              tooltip: 'Iniciar enfoque: ${task.title}',
              icon: Icon(Icons.play_circle_outline, color: p.primary, size: 28),
            ),
          PopupMenuButton<_TaskAction>(
            tooltip: 'Más opciones: ${task.title}',
            icon: Icon(Icons.more_vert, color: p.onSurfaceVariant),
            onSelected: (action) =>
                action == _TaskAction.edit ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _TaskAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: p.onSurface),
                    const SizedBox(width: AppSpacing.md),
                    const Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _TaskAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: p.error),
                    const SizedBox(width: AppSpacing.md),
                    Text('Eliminar', style: TextStyle(color: p.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
