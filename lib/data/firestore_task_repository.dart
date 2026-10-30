import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'task_repository.dart';

/// Tareas de un usuario con cuenta: users/{uid}/tasks/{id}.
///
/// Firestore guarda una copia en el teléfono, así que funciona sin internet y
/// sincroniza solo cuando vuelve la conexión. Por eso las escrituras no se
/// esperan: sin internet, el Future no termina hasta que hay conexión.
class FirestoreTaskRepository extends TaskRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<Task> _tasks = [];

  FirestoreTaskRepository(FirebaseFirestore firestore, String uid)
      : _collection =
            firestore.collection('users').doc(uid).collection('tasks');

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);

  @override
  Future<void> load() async {
    final first = Completer<void>();
    await _sub?.cancel();
    _sub = _collection.snapshots().listen((snapshot) {
      _tasks = snapshot.docs.map((d) => Task.fromDbMap(d.data())).toList();
      _sort();
      notifyListeners();
      if (!first.isCompleted) first.complete();
    }, onError: (Object e) {
      if (!first.isCompleted) first.complete();
    });
    await first.future.timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  void _write(Future<void> operation) => operation.catchError((_) {});

  void _upsertLocal(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    _sort();
    notifyListeners();
  }

  @override
  Future<void> add(Task task) async {
    _upsertLocal(task);
    _write(_collection.doc(task.id).set(task.toDbMap()));
  }

  @override
  Future<void> update(Task task) async {
    _upsertLocal(task);
    _write(_collection.doc(task.id).set(task.toDbMap()));
  }

  @override
  Future<void> toggleDone(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    _upsertLocal(updated);
    _write(_collection.doc(id).update({'is_done': updated.isDone ? 1 : 0}));
  }

  @override
  Future<void> delete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _write(_collection.doc(id).delete());
  }

  @override
  Future<void> clearAll() async {
    final ids = _tasks.map((t) => t.id).toList();
    _tasks = [];
    notifyListeners();
    final batch = _collection.firestore.batch();
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
    _write(batch.commit());
  }

  /// Sube tareas que estaban solo en el teléfono (al iniciar sesión).
  Future<void> importAll(List<Task> tasks) async {
    final batch = _collection.firestore.batch();
    for (final task in tasks) {
      batch.set(_collection.doc(task.id), task.toDbMap());
      _upsertLocal(task);
    }
    _write(batch.commit());
  }

  void _sort() {
    _tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final byPriority = Task.priorityRank(a.priority)
          .compareTo(Task.priorityRank(b.priority));
      if (byPriority != 0) return byPriority;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
