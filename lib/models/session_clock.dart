import 'dart:math' as math;
import 'task_model.dart';

class SessionPhase {
  final bool isFocus;
  final int minutes;
  final int round;

  const SessionPhase(
      {required this.isFocus, required this.minutes, required this.round});

  int get seconds => minutes * 60;
}

class SessionPosition {
  final int index;
  final int secondsLeft;
  final bool finished;

  const SessionPosition(this.index, this.secondsLeft, {this.finished = false});
}

// El tiempo se calcula con horas reales, no con un contador,
// así no se pierde nada si cierran la app.
class SessionClock {
  static const int emergencyPauseSeconds = 2 * 60;

  final List<SessionPhase> phases;
  final DateTime startedAt;

  int pausedSeconds;

  DateTime? pauseStartedAt;

  int skippedSeconds;

  SessionClock({
    required this.phases,
    required this.startedAt,
    this.pausedSeconds = 0,
    this.pauseStartedAt,
    this.skippedSeconds = 0,
  });

  static List<SessionPhase> phasesFor(Task task) {
    if (!task.isPomodoro) {
      return [
        SessionPhase(isFocus: true, minutes: task.durationMinutes, round: 1)
      ];
    }
    return [
      for (var r = 1; r <= task.pomodoroRounds; r++) ...[
        SessionPhase(isFocus: true, minutes: Pomodoro.focusMinutes, round: r),
        SessionPhase(
            isFocus: false, minutes: Pomodoro.breakAfterRound(r), round: r),
      ],
    ];
  }

  int get totalSeconds => phases.fold(0, (sum, p) => sum + p.seconds);

  int _secondsSince(DateTime from, DateTime now) =>
      math.max(0, now.difference(from).inSeconds);

  int _currentPauseSeconds(DateTime now) => pauseStartedAt == null
      ? 0
      : math.min(_secondsSince(pauseStartedAt!, now), emergencyPauseSeconds);

  bool isPaused(DateTime now) =>
      pauseStartedAt != null &&
      _secondsSince(pauseStartedAt!, now) < emergencyPauseSeconds;

  int pauseSecondsLeft(DateTime now) => isPaused(now)
      ? emergencyPauseSeconds - _secondsSince(pauseStartedAt!, now)
      : 0;

  // efectivo = (ahora - inicio) - pausas + descansos saltados
  int elapsed(DateTime now) {
    final raw = _secondsSince(startedAt, now) -
        pausedSeconds -
        _currentPauseSeconds(now) +
        skippedSeconds;
    return raw.clamp(0, totalSeconds);
  }

  SessionPosition position(DateTime now) {
    var remaining = elapsed(now);
    for (var i = 0; i < phases.length; i++) {
      final length = phases[i].seconds;
      if (remaining < length) return SessionPosition(i, length - remaining);
      remaining -= length;
    }
    return SessionPosition(phases.length - 1, 0, finished: true);
  }

  DateTime endsAt(DateTime now) => now.add(
      Duration(seconds: pauseSecondsLeft(now) + totalSeconds - elapsed(now)));

  int focusSeconds(DateTime now) {
    var remaining = elapsed(now);
    var focus = 0;
    for (final phase in phases) {
      if (remaining <= 0) break;
      final taken = math.min(remaining, phase.seconds);
      if (phase.isFocus) focus += taken;
      remaining -= taken;
    }
    return focus;
  }

  // Horarios de enfoque que se mandan a Kotlin para bloquear con la app cerrada
  List<(DateTime, DateTime)> focusWindows(DateTime now) {
    final pos = position(now);
    if (pos.finished) return const [];
    var time = now.add(Duration(seconds: pauseSecondsLeft(now)));
    final windows = <(DateTime, DateTime)>[];
    for (var i = pos.index; i < phases.length; i++) {
      final seconds = i == pos.index ? pos.secondsLeft : phases[i].seconds;
      final end = time.add(Duration(seconds: seconds));
      if (phases[i].isFocus) windows.add((time, end));
      time = end;
    }
    return windows;
  }

  bool settlePause(DateTime now) {
    if (pauseStartedAt != null && !isPaused(now)) {
      pausedSeconds += emergencyPauseSeconds;
      pauseStartedAt = null;
      return true;
    }
    return false;
  }

  void startPause(DateTime now) {
    settlePause(now);
    pauseStartedAt ??= now;
  }

  void endPause(DateTime now) {
    if (pauseStartedAt == null) return;
    pausedSeconds += _currentPauseSeconds(now);
    pauseStartedAt = null;
  }

  void skipCurrentPhase(DateTime now) {
    final pos = position(now);
    if (!pos.finished) skippedSeconds += pos.secondsLeft;
  }
}

class ActiveSessionRecord {
  final String sessionId;
  final String taskId;
  final DateTime startedAt;
  final int pausedSeconds;
  final DateTime? pauseStartedAt;
  final int skippedSeconds;

  const ActiveSessionRecord({
    required this.sessionId,
    required this.taskId,
    required this.startedAt,
    this.pausedSeconds = 0,
    this.pauseStartedAt,
    this.skippedSeconds = 0,
  });

  factory ActiveSessionRecord.fromClock(
          String sessionId, String taskId, SessionClock clock) =>
      ActiveSessionRecord(
        sessionId: sessionId,
        taskId: taskId,
        startedAt: clock.startedAt,
        pausedSeconds: clock.pausedSeconds,
        pauseStartedAt: clock.pauseStartedAt,
        skippedSeconds: clock.skippedSeconds,
      );

  Map<String, Object?> toDbMap() => {
        'id': 1,
        'session_id': sessionId,
        'task_id': taskId,
        'started_at': startedAt.toIso8601String(),
        'paused_seconds': pausedSeconds,
        'pause_started_at': pauseStartedAt?.toIso8601String(),
        'skipped_seconds': skippedSeconds,
      };

  factory ActiveSessionRecord.fromDbMap(Map<String, Object?> row) =>
      ActiveSessionRecord(
        sessionId: row['session_id'] as String,
        taskId: row['task_id'] as String,
        startedAt: DateTime.parse(row['started_at'] as String),
        pausedSeconds: row['paused_seconds'] as int? ?? 0,
        pauseStartedAt: row['pause_started_at'] == null
            ? null
            : DateTime.parse(row['pause_started_at'] as String),
        skippedSeconds: row['skipped_seconds'] as int? ?? 0,
      );
}
