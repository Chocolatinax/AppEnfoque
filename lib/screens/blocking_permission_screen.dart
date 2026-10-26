import 'package:flutter/material.dart';
import '../services/app_blocker.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';

/// Explica y activa el permiso de bloqueo (Servicio de Accesibilidad de Android).
///
/// Se abre desde Ajustes → Permisos de bloqueo, o al iniciar una sesión sin el
/// permiso activado ([fromSession] = true). En ese caso, cuando el permiso queda
/// activo aparece "Continuar con la sesión", que devuelve `true`.
class BlockingPermissionScreen extends StatefulWidget {
  final bool fromSession;

  const BlockingPermissionScreen({super.key, this.fromSession = false});

  @override
  State<BlockingPermissionScreen> createState() =>
      _BlockingPermissionScreenState();
}

class _BlockingPermissionScreenState extends State<BlockingPermissionScreen>
    with WidgetsBindingObserver {
  final _blocker = AppBlocker.instance;
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes de Android, revisar si ya se activó
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await _blocker.isEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos de bloqueo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
            AppSpacing.screen, AppSpacing.xxl),
        children: [
          if (!_blocker.isSupported)
            _StatusCard(
              icon: Icons.phone_iphone,
              color: p.surfaceContainerLow,
              foreground: p.onSurface,
              title: 'Disponible en Android',
              body: 'El bloqueo de apps funciona en teléfonos Android. '
                  'En iPhone llegará en una próxima versión.',
            )
          else if (_enabled == null)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator()))
          else if (_enabled!)
            _StatusCard(
              icon: Icons.check_circle_outline,
              color: p.primaryFixed,
              foreground: p.onPrimaryFixed,
              title: 'Bloqueo activado',
              body:
                  'Durante tus sesiones, Floria te avisará si abres una de las apps que elegiste bloquear.',
            )
          else
            _StatusCard(
              icon: Icons.shield_outlined,
              color: p.tertiaryFixed,
              foreground: p.onTertiaryFixed,
              title: 'Bloqueo desactivado',
              body:
                  'Para bloquear apps, Android necesita que actives a Floria en Accesibilidad.',
            ),
          if (_blocker.isSupported && _enabled == false) ...[
            const SizedBox(height: AppSpacing.xl),
            Semantics(
                header: true,
                child: Text('Cómo activarlo', style: t.titleMedium)),
            const SizedBox(height: AppSpacing.md),
            const _Step(
                number: 1, text: 'Toca "Abrir ajustes de Accesibilidad".'),
            const _Step(
                number: 2,
                text:
                    'Busca "Floria: bloqueo de distracciones" (puede estar en "Apps instaladas" o "Servicios descargados").'),
            const _Step(
                number: 3, text: 'Actívalo, confirma y vuelve a Floria.'),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _blocker.openSettings,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Abrir ajustes de Accesibilidad'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¿No te deja activarlo? En Android 13 o más nuevo, abre Ajustes → Apps → Floria, '
              'toca el menú ⋮ y elige "Permitir ajustes restringidos". Luego inténtalo de nuevo.',
              style: t.bodySmall,
            ),
          ],
          if (widget.fromSession && _enabled == true) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar con la sesión'),
              ),
            ),
          ],
          if (_blocker.isSupported) ...[
            const SizedBox(height: AppSpacing.xxl),
            Semantics(
                header: true,
                child: Text('Tu privacidad', style: t.titleMedium)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Floria solo usa este permiso para saber qué app abres mientras tienes una sesión activa. '
              'No lee el contenido de tus pantallas, no guarda qué apps usas y no envía nada a internet.',
              style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color foreground;
  final String title;
  final String body;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: color,
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: t.titleMedium!.copyWith(color: foreground)),
                  const SizedBox(height: 2),
                  Text(body, style: t.bodyMedium!.copyWith(color: foreground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: p.primaryFixed,
              child: Text('$number',
                  style: t.labelMedium!.copyWith(color: p.onPrimaryFixed)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: t.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
