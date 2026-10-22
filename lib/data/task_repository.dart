import 'package:flutter/widgets.dart';
import '../models/task_model.dart';
import 'app_database.dart';

/// Único punto de acceso a las tareas guardadas.
///
/// Las pantallas nunca hablan con SQLite directamente: usan este repositorio.
/// Mantiene una copia en memoria de las tareas y avisa a la interfaz
/// (ChangeNotifier) cada vez que algo cambia, para que se redibuje sola.
class TaskRepository extends ChangeNotifier {
  final AppDatabase _database;
  List<Task> _tasks = [];

  TaskRepository(this._database);

  /// Tareas ordenadas: pendientes primero, luego por prioridad y por fecha de creación.
  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get pendingTasks => _tasks.where((t) => !t.isDone).toList();

  /// La tarea pendiente más importante (la que se sugiere en "Tu siguiente tarea").
  Task? get nextTask {
    final pending = pendingTasks;
    return pending.isEmpty ? null : pending.first;
  }

  /// Carga las tareas desde SQLite. Se llama una vez al abrir la app.
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

  Future<void> delete(String id) async {
    await _database.db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Borra todo lo guardado en el teléfono (Ajustes → Reiniciar datos).
  Future<void> clearAll() async {
    await _database.db.transaction((txn) async {
      await txn.delete('sessions');
      await txn.delete('tasks');
    });
    _tasks = [];
    notifyListeners();
  }

  void _sort() {
    _tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final byPriority = Task.priorityRank(a.priority).compareTo(Task.priorityRank(b.priority));
      if (byPriority != 0) return byPriority;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
}

/// Pone el [TaskRepository] a disposición de toda la app.
///
/// Uso en una pantalla: `final repo = TaskScope.of(context);`
/// La pantalla se redibuja automáticamente cuando cambian las tareas.
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

  /// Para usar dentro de botones y acciones (no en `build`):
  /// obtiene el repositorio sin suscribir la pantalla a sus cambios.
  static TaskRepository? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TaskScope>()?.notifier;
}
