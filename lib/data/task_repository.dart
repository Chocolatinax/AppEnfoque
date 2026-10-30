import 'package:flutter/widgets.dart';
import '../models/task_model.dart';

abstract class TaskRepository extends ChangeNotifier {
  List<Task> get tasks;

  List<Task> get pendingTasks => tasks.where((t) => !t.isDone).toList();

  Task? get nextTask {
    final pending = pendingTasks;
    return pending.isEmpty ? null : pending.first;
  }

  Future<void> load();
  Future<void> add(Task task);
  Future<void> update(Task task);
  Future<void> toggleDone(String id);
  Future<void> delete(String id);
  Future<void> clearAll();
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
