import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enfoque_app/data/app_database.dart';
import 'package:enfoque_app/data/session_repository.dart';
import 'package:enfoque_app/models/session_clock.dart';
import 'package:enfoque_app/models/task_model.dart';

/// Pruebas del reloj de sesión (requerimiento R5: si la app se cierra durante una
/// sesión, al reabrirla el temporizador muestra el tiempo real transcurrido).
void main() {
  final start = DateTime(2026, 10, 25, 10, 0, 0);
  DateTime at(int minutes, [int seconds = 0]) =>
      start.add(Duration(minutes: minutes, seconds: seconds));

  Task freeTask(int minutes) => Task(
      id: 'libre',
      title: 'Leer',
      goal: 'Leer el capítulo 3 completo',
      durationMinutes: minutes);

  Task pomodoroTask(int rounds) => Task(
        id: 'pomo',
        title: 'Cálculo',
        goal: 'Resolver 5 ejercicios de integrales',
        durationMinutes: rounds * 25,
        timerMode: TimerMode.pomodoro,
        pomodoroRounds: rounds,
      );

  SessionClock clockFor(Task task) =>
      SessionClock(phases: SessionClock.phasesFor(task), startedAt: start);

  group('Tiempo libre', () {
    test('Calcula el tiempo restante a partir de la hora real', () {
      final clock = clockFor(freeTask(45));
      expect(clock.position(at(10)).secondsLeft, 35 * 60);
      expect(clock.focusSeconds(at(10)), 10 * 60);
    });

    test(
        'R5: tras 30 min con la app cerrada, muestra el tiempo real (no reiniciado)',
        () {
      final clock = clockFor(freeTask(45));
      // La app se cerró al minuto 5 y se reabrió al minuto 35
      final restored = SessionClock(
        phases: clock.phases,
        startedAt: clock.startedAt,
        pausedSeconds: clock.pausedSeconds,
        skippedSeconds: clock.skippedSeconds,
      );
      expect(restored.position(at(35)).secondsLeft, 10 * 60);
    });

    test(
        'Si el tiempo terminó con la app cerrada, la sesión aparece como terminada',
        () {
      final clock = clockFor(freeTask(25));
      final pos = clock.position(at(60));
      expect(pos.finished, isTrue);
      expect(clock.focusSeconds(at(60)),
          25 * 60); // no cuenta más del tiempo planeado
    });
  });

  group('Pausa de emergencia', () {
    test('El tiempo no avanza durante la pausa', () {
      final clock = clockFor(freeTask(25));
      clock.startPause(at(10));
      expect(clock.isPaused(at(11)), isTrue);
      expect(clock.position(at(11)).secondsLeft, 15 * 60);
      expect(clock.pauseSecondsLeft(at(11)), 60);
    });

    test('Reanudar antes de tiempo descuenta solo lo que duró la pausa', () {
      final clock = clockFor(freeTask(25));
      clock.startPause(at(10));
      clock.endPause(at(10, 30)); // 30 segundos de pausa
      expect(clock.position(at(12)).secondsLeft, (13 * 60) + 30);
    });

    test('La pausa termina sola a los 2 minutos, aunque la app esté cerrada',
        () {
      final clock = clockFor(freeTask(25));
      clock.startPause(at(10));
      expect(clock.isPaused(at(20)), isFalse);
      // 20 min reales − 2 min de pausa = 18 min efectivos → faltan 7
      expect(clock.position(at(20)).secondsLeft, 7 * 60);
      expect(clock.settlePause(at(20)), isTrue);
      expect(clock.pauseStartedAt, isNull);
      expect(clock.position(at(20)).secondsLeft, 7 * 60);
    });
  });

  group('Pomodoro', () {
    test('Sigue las rondas y descansos con la hora real', () {
      final clock =
          clockFor(pomodoroTask(2)); // 25 enfoque, 5 desc., 25 enfoque, 5 desc.
      expect(clock.phases.length, 4);

      final inBreak = clock.position(at(27));
      expect(clock.phases[inBreak.index].isFocus, isFalse);
      expect(inBreak.secondsLeft, 3 * 60);

      final secondRound = clock.position(at(40));
      expect(clock.phases[secondRound.index].round, 2);
      expect(secondRound.secondsLeft, 15 * 60);
    });

    test('Saltar un descanso adelanta a la siguiente ronda', () {
      final clock = clockFor(pomodoroTask(2));
      clock.skipCurrentPhase(at(26)); // faltaban 4 min de descanso
      final pos = clock.position(at(26));
      expect(clock.phases[pos.index].isFocus, isTrue);
      expect(clock.phases[pos.index].round, 2);
      expect(pos.secondsLeft, 25 * 60);
    });

    test('El tiempo de enfoque no cuenta descansos', () {
      final clock = clockFor(pomodoroTask(2));
      expect(clock.focusSeconds(at(40)), (25 + 10) * 60);
    });
  });

  group('Horario de bloqueo (se le pasa a Android)', () {
    test('Pomodoro: un horario por ronda, sin los descansos', () {
      final clock = clockFor(pomodoroTask(2)); // 25 enf, 5 desc, 25 enf, 5 desc
      expect(clock.focusWindows(at(0)), [(at(0), at(25)), (at(30), at(55))]);
    });

    test('Desde un descanso, el primer horario es la siguiente ronda', () {
      final clock = clockFor(pomodoroTask(2));
      expect(clock.focusWindows(at(27)), [(at(30), at(55))]);
    });

    test('En pausa, todo se corre lo que falta de la pausa', () {
      final clock = clockFor(freeTask(25))..startPause(at(10));
      // Faltan 15 min de enfoque y 2 min de pausa
      expect(clock.focusWindows(at(10)), [(at(12), at(27))]);
    });

    test('Al saltar un descanso, la siguiente ronda empieza ya', () {
      final clock = clockFor(pomodoroTask(2))..skipCurrentPhase(at(26));
      expect(clock.focusWindows(at(26)), [(at(26), at(51))]);
    });

    test('Sin horarios si la sesión ya terminó', () {
      expect(clockFor(freeTask(25)).focusWindows(at(30)), isEmpty);
    });
  });

  group('Sesión en curso guardada en SQLite', () {
    sqfliteFfiInit();

    test('Se guarda, se recupera igual y se borra al terminar', () async {
      final db = await AppDatabase.open(
          factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      final repo = SessionRepository(db);
      await repo.load();
      expect(await repo.loadActive(), isNull);

      final clock = clockFor(freeTask(45))
        ..pausedSeconds = 30
        ..skippedSeconds = 0
        ..pauseStartedAt = at(12);
      await repo
          .saveActive(ActiveSessionRecord.fromClock('s1', 'libre', clock));

      final loaded = await repo.loadActive();
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, 's1');
      expect(loaded.taskId, 'libre');
      expect(loaded.startedAt, start);
      expect(loaded.pausedSeconds, 30);
      expect(loaded.pauseStartedAt, at(12));

      // Guardar de nuevo reemplaza (solo hay una sesión en curso)
      await repo.saveActive(ActiveSessionRecord.fromClock(
          's1', 'libre', clock..pausedSeconds = 90));
      expect((await repo.loadActive())!.pausedSeconds, 90);

      await repo.clearActive();
      expect(await repo.loadActive(), isNull);
      await db.close();
    });
  });
}
