import '../models/task_model.dart';
import 'app_database.dart';
import 'task_repository.dart';

class SqliteTaskRepository extends TaskRepository {
  final AppDatabase _database;
  List<Task> _tasks = [];

  SqliteTaskRepository(this._database);

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);

  @override
  Future<void> load() async {
    final rows = await _database.db.query('tasks');
    _tasks = rows.map(Task.fromDbMap).toList();
    _sort();
    notifyListeners();
  }

  @override
  Future<void> add(Task task) async {
    await _database.db.insert('tasks', task.toDbMap());
    _tasks.add(task);
    _sort();
    notifyListeners();
  }

  @override
  Future<void> toggleDone(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    await _database.db.update(
      'tasks',
      {'is_done': updated.isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _tasks[index] = updated;
    _sort();
    notifyListeners();
  }

  @override
  Future<void> update(Task task) async {
    await _database.db
        .update('tasks', task.toDbMap(), where: 'id = ?', whereArgs: [task.id]);
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
  // se quita primero de la lista para que la UI no espere a la BD
  Future<void> delete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _database.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAll() async {
    await _database.db.transaction((txn) async {
      await txn.delete('active_session');
      await txn.delete('sessions');
      await txn.delete('tasks');
    });
    _tasks = [];
    notifyListeners();
  }

  // pendientes primero, después por prioridad y las más nuevas arriba
  void _sort() {
    _tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final byPriority = Task.priorityRank(a.priority)
          .compareTo(Task.priorityRank(b.priority));
      if (byPriority != 0) return byPriority;
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
