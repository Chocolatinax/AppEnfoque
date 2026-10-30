import 'dart:async';
import 'package:flutter/material.dart';
import '../data/blockable_apps.dart';
import '../data/session_repository.dart';
import '../data/task_repository.dart';
import '../models/focus_session.dart';
import '../models/session_clock.dart';
import '../models/task_model.dart';
import '../services/app_blocker.dart';
import '../services/notification_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/ui_feedback.dart';
import '../widgets/common/app_card.dart';
import '../services/analytics_service.dart';
import 'blocked_app_reminder_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final Task task;

  final ActiveSessionRecord? restored;

  const ActiveSessionScreen({super.key, required this.task, this.restored});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final String _sessionId = widget.restored?.sessionId ??
      DateTime.now().millisecondsSinceEpoch.toString();

  late final SessionClock _clock = SessionClock(
    phases: SessionClock.phasesFor(widget.task),
    startedAt: widget.restored?.startedAt ?? DateTime.now(),
    pausedSeconds: widget.restored?.pausedSeconds ?? 0,
    pauseStartedAt: widget.restored?.pauseStartedAt,
    skippedSeconds: widget.restored?.skippedSeconds ?? 0,
  );

  DateTime _now = DateTime.now();
  late SessionPosition _position = _clock.position(_now);
  late int _lastPhaseIndex = _position.index;
  bool _ended = false;
  Timer? _timer;

  StreamSubscription<BlockedAppEvent>? _blockedSub;
  bool _blockingActive = false;
  bool _reminderOpen = false;
  ValueNotifier<BlockedAppEvent>? _reminderEvent;
  late final ValueNotifier<int> _secondsLeftNotifier =
      ValueNotifier(_secondsLeft);
  late final List<String> _blockedPackages = !widget.task.blockDistractions
      ? const []
      : widget.task.blockedPackages.isNotEmpty
          ? widget.task.blockedPackages
          : BlockableApps.packagesFor(widget.task.blockedApps);

  String _appNameFor(String package) {
    final index = widget.task.blockedPackages.indexOf(package);
    if (index >= 0 && index < widget.task.blockedApps.length) {
      return widget.task.blockedApps[index];
    }
    return BlockableApps.nameForPackage(package);
  }

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  List<SessionPhase> get _phases => _clock.phases;
  SessionPhase get _phase => _phases[_position.index];
  int get _secondsLeft => _position.secondsLeft;
  bool get _isLastPhase => _position.index == _phases.length - 1;
  bool get _isPaused => _clock.isPaused(_now);
  int get _pauseSecondsLeft => _clock.pauseSecondsLeft(_now);
  int get _focusRounds => _phases.where((ph) => ph.isFocus).length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _blockedSub = AppBlocker.instance.blockedAppOpened.listen(_onBlockedApp);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _persist();
      NotificationService.instance.showSessionInProgress(
        widget.task,
        _clock.endsAt(DateTime.now()),
        update: widget.restored != null,
      );
      NotificationService.instance.cancelScheduled();
      if (widget.restored != null) {
        showAppSnackBar(context, 'Retomamos tu sesión donde ibas',
            icon: Icons.history_rounded);
      }
      _tick();
      // Android a veces nos devuelve un aviso viejo al recrear la activity
      final pending = await AppBlocker.instance.consumePendingBlockedApp();
      if (pending != null &&
          pending.isFresh(
              now: DateTime.now(), sessionStart: _clock.startedAt)) {
        _onBlockedApp(pending);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // respetar "reducir movimiento"
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _blockedSub?.cancel();
    // si cierran la app a media sesión no paramos: Android sigue el horario solo
    if (_ended && _blockedPackages.isNotEmpty) AppBlocker.instance.stop();
    _secondsLeftNotifier.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ended) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        NotificationService.instance.scheduleSessionEvents(_clock, widget.task);
      case AppLifecycleState.resumed:
        NotificationService.instance.cancelScheduled();
        _sendBlockingSchedule();
        _tick();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _persist() {
    if (_ended) return;
    SessionScope.read(context)?.saveActive(
      ActiveSessionRecord.fromClock(_sessionId, widget.task.id, _clock),
    );
    NotificationService.instance.showSessionInProgress(
        widget.task, _clock.endsAt(DateTime.now()),
        update: true);
    _sendBlockingSchedule();
  }

  void _sendBlockingSchedule() {
    if (_ended || _blockedPackages.isEmpty) return;
    AppBlocker.instance
        .start(_blockedPackages, windows: _clock.focusWindows(DateTime.now()));
  }

  void _tick() {
    if (!mounted || _ended) return;
    _now = DateTime.now();

    if (_clock.settlePause(_now)) {
      _persist();
      showAppSnackBar(context, 'Pausa terminada. De vuelta al enfoque.');
    }

    final position = _clock.position(_now);
    setState(() => _position = position);

    if (position.finished) {
      _ended = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (position.index != _lastPhaseIndex) {
      _lastPhaseIndex = position.index;
      showAppSnackBar(
        context,
        _phase.isFocus
            ? 'Ronda ${_phase.round}: de vuelta al enfoque'
            : '¡Bien! Toma un descanso de ${_phase.minutes} min',
        icon: _phase.isFocus ? Icons.spa_outlined : Icons.local_cafe_outlined,
      );
    }

    _secondsLeftNotifier.value = _secondsLeft;
    _syncBlocking();
  }

  void _toggleEmergencyPause() {
    final now = DateTime.now();
    if (_clock.isPaused(now)) {
      _clock.endPause(now);
    } else {
      _clock.startPause(now);
      Analytics.log('emergency_pause');
    }
    _persist();
    _tick();
  }

  void _skipBreak() {
    _clock.skipCurrentPhase(DateTime.now());
    _persist();
    _tick();
  }

  bool get _shouldBlock =>
      !_ended && _phase.isFocus && !_isPaused && _blockedPackages.isNotEmpty;

  void _syncBlocking() {
    final should = _shouldBlock;
    if (should == _blockingActive) return;
    _blockingActive = should;
    if (!should) {
      if (_ended && _blockedPackages.isNotEmpty) AppBlocker.instance.stop();
      if (_reminderOpen && mounted) {
        final sessionRoute = ModalRoute.of(context);
        Navigator.of(context).popUntil((route) => route == sessionRoute);
      }
    }
  }

  Future<void> _onBlockedApp(BlockedAppEvent event) async {
    if (!mounted || !_blockingActive) return;

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

  Future<void> _record(String status, {String? goalResult}) async {
    final sessions = SessionScope.read(context);
    await NotificationService.instance.cancelAll();
    await sessions?.clearActive();
    await sessions?.record(
      FocusSession(
        id: _sessionId,
        taskId: widget.task.id,
        taskTitle: widget.task.title,
        plannedMinutes: widget.task.durationMinutes,
        focusSeconds: _clock.focusSeconds(DateTime.now()),
        startedAt: _clock.startedAt,
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
    Analytics.log('session_completed', {
      'focus_minutes': _clock.focusSeconds(DateTime.now()) ~/ 60,
      'result': result ?? 'none',
    });
    if (!mounted) return;

    if (result == GoalResult.yes) {
      final tasks = TaskScope.read(context);
      final saved =
          tasks?.tasks.where((t) => t.id == widget.task.id).firstOrNull;
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir enfocado')),
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
    if (_blockedPackages.isNotEmpty) AppBlocker.instance.stop();
    await _record(SessionStatus.abandoned);
    Analytics.log('session_abandoned', {
      'focus_minutes': _clock.focusSeconds(DateTime.now()) ~/ 60,
    });
    if (!mounted) return;

    showAppSnackBar(context, 'Sesión registrada como abandonada',
        icon: Icons.close_rounded);
    Navigator.of(context).pop();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _blockedSummary {
    final names = widget.task.blockedApps;
    if (names.length == 1) return '${names.first} está bloqueada';
    if (names.length == 2) return '${names[0]} y ${names[1]} están bloqueadas';
    return '${names[0]}, ${names[1]} y ${names.length - 2} más están bloqueadas';
  }

  String get _phaseLabel {
    if (!widget.task.isPomodoro) return 'Enfoque';
    if (_phase.isFocus) {
      return 'Ronda ${_phase.round} de $_focusRounds · Enfoque';
    }
    final kind = _phase.minutes == Pomodoro.longBreakMinutes
        ? 'Descanso largo'
        : 'Descanso corto';
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
          showAppSnackBar(context,
              'Tu sesión sigue activa. Usa la pausa o abandona la sesión.',
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
                AppSpacing.screen, AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: onBreak ? p.secondaryFixed : p.primaryFixed,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _isPaused ? 'En pausa' : _phaseLabel,
                    style: t.labelMedium!.copyWith(
                        color: onBreak
                            ? p.onSecondaryFixedVariant
                            : p.onPrimaryFixed),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(
                      parent: _breath, curve: Curves.easeInOut)),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: onBreak ? p.secondaryFixed : p.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        onBreak
                            ? Icons.local_cafe_outlined
                            : Icons.spa_outlined,
                        size: 48,
                        color: accent),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: _secondsLeft <= 60
                      ? 'Queda menos de un minuto'
                      : 'Quedan ${(_secondsLeft / 60).ceil()} minutos',
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _format(_secondsLeft),
                      style: t.displaySmall!.copyWith(
                        fontSize: 64,
                        color: _isPaused ? p.onSurfaceVariant : accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu objetivo',
                          style: t.labelMedium!.copyWith(color: p.primary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.task.goal, style: t.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.task.title, style: t.bodySmall),
                      if (widget.task.blockDistractions &&
                          widget.task.blockedApps.isNotEmpty &&
                          !onBreak) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 16, color: p.tertiary),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _blockedSummary,
                                style: t.bodySmall!.copyWith(color: p.tertiary),
                              ),
                            ),
                          ],
                        ),
                        if (AppBlocker.instance.isSupported) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.picture_in_picture_alt_outlined,
                                  size: 16, color: p.onSurfaceVariant),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Si tienes un video en ventana flotante, ciérralo: esa ventana no se puede bloquear.',
                                  style: t.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: onBreak
                      ? OutlinedButton.icon(
                          onPressed: _skipBreak,
                          icon: Icon(_isLastPhase
                              ? Icons.flag_outlined
                              : Icons.skip_next_rounded),
                          label: Text(_isLastPhase
                              ? 'Terminar sesión'
                              : 'Saltar descanso'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _toggleEmergencyPause,
                          icon: Icon(_isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded),
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

class _GoalResultDialog extends StatelessWidget {
  final String goal;
  const _GoalResultDialog({required this.goal});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    // que el botón atrás no se salte la pregunta
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(Icons.emoji_events_outlined, color: p.primary, size: 36),
        title: const Text('¡Sesión completada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Cumpliste tu objetivo?',
                textAlign: TextAlign.center, style: t.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('"$goal"',
                textAlign: TextAlign.center,
                style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
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
      ),
    );
  }
}
