import 'dart:math' as math;
import 'task_model.dart';

/// Una fase de la sesión: enfoque o descanso.
class SessionPhase {
  final bool isFocus;
  final int minutes;
  final int round;

  const SessionPhase(
      {required this.isFocus, required this.minutes, required this.round});

  int get seconds => minutes * 60;
}

/// Dónde va la sesión en un momento dado.
class SessionPosition {
  final int index; // fase actual
  final int secondsLeft; // segundos que faltan de esa fase
  final bool finished;

  const SessionPosition(this.index, this.secondsLeft, {this.finished = false});
}

/// Reloj de la sesión basado en horas reales (requerimiento R5).
///
/// En vez de restar un segundo cada segundo (que se pierde si la app se cierra),
/// guarda CUÁNDO empezó la sesión, cuánto estuvo en pausa y qué descansos se saltaron.
/// Con eso calcula en cualquier momento la fase y el tiempo restante, aunque la app
/// haya estado cerrada.
///
///   tiempo efectivo = (ahora − inicio) − pausas + descansos saltados
class SessionClock {
  static const int emergencyPauseSeconds = 2 * 60;

  final List<SessionPhase> phases;
  final DateTime startedAt;

  /// Segundos de pausas que ya terminaron.
  int pausedSeconds;

  /// Inicio de la pausa de emergencia en curso (null si no hay pausa).
  DateTime? pauseStartedAt;

  /// Segundos de descanso que el usuario se saltó.
  int skippedSeconds;

  SessionClock({
    required this.phases,
    required this.startedAt,
    this.pausedSeconds = 0,
    this.pauseStartedAt,
    this.skippedSeconds = 0,
  });

  /// Fases de una tarea: un bloque (tiempo libre) o rondas con descansos (Pomodoro).
  static List<SessionPhase> phasesFor(Task task) {
    if (!task.isPomodoro) {
      return [
        SessionPhase(isFocus: true, minutes: task.durationMinutes, round: 1)
      ];
    }
    return [
      for (var r = 1; r <= task.pomodoroRounds; r++) ...[
        SessionPhase(isFocus: true, minutes: Pomodoro.focusMinutes, round: r),
        // Toda ronda termina con su descanso (también la última)
        SessionPhase(
            isFocus: false, minutes: Pomodoro.breakAfterRound(r), round: r),
      ],
    ];
  }

  int get totalSeconds => phases.fold(0, (sum, p) => sum + p.seconds);

  int _secondsSince(DateTime from, DateTime now) =>
      math.max(0, now.difference(from).inSeconds);

  /// Segundos transcurridos de la pausa en curso (máximo 2 minutos).
  int _currentPauseSeconds(DateTime now) => pauseStartedAt == null
      ? 0
      : math.min(_secondsSince(pauseStartedAt!, now), emergencyPauseSeconds);

  bool isPaused(DateTime now) =>
      pauseStartedAt != null &&
      _secondsSince(pauseStartedAt!, now) < emergencyPauseSeconds;

  int pauseSecondsLeft(DateTime now) => isPaused(now)
      ? emergencyPauseSeconds - _secondsSince(pauseStartedAt!, now)
      : 0;

  /// Tiempo efectivo de la sesión (sin pausas, con los descansos saltados).
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

  /// Hora estimada de fin de la sesión (contando lo que falte de la pausa).
  DateTime endsAt(DateTime now) => now.add(
      Duration(seconds: pauseSecondsLeft(now) + totalSeconds - elapsed(now)));

  /// Segundos reales de enfoque (sin contar descansos ni pausas).
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

  /// Horarios de los bloques de enfoque que faltan (inicio, fin), contando desde [now].
  ///
  /// Se le pasan a Android para que bloquee en cada ronda aunque Floria esté cerrada.
  /// Si hay una pausa en curso, todo empieza cuando termine la pausa. Si el usuario
  /// pausa o salta un descanso, Floria recalcula los horarios y los vuelve a enviar.
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

  /// Si la pausa ya cumplió sus 2 minutos, la cierra. Devuelve `true` si cambió algo.
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

  /// Salta lo que queda de la fase actual (se usa para saltar un descanso).
  void skipCurrentPhase(DateTime now) {
    final pos = position(now);
    if (!pos.finished) skippedSeconds += pos.secondsLeft;
  }
}

/// Lo que se guarda en SQLite para poder retomar la sesión al reabrir la app.
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
        'id': 1, // solo puede haber una sesión en curso
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
