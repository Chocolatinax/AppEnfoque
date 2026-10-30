import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/focus_session.dart';
import '../models/session_clock.dart';
import 'session_repository.dart';

/// Historial de un usuario con cuenta: users/{uid}/sessions/{id}.
/// La sesión en curso sigue en el teléfono (la pasa [local]) por velocidad y
/// para que el bloqueo funcione con la app cerrada.
class FirestoreSessionRepository extends SessionRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  final SessionRepository local;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<FocusSession> _sessions = [];

  FirestoreSessionRepository(FirebaseFirestore firestore, String uid,
      {required this.local})
      : _collection =
            firestore.collection('users').doc(uid).collection('sessions');

  @override
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  @override
  Future<void> load() async {
    final first = Completer<void>();
    await _sub?.cancel();
    _sub = _collection.snapshots().listen((snapshot) {
      _sessions =
          snapshot.docs.map((d) => FocusSession.fromDbMap(d.data())).toList();
      _sort();
      notifyListeners();
      if (!first.isCompleted) first.complete();
    }, onError: (Object e) {
      if (!first.isCompleted) first.complete();
    });
    await first.future.timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  @override
  Future<void> record(FocusSession session) async {
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
    _sort();
    notifyListeners();
    _collection.doc(session.id).set(session.toDbMap()).catchError((_) {});
  }

  @override
  Future<void> clearAll() async {
    final ids = _sessions.map((s) => s.id).toList();
    _sessions = [];
    notifyListeners();
    await local.clearActive();
    final batch = _collection.firestore.batch();
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
    batch.commit().catchError((_) {});
  }

  Future<void> importAll(List<FocusSession> sessions) async {
    final batch = _collection.firestore.batch();
    for (final s in sessions) {
      batch.set(_collection.doc(s.id), s.toDbMap());
    }
    _sessions = {
      for (final s in [..._sessions, ...sessions]) s.id: s
    }.values.toList();
    _sort();
    notifyListeners();
    batch.commit().catchError((_) {});
  }

  @override
  Future<void> saveActive(ActiveSessionRecord record) =>
      local.saveActive(record);

  @override
  Future<ActiveSessionRecord?> loadActive() => local.loadActive();

  @override
  Future<void> clearActive() => local.clearActive();

  void _sort() => _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
