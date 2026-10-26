import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/models/session_clock.dart';
import 'package:enfoque_app/models/task_model.dart';
import 'package:enfoque_app/services/notification_service.dart';

/// Pruebas de los avisos programados de la sesión (qué aviso y a qué hora).
void main() {
  final start = DateTime(2026, 10, 25, 10, 0, 0);
  DateTime at(int minutes) => start.add(Duration(minutes: minutes));

  Task task({int minutes = 25, int rounds = 0}) => Task(
        id: 't',
        title: 'Estudiar Cálculo',
        goal: 'Resolver 5 ejercicios de integrales',
        durationMinutes: rounds > 0 ? rounds * 25 : minutes,
        timerMode: rounds > 0 ? TimerMode.pomodoro : TimerMode.free,
        pomodoroRounds: rounds,
      );

  SessionClock clockFor(Task t) =>
      SessionClock(phases: SessionClock.phasesFor(t), startedAt: start);

  test('Tiempo libre: un solo aviso al terminar la sesión', () {
    final t = task(minutes: 45);
    final events =
        NotificationService.planSessionEvents(clockFor(t), t, at(10));
    expect(events, hasLength(1));
    expect(events.single.title, '¡Sesión completada!');
    expect(events.single.at, at(45));
  });

  test('Pomodoro: avisa el fin de cada ronda y de cada descanso', () {
    final t = task(rounds: 2); // 25 + 5 + 25 + 5
    final events = NotificationService.planSessionEvents(clockFor(t), t, at(0));
    expect(events.map((e) => e.title), [
      '¡Ronda 1 completada!',
      'Descanso terminado',
      '¡Ronda 2 completada!',
      '¡Sesión completada!',
    ]);
    expect(events.map((e) => e.at), [at(25), at(30), at(55), at(60)]);
    expect(events.first.body, 'Toma un descanso de 5 min.');
    expect(events[1].body, 'Vuelve a enfocarte: ronda 2.');
  });

  test('Solo programa lo que falta de la sesión', () {
    final t = task(rounds: 2);
    final events =
        NotificationService.planSessionEvents(clockFor(t), t, at(40));
    expect(events.map((e) => e.at), [at(55), at(60)]);
  });

  test('En pausa: avisa el fin de la pausa y corre los demás avisos', () {
    final t = task(minutes: 25);
    final clock = clockFor(t)..startPause(at(10));
    final events = NotificationService.planSessionEvents(clock, t, at(10));
    expect(events.first.title, 'Tu pausa terminó');
    expect(events.first.at, at(12));
    expect(events.last.at, at(27)); // 25 min de enfoque + 2 de pausa
  });

  test('Sin avisos si la sesión ya terminó', () {
    final t = task(minutes: 25);
    expect(
        NotificationService.planSessionEvents(clockFor(t), t, at(30)), isEmpty);
  });

  test('La hora de fin estimada incluye la pausa', () {
    final clock = clockFor(task(minutes: 25))..startPause(at(10));
    expect(clock.endsAt(at(10)), at(27));
  });
}
