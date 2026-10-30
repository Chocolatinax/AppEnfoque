import 'package:flutter/widgets.dart';
import '../models/focus_session.dart';
import '../models/session_clock.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'app_database.dart';

class SessionRepository extends ChangeNotifier {
  final AppDatabase _database;
  List<FocusSession> _sessions = [];

  SessionRepository(this._database);

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Future<void> load() async {
    final rows =
        await _database.db.query('sessions', orderBy: 'started_at DESC');
    _sessions = rows.map(FocusSession.fromDbMap).toList();
    notifyListeners();
  }

  Future<void> record(FocusSession session) async {
    await _database.db.insert('sessions', session.toDbMap());
    _sessions.insert(0, session);
    _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  List<FocusSession> between(DateTime from, DateTime to) => _sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .toList();

  int currentStreak({DateTime? today}) {
    final now = today ?? DateTime.now();
    final days = _sessions
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

  Future<void> saveActive(ActiveSessionRecord record) =>
      _database.db.insert('active_session', record.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<ActiveSessionRecord?> loadActive() async {
    final rows = await _database.db.query('active_session', limit: 1);
    return rows.isEmpty ? null : ActiveSessionRecord.fromDbMap(rows.first);
  }

  Future<void> clearActive() => _database.db.delete('active_session');

  Future<void> clearAll() async {
    await _database.db.delete('active_session');
    await _database.db.delete('sessions');
    _sessions = [];
    notifyListeners();
  }
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
