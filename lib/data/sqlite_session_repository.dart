import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/focus_session.dart';
import '../models/session_clock.dart';
import 'app_database.dart';
import 'session_repository.dart';

class SqliteSessionRepository extends SessionRepository {
  final AppDatabase _database;
  List<FocusSession> _sessions = [];

  SqliteSessionRepository(this._database);

  @override
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  @override
  Future<void> load() async {
    final rows =
        await _database.db.query('sessions', orderBy: 'started_at DESC');
    _sessions = rows.map(FocusSession.fromDbMap).toList();
    notifyListeners();
  }

  @override
  Future<void> record(FocusSession session) async {
    await _database.db.insert('sessions', session.toDbMap());
    _sessions.insert(0, session);
    _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  @override
  Future<void> saveActive(ActiveSessionRecord record) =>
      _database.db.insert('active_session', record.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<ActiveSessionRecord?> loadActive() async {
    final rows = await _database.db.query('active_session', limit: 1);
    return rows.isEmpty ? null : ActiveSessionRecord.fromDbMap(rows.first);
  }

  @override
  Future<void> clearActive() => _database.db.delete('active_session');

  @override
  Future<void> clearAll() async {
    await _database.db.delete('active_session');
    await _database.db.delete('sessions');
    _sessions = [];
    notifyListeners();
  }
}
