import 'package:flutter/widgets.dart';
import '../models/focus_session.dart';
import '../models/session_clock.dart';

abstract class SessionRepository extends ChangeNotifier {
  List<FocusSession> get sessions;

  Future<void> load();
  Future<void> record(FocusSession session);
  Future<void> clearAll();

  Future<void> saveActive(ActiveSessionRecord record);
  Future<ActiveSessionRecord?> loadActive();
  Future<void> clearActive();

  List<FocusSession> between(DateTime from, DateTime to) => sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .toList();

  int currentStreak({DateTime? today}) {
    final now = today ?? DateTime.now();
    final days = sessions
        .where((s) => s.isCompleted)
        .map((s) => _dateOnly(s.startedAt))
        .toSet();

    var day = _dateOnly(now);
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));

    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class SessionScope extends InheritedNotifier<SessionRepository> {
  const SessionScope({
    super.key,
    required SessionRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static SessionRepository of(BuildContext context) {
    final repo =
        context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    assert(
        repo != null, 'No hay un SessionScope arriba en el árbol de widgets.');
    return repo!;
  }

  static SessionRepository? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()?.notifier;
}
