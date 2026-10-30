import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../models/task_model.dart';
import '../services/app_blocker.dart';
import '../services/notification_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'active_session_screen.dart';
import 'blocking_permission_screen.dart';

enum _PermissionChoice { activate, withoutBlocking }

Future<bool> launchFocusSession(BuildContext context, Task task,
    {bool replace = false}) async {
  final blocker = AppBlocker.instance;
  final needsBlocking = task.blockDistractions && task.blockedApps.isNotEmpty;

  // leerlo antes del await (no usar context después)
  final isFirstSession = SessionScope.read(context)?.sessions.isEmpty ?? false;

  final notifications = NotificationService.instance;
  await notifications.requestPermission();

  if (isFirstSession &&
      notifications.supportsExactAlarms &&
      !await notifications.canScheduleExact()) {
    if (!context.mounted) return false;
    final activate = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const _ExactAlarmSheet(),
    );
    if (activate == true) await notifications.requestExactAlarms();
  }

  if (needsBlocking && blocker.isSupported && !await blocker.isEnabled()) {
    if (!context.mounted) return false;
    final choice = await showModalBottomSheet<_PermissionChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const _PermissionSheet(),
    );
    if (choice == null || !context.mounted) return false;

    if (choice == _PermissionChoice.activate) {
      final ready = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (_) => const BlockingPermissionScreen(fromSession: true)),
      );
      if (ready != true || !context.mounted) return false;
    }
  }

  if (!context.mounted) return false;
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  final route =
      MaterialPageRoute<void>(builder: (_) => ActiveSessionScreen(task: task));
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
  return true;
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.shield_outlined, size: 40, color: p.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Activa el bloqueo de apps',
                textAlign: TextAlign.center, style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Para bloquear tus distracciones durante la sesión, Android necesita un permiso. '
              'Solo tienes que activarlo una vez.',
              textAlign: TextAlign.center,
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _PermissionChoice.activate),
              child: const Text('Activar bloqueo'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _PermissionChoice.withoutBlocking),
              child: const Text('Iniciar sin bloqueo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExactAlarmSheet extends StatelessWidget {
  const _ExactAlarmSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.alarm_on_outlined, size: 40, color: p.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Avisos a tiempo',
                textAlign: TextAlign.center, style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Para avisarte justo cuando termina cada ronda o descanso, activa '
              '"Alarmas y recordatorios" para Floria. Si no, los avisos pueden llegar unos minutos tarde.',
              textAlign: TextAlign.center,
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activar'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }
}
