import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../data/blockable_apps.dart';
import '../screens/app_picker_screen.dart';
import '../services/app_blocker.dart';
import 'common/task_delete.dart';
import '../screens/session_launcher.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/form_validators.dart';
import '../utils/plural.dart';
import '../utils/ui_feedback.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? initialTask;

  const TaskFormScreen({super.key, this.initialTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController(text: '25');

  static const _presetMinutes = [15, 25, 45, 60, 90];

  String _timerMode = TimerMode.free;
  int _rounds = 4;
  String _priority = 'Media';
  bool _blockDistractions = true;
  String? _appsError;

  List<InstalledApp> _availableApps = [];
  final Set<String> _selectedPackages = {};
  bool _appsLoaded = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task != null) {
      _titleController.text = task.title;
      _goalController.text = task.goal;
      _timerMode = task.timerMode;
      _priority = task.priority;
      _blockDistractions = task.blockDistractions;
      if (task.isPomodoro) {
        _rounds =
            task.pomodoroRounds.clamp(Pomodoro.minRounds, Pomodoro.maxRounds);
      } else {
        _durationController.text = '${task.durationMinutes}';
      }
    }
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await AppBlocker.instance.getLaunchableApps();
    if (!mounted) return;

    final Iterable<String> initial;
    final task = widget.initialTask;
    if (task != null) {
      final saved = task.blockedPackages.isNotEmpty
          ? task.blockedPackages.toSet()
          : BlockableApps.packagesFor(task.blockedApps).toSet();
      initial = apps
          .where((a) => saved.contains(a.packageName))
          .map((a) => a.packageName);
    } else if (AppBlocker.instance.isSupported) {
      initial = apps.where((a) => a.isRecommended).map((a) => a.packageName);
    } else {
      initial = apps
          .where((a) => BlockableApps.defaultSelection.contains(a.name))
          .map((a) => a.packageName);
    }

    setState(() {
      _availableApps = apps;
      _selectedPackages
        ..clear()
        ..addAll(initial);
      _appsLoaded = true;
    });
  }

  Future<void> _delete() async {
    final task = widget.initialTask;
    if (task == null || !await confirmDeleteTask(context, task)) return;
    if (!mounted) return;
    await deleteTaskWithUndo(context, task);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openAppPicker() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => AppPickerScreen(
            apps: _availableApps, initialSelection: _selectedPackages),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedPackages
        ..clear()
        ..addAll(result);
      _appsError = null;
    });
  }

  List<InstalledApp> get _chosenApps => _availableApps
      .where((a) => _selectedPackages.contains(a.packageName))
      .toList();

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool get _isPomodoro => _timerMode == TimerMode.pomodoro;

  List<String> get _selectedApps => _chosenApps.map((a) => a.name).toList();

  int get _pomodoroFocusMinutes => _rounds * Pomodoro.focusMinutes;

  int get _pomodoroBreakMinutes {
    var total = 0;
    for (var r = 1; r <= _rounds; r++) {
      total += Pomodoro.breakAfterRound(r);
    }
    return total;
  }

  void _showPomodoroInfo() {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    const steps = [
      (
        Icons.check_circle_outline,
        'Elige una tarea',
        'Una sola actividad en la que te vas a enfocar.'
      ),
      (
        Icons.timer_outlined,
        'Trabaja 25 minutos',
        'Concéntrate solo en esa tarea. Floria bloquea tus distracciones.'
      ),
      (
        Icons.local_cafe_outlined,
        'Descansa 5 minutos',
        'Haz una pausa corta: levántate, estírate o toma agua.'
      ),
      (
        Icons.repeat_rounded,
        'Repite el ciclo',
        'Cada bloque de 25 minutos con su descanso es una ronda.'
      ),
      (
        Icons.self_improvement_outlined,
        'Toma un descanso largo',
        'Después de la 4.ª ronda descansa 25 minutos para recargar energía.'
      ),
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Cómo funciona Pomodoro?', style: t.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: MergeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: p.primaryFixed,
                          child: Text('${i + 1}',
                              style: t.labelMedium!
                                  .copyWith(color: p.onPrimaryFixed)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.$2, style: t.titleMedium),
                              Text(step.$3,
                                  style: t.bodyMedium!
                                      .copyWith(color: p.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit({required bool startNow}) async {
    final isFormValid = _formKey.currentState!.validate();

    final appsError = FormValidators.validateBlockedApps(
      isBlockingEnabled: _blockDistractions,
      apps: _selectedApps,
    );
    setState(() => _appsError = appsError);

    if (!isFormValid || appsError != null) {
      showAppSnackBar(
        context,
        'Revisa los campos marcados antes de guardar.',
        icon: Icons.error_outline,
        isError: true,
      );
      return;
    }

    final original = widget.initialTask;
    final task = Task(
      id: original?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: original?.createdAt,
      isDone: original?.isDone ?? false,
      title: _titleController.text.trim(),
      goal: _goalController.text.trim(),
      durationMinutes: _isPomodoro
          ? _pomodoroFocusMinutes
          : int.parse(_durationController.text.trim()),
      priority: _priority,
      timerMode: _timerMode,
      pomodoroRounds: _isPomodoro ? _rounds : 0,
      blockDistractions: _blockDistractions,
      blockedApps: _blockDistractions ? _selectedApps : const [],
      blockedPackages: _blockDistractions
          ? _chosenApps.map((a) => a.packageName).toList()
          : const [],
    );

    final repo = TaskScope.read(context);
    if (_isEditing) {
      await repo?.update(task);
    } else {
      await repo?.add(task);
    }
    if (!mounted) return;

    if (startNow) {
      final started = await launchFocusSession(context, task, replace: true);
      if (!started && mounted) {
        showAppSnackBar(context, 'Tarea guardada en tu lista');
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    } else {
      showAppSnackBar(context,
          _isEditing ? 'Cambios guardados' : 'Tarea guardada en tu lista');
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar tarea' : 'Nueva tarea')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('¿Qué vas a hacer?'),
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  hintText: 'Ej. Estudiar para el parcial de Cálculo',
                ),
                validator: FormValidators.validateTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _goalController,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '¿Qué quieres lograr exactamente?',
                  hintText: 'Ej. Resolver 5 ejercicios de integrales',
                  alignLabelWithHint: true,
                ),
                validator: FormValidators.validateGoal,
              ),
              const _SectionTitle('¿Cómo quieres medir el tiempo?'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: TimerMode.free,
                      label: Text('Tiempo libre'),
                      icon: Icon(Icons.timer_outlined)),
                  ButtonSegment(
                      value: TimerMode.pomodoro,
                      label: Text('Pomodoro'),
                      icon: Icon(Icons.av_timer)),
                ],
                selected: {_timerMode},
                onSelectionChanged: (s) => setState(() => _timerMode = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isPomodoro)
                _buildPomodoroOptions(p, t)
              else
                _buildFreeTimeOptions(p),
              const _SectionTitle('Prioridad'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Baja', label: Text('Baja')),
                  ButtonSegment(value: 'Media', label: Text('Media')),
                  ButtonSegment(value: 'Alta', label: Text('Alta')),
                ],
                selected: {_priority},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const _SectionTitle('Distracciones'),
              _buildBlockingCard(p, t),
              const SizedBox(height: AppSpacing.xxl),
              if (_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _submit(startNow: false),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: p.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar tarea'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _submit(startNow: true),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Guardar e iniciar enfoque'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _submit(startNow: false),
                    child: const Text('Solo guardar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeTimeOptions(AppPalette p) {
    final current = int.tryParse(_durationController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final m in _presetMinutes)
              ChoiceChip(
                label: Text('$m min'),
                selected: current == m,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: current == m ? p.onPrimary : p.onSurface,
                ),
                onSelected: (_) =>
                    setState(() => _durationController.text = '$m'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'O escribe los minutos',
            suffixText: 'min',
            helperText: 'Entre 5 y 180 minutos',
          ),
          validator: FormValidators.validateDuration,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPomodoroOptions(AppPalette p, TextTheme t) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Rondas', style: t.titleMedium)),
              TextButton.icon(
                onPressed: _showPomodoroInfo,
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('¿Cómo funciona?'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Spacer(),
              IconButton.outlined(
                tooltip: 'Quitar una ronda',
                onPressed: _rounds > Pomodoro.minRounds
                    ? () => setState(() => _rounds--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Semantics(
                label: plural(_rounds, 'ronda', 'rondas'),
                excludeSemantics: true,
                child: SizedBox(
                  width: 44,
                  child: Text('$_rounds',
                      textAlign: TextAlign.center, style: t.headlineSmall),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Agregar una ronda',
                onPressed: _rounds < Pomodoro.maxRounds
                    ? () => setState(() => _rounds++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cada ronda: ${Pomodoro.focusMinutes} min de enfoque + ${Pomodoro.shortBreakMinutes} min de descanso. '
            'Después de la ${Pomodoro.longBreakEvery}.ª ronda, el descanso es de ${Pomodoro.longBreakMinutes} min.',
            style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total: $_pomodoroFocusMinutes min de enfoque + $_pomodoroBreakMinutes min de descanso',
            style: t.titleSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockingCard(AppPalette p, TextTheme t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: _appsError != null ? p.error : p.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _blockDistractions,
            onChanged: (v) => setState(() {
              _blockDistractions = v;
              if (!v) _appsError = null;
            }),
            title: const Text('Bloquear apps durante la sesión',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle:
                const Text('Si intentas abrirlas, Floria te lo recordará.'),
          ),
          if (_blockDistractions) ...[
            const Divider(),
            ListTile(
              enabled: _appsLoaded,
              onTap: _openAppPicker,
              leading: Icon(Icons.apps_rounded, color: p.primary),
              title: Text(
                !_appsLoaded
                    ? 'Cargando tus apps…'
                    : _selectedApps.isEmpty
                        ? 'Ninguna app elegida'
                        : '${_selectedApps.length} ${_selectedApps.length == 1 ? 'app elegida' : 'apps elegidas'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: _selectedApps.isEmpty
                  ? const Text('Toca para elegir qué apps bloquear')
                  : Text(_selectedApps.join(', '),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
          if (_appsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: p.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(_appsError!,
                          style: t.bodyMedium!.copyWith(color: p.error))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
