import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';
import '../screens/active_session_screen.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/form_validators.dart';
import '../utils/ui_feedback.dart';

/// Formulario "Nueva tarea".
///
/// Sigue la especificación de la entrega del formulario (docs/especificacion-formulario.md):
/// `Form` + `GlobalKey<FormState>` + `TextFormField` con `validator`, y la regla de
/// "al menos una app bloqueada". Se simplificó la interfaz para que no abrume:
/// solo lo necesario para la tarea principal (título, objetivo, tiempo, prioridad y bloqueo).
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

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

  final List<BlockedAppItem> _apps = [
    BlockedAppItem(name: 'Instagram', packageName: 'com.instagram.android', isBlocked: true),
    BlockedAppItem(name: 'TikTok', packageName: 'com.zhiliaoapp.musically', isBlocked: true),
    BlockedAppItem(name: 'YouTube', packageName: 'com.google.android.youtube', isBlocked: true),
    BlockedAppItem(name: 'X (Twitter)', packageName: 'com.twitter.android'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool get _isPomodoro => _timerMode == TimerMode.pomodoro;

  List<String> get _selectedApps => _apps.where((a) => a.isBlocked).map((a) => a.name).toList();

  int get _pomodoroFocusMinutes => _rounds * Pomodoro.focusMinutes;

  /// Minutos de descanso: cada ronda (incluida la última) termina con su descanso.
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
      (Icons.check_circle_outline, 'Elige una tarea', 'Una sola actividad en la que te vas a enfocar.'),
      (Icons.timer_outlined, 'Trabaja 25 minutos', 'Concéntrate solo en esa tarea. Floria bloquea tus distracciones.'),
      (Icons.local_cafe_outlined, 'Descansa 5 minutos', 'Haz una pausa corta: levántate, estírate o toma agua.'),
      (Icons.repeat_rounded, 'Repite el ciclo', 'Cada bloque de 25 minutos con su descanso es una ronda.'),
      (Icons.self_improvement_outlined, 'Toma un descanso largo', 'Después de la 4.ª ronda descansa 25 minutos para recargar energía.'),
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
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
                          child: Text('${i + 1}', style: t.labelMedium!.copyWith(color: p.onPrimaryFixed)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.$2, style: t.titleMedium),
                              Text(step.$3, style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit({required bool startNow}) async {
    // 1. Validar los TextFormField con la GlobalKey del Form
    final isFormValid = _formKey.currentState!.validate();

    // 2. Validar la regla de apps bloqueadas
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

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      goal: _goalController.text.trim(),
      durationMinutes: _isPomodoro ? _pomodoroFocusMinutes : int.parse(_durationController.text.trim()),
      priority: _priority,
      timerMode: _timerMode,
      pomodoroRounds: _isPomodoro ? _rounds : 0,
      blockDistractions: _blockDistractions,
      blockedApps: _blockDistractions ? _selectedApps : const [],
    );

    // 3. Guardar en SQLite
    await TaskScope.read(context)?.add(task);
    if (!mounted) return;

    if (startNow) {
      // La sesión reemplaza al formulario: al terminar se vuelve a Tareas
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ActiveSessionScreen(task: task)),
      );
    } else {
      showAppSnackBar(context, 'Tarea guardada en tu lista');
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- 1. ¿Qué vas a hacer? ----------
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

            // ---------- 2. Tiempo ----------
            const _SectionTitle('¿Cómo quieres medir el tiempo?'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: TimerMode.free, label: Text('Tiempo libre'), icon: Icon(Icons.timer_outlined)),
                ButtonSegment(value: TimerMode.pomodoro, label: Text('Pomodoro'), icon: Icon(Icons.av_timer)),
              ],
              selected: {_timerMode},
              onSelectionChanged: (s) => setState(() => _timerMode = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isPomodoro) _buildPomodoroOptions(p, t) else _buildFreeTimeOptions(p),

            // ---------- 3. Prioridad ----------
            const _SectionTitle('Prioridad'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Alta', label: Text('Alta')),
                ButtonSegment(value: 'Media', label: Text('Media')),
                ButtonSegment(value: 'Baja', label: Text('Baja')),
              ],
              selected: {_priority},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),

            // ---------- 4. Bloqueo ----------
            const _SectionTitle('Distracciones'),
            _buildBlockingCard(p, t),

            // ---------- Acciones ----------
            const SizedBox(height: AppSpacing.xxl),
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
                onSelected: (_) => setState(() => _durationController.text = '$m'),
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
                onPressed: _rounds > Pomodoro.minRounds ? () => setState(() => _rounds--) : null,
                icon: const Icon(Icons.remove),
              ),
              Semantics(
                label: '$_rounds rondas',
                excludeSemantics: true,
                child: SizedBox(
                  width: 44,
                  child: Text('$_rounds', textAlign: TextAlign.center, style: t.headlineSmall),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Agregar una ronda',
                onPressed: _rounds < Pomodoro.maxRounds ? () => setState(() => _rounds++) : null,
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
        border: Border.all(color: _appsError != null ? p.error : p.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _blockDistractions,
            onChanged: (v) => setState(() {
              _blockDistractions = v;
              if (!v) _appsError = null;
            }),
            title: const Text('Bloquear apps durante la sesión', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Si intentas abrirlas, Floria te lo recordará.'),
          ),
          if (_blockDistractions) ...[
            const Divider(),
            for (final app in _apps)
              CheckboxListTile(
                value: app.isBlocked,
                title: Text(app.name),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() {
                  app.isBlocked = v ?? false;
                  _appsError = null;
                }),
              ),
          ],
          if (_appsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: p.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_appsError!, style: t.bodyMedium!.copyWith(color: p.error))),
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
