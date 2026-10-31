import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/plural.dart';
import '../utils/ui_feedback.dart';
import 'welcome_screen.dart';

/// Inicia sesión con Google. Devuelve true si quedó con cuenta.
Future<bool> signInWithGoogleFlow(BuildContext context) async {
  final auth = AuthScope.read(context);
  final data = AppDataScope.read(context);
  if (auth == null) return false;

  final AppUser user;
  try {
    user = await auth.signInWithGoogle();
  } on SignInCanceled {
    return false;
  } catch (e) {
    debugPrint('[Auth] Error al iniciar sesión: $e');
    final code = e is FirebaseAuthException ? ' (${e.code})' : '';
    if (context.mounted) {
      showAppSnackBar(
          context,
          kDebugMode
              ? 'No se pudo iniciar sesión$code'
              : 'No se pudo iniciar sesión. Revisa tu conexión.',
          isError: true);
    }
    return false;
  }

  await data.useAccount(user.uid);
  Analytics.log('login', {'method': 'google'});

  if (data.hasLocalData && context.mounted) {
    final tasks = data.localTasks.tasks.length;
    final upload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Subir tus datos a tu cuenta?'),
        content: Text(
          'En este teléfono tienes ${plural(tasks, 'tarea', 'tareas')} e historial '
          'guardados sin cuenta. Si los subes, los verás en cualquier teléfono '
          'donde inicies sesión.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Subir')),
        ],
      ),
    );
    if (upload == true) await data.importLocalToCloud();
  }

  if (context.mounted) {
    showAppSnackBar(context,
        'Hola${user.firstName == null ? '' : ', ${user.firstName}'}. Tus datos se guardan en tu cuenta.');
  }
  return true;
}

Future<void> signOutFlow(BuildContext context) async {
  final auth = AuthScope.read(context);
  final data = AppDataScope.read(context);
  if (auth == null) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: const Text(
        'Tus tareas e historial quedan guardados en tu cuenta. En este teléfono '
        'volverás a ver lo que tengas sin cuenta.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión')),
      ],
    ),
  );
  if (ok != true) return;

  await auth.signOut();
  await data.useAccount(null);
  if (context.mounted) _backToWelcome(context, 'Sesión cerrada');
}

/// Después de cerrar sesión o eliminar la cuenta se vuelve a la Bienvenida,
/// donde se puede entrar con otra cuenta o seguir sin cuenta.
void _backToWelcome(BuildContext context, String message) {
  showAppSnackBar(context, message);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    (route) => false,
  );
}

Future<void> deleteAccountFlow(BuildContext context) async {
  final auth = AuthScope.read(context);
  final data = AppDataScope.read(context);
  if (auth == null) return;
  final p = context.palette;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: const Text(
        'Se borrarán tu cuenta de Floria y todas las tareas e historial guardados '
        'en ella. Necesitas internet. Esta acción no se puede deshacer.',
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
  if (ok != true || !context.mounted) return;

  try {
    await data.deleteCloudData();
    await auth.deleteAccount();
    await data.useAccount(null);
    if (context.mounted) _backToWelcome(context, 'Tu cuenta fue eliminada');
  } on SignInCanceled {
    return;
  } catch (_) {
    if (context.mounted) {
      showAppSnackBar(
          context, 'No se pudo eliminar la cuenta. Revisa tu conexión.',
          isError: true);
    }
  }
}

/// Se pregunta una sola vez. Después se cambia en Ajustes.
Future<void> askAnalyticsConsentIfNeeded(BuildContext context) async {
  final data = AppDataScope.read(context);
  if (await data.settings.analyticsAllowed() != null || !context.mounted) {
    return;
  }

  final allowed = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => const _AnalyticsSheet(),
  );
  await setAnalyticsAllowed(data, allowed == true);
}

Future<void> setAnalyticsAllowed(AppData data, bool allowed) async {
  await data.settings.setAnalyticsAllowed(allowed);
  await Analytics.instance.setEnabled(allowed);
}

class _AnalyticsSheet extends StatelessWidget {
  const _AnalyticsSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.insights_outlined, size: 40, color: p.primary),
            const SizedBox(height: AppSpacing.md),
            Text('¿Nos ayudas a mejorar Floria?',
                textAlign: TextAlign.center, style: t.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Podemos recibir datos de uso anónimos, como cuántas sesiones se '
              'completan. Nunca enviamos tus tareas, tus objetivos ni las apps que usas. '
              'Puedes cambiarlo cuando quieras en Ajustes.',
              textAlign: TextAlign.center,
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, compartir'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, gracias'),
            ),
          ],
        ),
      ),
    );
  }
}
