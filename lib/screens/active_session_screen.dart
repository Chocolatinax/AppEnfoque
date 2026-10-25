import 'dart:async';
import 'package:flutter/material.dart';
import '../data/blockable_apps.dart';
import '../data/session_repository.dart';
import '../data/task_repository.dart';
import '../models/focus_session.dart';
import '../models/task_model.dart';
import '../services/app_blocker.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/ui_feedback.dart';
import '../widgets/common/app_card.dart';
import 'blocked_app_reminder_screen.dart';

/// Una fase de la sesión: enfoque o descanso.
class _Phase {
  final bool isFocus;
  final int minutes;
  final int round;
  const _Phase({required this.isFocus, required this.minutes, required this.round});
}

/// Sesión de enfoque en curso.
///
/// - Tiempo libre: un solo bloque de enfoque.
/// - Pomodoro: rondas de 25 min con descansos de 5 min (25 min cada 3 rondas).
///
/// No hay botón de volver: la única salida es terminar o abandonar.
/// Al terminar pregunta si se cumplió el objetivo y guarda la sesión en el historial (R2).
class ActiveSessionScreen extends StatefulWidget {
  final Task task;

  const ActiveSessionScreen({super.key, required this.task});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> with SingleTickerProviderStateMixin {
  static const int _emergencyPauseSeconds = 2 * 60;

  late final List<_Phase> _phases = _buildPhases();
  final DateTime _startedAt = DateTime.now();
  int _phaseIndex = 0;
  late int _secondsLeft = _phases.first.minutes * 60;
  int _pauseSecondsLeft = 0;
  int _focusSeconds = 0;
  bool _ended = false;
  Timer? _timer;

  // Bloqueo de apps (solo Android)
  StreamSubscription<BlockedAppEvent>? _blockedSub;
  bool _blockingActive = false;
  bool _reminderOpen = false;
  ValueNotifier<BlockedAppEvent>? _reminderEvent; // app que muestra el recordatorio abierto
  late final ValueNotifier<int> _secondsLeftNotifier = ValueNotifier(_secondsLeft);
  late final List<String> _blockedPackages = !widget.task.blockDistractions
      ? const []
      : widget.task.blockedPackages.isNotEmpty
          ? widget.task.blockedPackages
          // Tareas creadas antes de guardar paquetes: traducir los nombres del catálogo
          : BlockableApps.packagesFor(widget.task.blockedApps);

  /// Nombre visible de una app bloqueada a partir de su paquete.
  String _appNameFor(String package) {
    final index = widget.task.blockedPackages.indexOf(package);
    if (index >= 0 && index < widget.task.blockedApps.length) return widget.task.blockedApps[index];
    return BlockableApps.nameForPackage(package);
  }

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  _Phase get _phase => _phases[_phaseIndex];
  bool get _isLastPhase => _phaseIndex == _phases.length - 1;
  bool get _isPaused => _pauseSecondsLeft > 0;
  int get _focusRounds => _phases.where((ph) => ph.isFocus).length;

  List<_Phase> _buildPhases() {
    final task = widget.task;
    if (!task.isPomodoro) {
      return [_Phase(isFocus: true, minutes: task.durationMinutes, round: 1)];
    }
    final phases = <_Phase>[];
    for (var r = 1; r <= task.pomodoroRounds; r++) {
      phases.add(_Phase(isFocus: true, minutes: Pomodoro.focusMinutes, round: r));
      // Toda ronda termina con su descanso (también la última)
      phases.add(_Phase(isFocus: false, minutes: Pomodoro.breakAfterRound(r), round: r));
    }
    return phases;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _blockedSub = AppBlocker.instance.blockedAppOpened.listen(_onBlockedApp);
    _syncBlocking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accesibilidad: respetar "reducir movimiento" del sistema
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blockedSub?.cancel();
    if (_blockingActive) AppBlocker.instance.stop();
    _secondsLeftNotifier.dispose();
    _breath.dispose();
    super.dispose();
  }

  // ---------- Lógica del temporizador ----------

  void _tick() {
    if (!mounted || _ended) return;
    setState(() {
      if (_isPaused) {
        _pauseSecondsLeft--;
        if (_pauseSecondsLeft == 0) showAppSnackBar(context, 'Pausa terminada. De vuelta al enfoque.');
        return;
      }
      if (_secondsLeft > 0) {
        _secondsLeft--;
        if (_phase.isFocus) _focusSeconds++;
      }
      if (_secondsLeft == 0) _nextPhase();
    });
    _secondsLeftNotifier.value = _secondsLeft;
    _syncBlocking();
  }

  void _nextPhase() {
    if (_phaseIndex == _phases.length - 1) {
      _ended = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    _phaseIndex++;
    _secondsLeft = _phase.minutes * 60;
    showAppSnackBar(
      context,
      _phase.isFocus
          ? 'Ronda ${_phase.round}: de vuelta al enfoque'
          : '¡Bien! Toma un descanso de ${_phase.minutes} min',
      icon: _phase.isFocus ? Icons.spa_outlined : Icons.local_cafe_outlined,
    );
  }

  void _toggleEmergencyPause() {
    setState(() => _pauseSecondsLeft = _isPaused ? 0 : _emergencyPauseSeconds);
    _syncBlocking();
  }

  void _skipBreak() {
    setState(() {
      _secondsLeft = 0;
      _nextPhase();
    });
    _syncBlocking();
  }

  // ---------- Bloqueo de apps ----------

  /// Se bloquea solo durante el enfoque; en descansos, pausas y al terminar se libera.
  bool get _shouldBlock => !_ended && _phase.isFocus && !_isPaused && _blockedPackages.isNotEmpty;

  void _syncBlocking() {
    final should = _shouldBlock;
    if (should == _blockingActive) return;
    _blockingActive = should;
    if (should) {
      AppBlocker.instance.start(_blockedPackages);
    } else {
      AppBlocker.instance.stop();
      // Si empieza un descanso o termina la sesión con el recordatorio abierto, se cierra solo
      if (_reminderOpen && mounted) {
        final sessionRoute = ModalRoute.of(context);
        Navigator.of(context).popUntil((route) => route == sessionRoute);
      }
    }
  }

  /// El usuario abrió una app bloqueada: mostrar la pantalla de recordatorio (R1).
  Future<void> _onBlockedApp(BlockedAppEvent event) async {
    if (!mounted || !_blockingActive) return;

    // Si el recordatorio ya está abierto, solo se actualiza con la app nueva
    if (_reminderOpen) {
      _reminderEvent?.value = event;
      return;
    }

    _reminderOpen = true;
    final notifier = ValueNotifier(event);
    _reminderEvent = notifier;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockedAppReminderScreen(
          event: notifier,
          secondsLeft: _secondsLeftNotifier,
          appNameFor: _appNameFor,
          goal: widget.task.goal,
        ),
      ),
    );
    _reminderOpen = false;
    _reminderEvent = null;
    notifier.dispose();
  }

  // ---------- Cierre de sesión ----------

  Future<void> _record(String status, {String? goalResult}) async {
    await SessionScope.read(context)?.record(
      FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: widget.task.id,
        taskTitle: widget.task.title,
        plannedMinutes: widget.task.durationMinutes,
        focusSeconds: _focusSeconds,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        status: status,
        goalResult: goalResult,
      ),
    );
  }

  Future<void> _finish() async {
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GoalResultDialog(goal: widget.task.goal),
    );
    if (!mounted) return;

    await _record(SessionStatus.completed, goalResult: result);
    if (!mounted) return;

    // Si cumplió su objetivo, la tarea se marca como hecha
    if (result == GoalResult.yes) {
      final tasks = TaskScope.read(context);
      final saved = tasks?.tasks.where((t) => t.id == widget.task.id).firstOrNull;
      if (saved != null && !saved.isDone) await tasks!.toggleDone(saved.id);
    }
    if (!mounted) return;

    showAppSnackBar(context, 'Sesión guardada en tu historial');
    Navigator.of(context).pop();
  }

  Future<void> _confirmAbandon() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Abandonar la sesión?'),
        content: const Text('Se registrará como abandonada en tu historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir enfocado')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: p.error),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _ended = true;
    _timer?.cancel();
    _syncBlocking();
    await _record(SessionStatus.abandoned);
    if (!mounted) return;

    showAppSnackBar(context, 'Sesión registrada como abandonada', icon: Icons.close_rounded);
    Navigator.of(context).pop();
  }

  // ---------- Interfaz ----------

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _phaseLabel {
    if (!widget.task.isPomodoro) return 'Enfoque';
    if (_phase.isFocus) return 'Ronda ${_phase.round} de $_focusRounds · Enfoque';
    final kind = _phase.minutes == Pomodoro.longBreakMinutes ? 'Descanso largo' : 'Descanso corto';
    return _isLastPhase ? '$kind · Último' : kind;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final onBreak = !_phase.isFocus;
    final accent = onBreak ? p.secondary : p.primary;

    return PopScope(
      canPop: _ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showAppSnackBar(context, 'Tu sesión sigue activa. Usa la pausa o abandona la sesión.',
              icon: Icons.lock_outline);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(onBreak ? 'Descanso' : 'Sesión de enfoque'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl),
            child: Column(
              children: [
                // Fase actual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: onBreak ? p.secondaryFixed : p.primaryFixed,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _isPaused ? 'En pausa' : _phaseLabel,
                    style: t.labelMedium!.copyWith(color: onBreak ? p.onSecondaryFixedVariant : p.onPrimaryFixed),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Círculo que "respira"
                ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0)
                      .animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: onBreak ? p.secondaryFixed : p.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(onBreak ? Icons.local_cafe_outlined : Icons.spa_outlined, size: 48, color: accent),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Temporizador (el lector de pantalla lo lee en palabras)
                Semantics(
                  label: 'Quedan ${(_secondsLeft / 60).ceil()} minutos',
                  excludeSemantics: true,
                  child: Text(
                    _format(_secondsLeft),
                    style: t.displaySmall!.copyWith(
                      fontSize: 64,
                      color: _isPaused ? p.onSurfaceVariant : accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isPaused
                      ? 'Vuelves al enfoque en ${_format(_pauseSecondsLeft)}'
                      : onBreak
                          ? 'Levántate, estírate o toma agua.'
                          : 'Respira profundo y enfócate en tu objetivo.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Objetivo
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu objetivo', style: t.labelMedium!.copyWith(color: p.primary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.task.goal, style: t.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.task.title, style: t.bodySmall),
                      if (widget.task.blockDistractions && widget.task.blockedApps.isNotEmpty && !onBreak) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: p.tertiary),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Bloqueadas: ${widget.task.blockedApps.join(', ')}',
                                style: t.bodySmall!.copyWith(color: p.tertiary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Acciones
                SizedBox(
                  width: double.infinity,
                  child: onBreak
                      ? OutlinedButton.icon(
                          onPressed: _skipBreak,
                          icon: Icon(_isLastPhase ? Icons.flag_outlined : Icons.skip_next_rounded),
                          label: Text(_isLastPhase ? 'Terminar sesión' : 'Saltar descanso'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _toggleEmergencyPause,
                          icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(_isPaused
                              ? 'Reanudar ahora (${_format(_pauseSecondsLeft)})'
                              : 'Pausa de emergencia (2 min)'),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: _confirmAbandon,
                  style: TextButton.styleFrom(foregroundColor: p.error),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Abandonar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pregunta final: "¿Cumpliste tu objetivo?" (Sí / En parte / No).
class _GoalResultDialog extends StatelessWidget {
  final String goal;
  const _GoalResultDialog({required this.goal});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(Icons.emoji_events_outlined, color: p.primary, size: 36),
      title: const Text('¡Sesión completada!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Cumpliste tu objetivo?', textAlign: TextAlign.center, style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('"$goal"', textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.pop(context, GoalResult.yes),
            child: const Text('Sí, lo cumplí'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, GoalResult.partly),
            child: const Text('En parte'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.pop(context, GoalResult.no),
            child: const Text('No lo cumplí'),
          ),
        ],
      ),
    );
  }
}
