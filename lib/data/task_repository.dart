import 'package:flutter/widgets.dart';
import '../models/task_model.dart';
import 'app_database.dart';

class TaskRepository extends ChangeNotifier {
  final AppDatabase _database;
  List<Task> _tasks = [];

  TaskRepository(this._database);

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get pendingTasks => _tasks.where((t) => !t.isDone).toList();

  Task? get nextTask {
    final pending = pendingTasks;
    return pending.isEmpty ? null : pending.first;
  }

  Future<void> load() async {
    final rows = await _database.db.query('tasks');
    _tasks = rows.map(Task.fromDbMap).toList();
    _sort();
    notifyListeners();
  }

  Future<void> add(Task task) async {
    await _database.db.insert('tasks', task.toDbMap());
    _tasks.add(task);
    _sort();
    notifyListeners();
  }

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

  // se quita primero de la lista para que la UI no espere a la BD
  Future<void> delete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _database.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

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

class TaskScope extends InheritedNotifier<TaskRepository> {
  const TaskScope({
    super.key,
    required TaskRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static TaskRepository of(BuildContext context) {
    final repo = maybeOf(context);
    assert(repo != null, 'No hay un TaskScope arriba en el árbol de widgets.');
    return repo!;
  }

  static TaskRepository? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaskScope>()?.notifier;

  static TaskRepository? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TaskScope>()?.notifier;
}
