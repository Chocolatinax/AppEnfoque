import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enfoque_app/data/app_database.dart';
import 'package:enfoque_app/data/session_repository.dart';
import 'package:enfoque_app/models/focus_session.dart';
import 'package:enfoque_app/data/sqlite_session_repository.dart';
import 'package:enfoque_app/models/task_model.dart';

/// Pruebas del historial de sesiones (R2) y de las reglas del Pomodoro.
void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SessionRepository repo;

  setUp(() async {
    database = await AppDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repo = SqliteSessionRepository(database);
    await repo.load();
  });

  tearDown(() => database.close());

  FocusSession buildSession(String id, DateTime start,
          {String status = SessionStatus.completed, int minutes = 25}) =>
      FocusSession(
        id: id,
        taskId: null,
        taskTitle: 'Estudiar Cálculo',
        plannedMinutes: 25,
        focusSeconds: minutes * 60,
        startedAt: start,
        endedAt: start.add(Duration(minutes: minutes)),
        status: status,
        goalResult: status == SessionStatus.completed ? GoalResult.yes : null,
      );

  group('Historial de sesiones (SQLite)', () {
    test('Registra fecha, duración, tarea y estado de la sesión (R2)',
        () async {
      final start = DateTime(2026, 10, 20, 10, 30);
      await repo.record(buildSession('1', start, minutes: 40));
      await repo.record(buildSession('2', start.add(const Duration(hours: 2)),
          status: SessionStatus.abandoned, minutes: 10));

      final reopened = SqliteSessionRepository(database);
      await reopened.load();

      expect(reopened.sessions, hasLength(2));
      final completed = reopened.sessions.firstWhere((s) => s.id == '1');
      expect(completed.startedAt, start);
      expect(completed.focusSeconds, 40 * 60);
      expect(completed.taskTitle, 'Estudiar Cálculo');
      expect(completed.isCompleted, isTrue);
      expect(completed.goalResult, GoalResult.yes);
      expect(reopened.sessions.firstWhere((s) => s.id == '2').isCompleted,
          isFalse);
    });

    test('Filtra las sesiones de una semana', () async {
      await repo.record(buildSession('a', DateTime(2026, 10, 19, 9))); // lunes
      await repo
          .record(buildSession('b', DateTime(2026, 10, 25, 22))); // domingo
      await repo.record(
          buildSession('c', DateTime(2026, 10, 26, 8))); // lunes siguiente

      final week = repo.between(DateTime(2026, 10, 19), DateTime(2026, 10, 26));
      expect(week.map((s) => s.id).toSet(), {'a', 'b'});
    });

    test('Calcula la racha de días seguidos con sesiones completadas',
        () async {
      final today = DateTime(2026, 10, 22, 18);
      await repo.record(buildSession('1', DateTime(2026, 10, 22, 9)));
      await repo.record(buildSession('2', DateTime(2026, 10, 21, 9)));
      await repo.record(buildSession('3', DateTime(2026, 10, 20, 9)));
      await repo
          .record(buildSession('4', DateTime(2026, 10, 18, 9))); // día cortado
      await repo.record(buildSession('5', DateTime(2026, 10, 19, 9),
          status: SessionStatus.abandoned));

      expect(repo.currentStreak(today: today), 3);
    });
  });

  group('Reglas del Pomodoro', () {
    test('Descanso corto de 5 min y largo de 25 min después de la 4.ª ronda',
        () {
      expect(Pomodoro.breakAfterRound(1), 5);
      expect(Pomodoro.breakAfterRound(2), 5);
      expect(Pomodoro.breakAfterRound(3), 5);
      expect(Pomodoro.breakAfterRound(4), 25);
      expect(Pomodoro.breakAfterRound(5), 5);
    });

    test('La duración de una tarea Pomodoro se muestra con sus rondas', () {
      final task = Task(
        id: '1',
        title: 'Leer',
        goal: 'Leer el capítulo 3 completo',
        durationMinutes: 100,
        timerMode: TimerMode.pomodoro,
        pomodoroRounds: 4,
      );
      expect(task.isPomodoro, isTrue);
      expect(task.durationLabel, '4 pomodoros · 100 min');
    });
  });
}
