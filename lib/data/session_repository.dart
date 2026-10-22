import 'package:flutter/widgets.dart';
import '../models/focus_session.dart';
import 'app_database.dart';

/// Acceso a las sesiones de enfoque guardadas (historial).
///
/// Igual que [TaskRepository]: guarda en SQLite, mantiene una copia en memoria
/// y avisa a la interfaz cuando hay cambios.
class SessionRepository extends ChangeNotifier {
  final AppDatabase _database;
  List<FocusSession> _sessions = [];

  SessionRepository(this._database);

  /// Sesiones de la más reciente a la más antigua.
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Future<void> load() async {
    final rows = await _database.db.query('sessions', orderBy: 'started_at DESC');
    _sessions = rows.map(FocusSession.fromDbMap).toList();
    notifyListeners();
  }

  /// Registra una sesión terminada (completada o abandonada).
  Future<void> record(FocusSession session) async {
    await _database.db.insert('sessions', session.toDbMap());
    _sessions.insert(0, session);
    _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  /// Sesiones que empezaron entre [from] (incluido) y [to] (excluido).
  List<FocusSession> between(DateTime from, DateTime to) => _sessions
      .where((s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to))
      .toList();

  /// Días seguidos (hasta hoy o ayer) con al menos una sesión completada.
  int currentStreak({DateTime? today}) {
    final now = today ?? DateTime.now();
    final days = _sessions
        .where((s) => s.isCompleted)
        .map((s) => _dateOnly(s.startedAt))
        .toSet();

    var day = _dateOnly(now);
    // Si hoy todavía no hay sesión, la racha sigue viva desde ayer.
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));

    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Fecha sin hora (para comparar días).
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Borra el historial (Ajustes → Reiniciar datos).
  Future<void> clearAll() async {
    await _database.db.delete('sessions');
    _sessions = [];
    notifyListeners();
  }
}

/// Pone el [SessionRepository] a disposición de toda la app.
class SessionScope extends InheritedNotifier<SessionRepository> {
  const SessionScope({
    super.key,
    required SessionRepository repository,
    required super.child,
  }) : super(notifier: repository);

  /// Para usar en `build`: la pantalla se redibuja cuando cambian las sesiones.
  static SessionRepository of(BuildContext context) {
    final repo = context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    assert(repo != null, 'No hay un SessionScope arriba en el árbol de widgets.');
    return repo!;
  }

  /// Para usar dentro de botones y acciones (no en `build`).
  static SessionRepository? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()?.notifier;
}
