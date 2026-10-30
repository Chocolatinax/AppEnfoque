import 'package:flutter/material.dart';
import '../../data/task_repository.dart';
import '../../models/task_model.dart';
import '../../theme/app_palette.dart';

Future<bool> confirmDeleteTask(BuildContext context, Task task) async {
  final p = context.palette;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar tarea?'),
      content: Text(
        '"${task.title}" se borrará de tu lista. Las sesiones que ya hiciste se quedan en tu historial.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: p.error),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> deleteTaskWithUndo(BuildContext context, Task task) async {
  final repo = TaskScope.read(context);
  if (repo == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final p = context.palette;

  await repo.delete(task.id);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Tarea eliminada',
        style:
            TextStyle(fontWeight: FontWeight.w600, color: p.inverseOnSurface),
      ),
      action: SnackBarAction(
        label: 'Deshacer',
        textColor: p.primaryFixed,
        onPressed: () => repo.add(task),
      ),
      // con action el snackbar no se cierra solo si no ponemos esto
      persist: false,
      duration: const Duration(seconds: 6),
    ),
  );
}
