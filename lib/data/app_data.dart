import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'app_database.dart';
import 'firestore_session_repository.dart';
import 'firestore_task_repository.dart';
import 'session_repository.dart';
import 'settings_store.dart';
import 'sqlite_session_repository.dart';
import 'sqlite_task_repository.dart';
import 'task_repository.dart';

/// Elige de dónde vienen los datos: SQLite sin cuenta, Firestore con cuenta.
/// Las pantallas solo ven TaskRepository y SessionRepository, no saben cuál es.
class AppData extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final SettingsStore settings;
  final SqliteTaskRepository localTasks;
  final SqliteSessionRepository localSessions;

  String? _uid;
  Future<void> _switching = Future.value();
  FirestoreTaskRepository? _cloudTasks;
  FirestoreSessionRepository? _cloudSessions;

  AppData({required AppDatabase database, required this.firestore})
      : settings = SettingsStore(database),
        localTasks = SqliteTaskRepository(database),
        localSessions = SqliteSessionRepository(database);

  String? get uid => _uid;
  bool get usesCloud => _uid != null;

  TaskRepository get tasks => _cloudTasks ?? localTasks;
  SessionRepository get sessions => _cloudSessions ?? localSessions;

  Future<void> loadLocal() =>
      Future.wait([localTasks.load(), localSessions.load()]);

  /// null = sin cuenta (SQLite). Con uid, usa Firestore.
  // Si ya se está cambiando a esa cuenta, se espera ese mismo cambio
  Future<void> useAccount(String? uid) {
    if (uid == _uid) return _switching;
    _uid = uid;
    return _switching = _switchTo(uid);
  }

  Future<void> _switchTo(String? uid) async {
    final oldTasks = _cloudTasks;
    final oldSessions = _cloudSessions;

    if (uid == null) {
      _cloudTasks = null;
      _cloudSessions = null;
    } else {
      final cloudTasks = FirestoreTaskRepository(firestore, uid);
      final cloudSessions =
          FirestoreSessionRepository(firestore, uid, local: localSessions);
      await Future.wait([cloudTasks.load(), cloudSessions.load()]);
      if (_uid != uid) {
        cloudTasks.dispose();
        cloudSessions.dispose();
        return;
      }
      _cloudTasks = cloudTasks;
      _cloudSessions = cloudSessions;
    }
    notifyListeners();
    oldTasks?.dispose();
    oldSessions?.dispose();
  }

  bool get hasLocalData =>
      localTasks.tasks.isNotEmpty || localSessions.sessions.isNotEmpty;

  /// Sube a la cuenta lo que se hizo sin cuenta en este teléfono.
  Future<void> importLocalToCloud() async {
    final cloudTasks = _cloudTasks;
    final cloudSessions = _cloudSessions;
    if (cloudTasks == null || cloudSessions == null) return;
    await cloudTasks.importAll(localTasks.tasks);
    await cloudSessions.importAll(localSessions.sessions);
  }

  /// Borra de verdad los datos en Firestore (se espera a que termine).
  /// Se usa antes de eliminar la cuenta, porque después las reglas ya no dejan.
  Future<void> deleteCloudData() async {
    final uid = _uid;
    if (uid == null) return;
    final user = firestore.collection('users').doc(uid);
    for (final name in ['tasks', 'sessions']) {
      final docs = (await user.collection(name).get()).docs;
      for (var i = 0; i < docs.length; i += 400) {
        final batch = firestore.batch();
        for (final doc in docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await _cloudTasks?.clearAll();
    await _cloudSessions?.clearAll();
  }
}

class AppDataScope extends InheritedNotifier<AppData> {
  const AppDataScope({super.key, required AppData data, required super.child})
      : super(notifier: data);

  static AppData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDataScope>()!.notifier!;

  static AppData read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppDataScope>()!.notifier!;
}
