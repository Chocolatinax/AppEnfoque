import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../data/task_repository.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../utils/ui_feedback.dart';
import '../widgets/common/app_card.dart';
import '../services/notification_service.dart';
import 'about_screen.dart';
import 'legal_screen.dart';
import 'blocking_permission_screen.dart';
import 'welcome_screen.dart';

/// Ajustes de la app (antes "Perfil de invitado").
/// Floria no tiene cuentas: aquí solo hay permisos, datos locales e información.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reiniciar tus datos?'),
        content: const Text(
          'Se borrarán las tareas, sesiones e historial guardados en este teléfono. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: p.error),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Borra las tareas y sesiones de SQLite
    await SessionScope.read(context)?.clearAll();
    if (!context.mounted) return;
    await TaskScope.read(context)?.clearAll();
    if (!context.mounted) return;

    showAppSnackBar(context, 'Datos borrados de este teléfono');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
            AppSpacing.screen, AppSpacing.xxl),
        children: [
          // Aviso de privacidad local
          AppCard(
            color: p.primaryFixed,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smartphone_outlined, color: p.onPrimaryFixed),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tus datos viven en este teléfono',
                          style:
                              t.titleMedium!.copyWith(color: p.onPrimaryFixed)),
                      const SizedBox(height: 2),
                      Text(
                        'Floria funciona sin cuenta y sin internet. Nadie más puede ver tus tareas ni tu historial.',
                        style: t.bodyMedium!.copyWith(color: p.onPrimaryFixed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const _SectionLabel('Sesiones de enfoque'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Permisos de bloqueo',
              subtitle: 'Necesarios para bloquear apps durante la sesión',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const BlockingPermissionScreen()),
              ),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              subtitle: 'Avisos al iniciar y terminar una sesión',
              onTap: () async {
                final granted =
                    await NotificationService.instance.requestPermission();
                if (!context.mounted) return;
                showAppSnackBar(
                  context,
                  granted
                      ? 'Las notificaciones están activadas'
                      : 'Actívalas en los ajustes del teléfono: Apps → Floria → Notificaciones',
                  icon: granted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                );
              },
            ),
            // Solo Android: en iOS los avisos ya llegan a la hora exacta
            if (NotificationService.instance.supportsExactAlarms)
              const _ExactAlarmTile(),
          ]),

          const _SectionLabel('Tus datos'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Reiniciar datos',
              subtitle: 'Borra todo lo guardado en este teléfono',
              destructive: true,
              onTap: () => _confirmReset(context),
            ),
          ]),

          const _SectionLabel('Floria'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Acerca de Floria',
              subtitle: 'Versión, equipo y lo que viene',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Términos de uso',
              subtitle: 'Las reglas para usar Floria',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const LegalScreen(document: LegalDocument.terms)),
              ),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Política de privacidad',
              subtitle: 'Qué se guarda y para qué sirve cada permiso',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const LegalScreen(document: LegalDocument.privacy)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpacing.xl, 4, AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) divided.add(const Divider(indent: 56));
      divided.add(children[i]);
    }
    return AppCard(padding: EdgeInsets.zero, child: Column(children: divided));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = destructive ? p.error : p.onSurface;

    return ListTile(
      onTap: onTap,
      minVerticalPadding: 12,
      leading: Icon(icon, color: destructive ? p.error : p.onSurfaceVariant),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(subtitle, style: TextStyle(color: p.onSurfaceVariant)),
      trailing: destructive
          ? null
          : Icon(Icons.chevron_right, color: p.onSurfaceVariant),
    );
  }
}

/// "Avisos a tiempo": muestra si el permiso de alarmas exactas está activo y permite activarlo.
class _ExactAlarmTile extends StatefulWidget {
  const _ExactAlarmTile();

  @override
  State<_ExactAlarmTile> createState() => _ExactAlarmTileState();
}

class _ExactAlarmTileState extends State<_ExactAlarmTile>
    with WidgetsBindingObserver {
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

  // Al volver de los ajustes de Android, actualizar el estado
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await NotificationService.instance.canScheduleExact();
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _onTap() async {
    if (_enabled == true) {
      showAppSnackBar(context, 'Tus avisos ya llegan a tiempo',
          icon: Icons.alarm_on_outlined);
      return;
    }
    await NotificationService.instance.requestExactAlarms();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.alarm_on_outlined,
      title: 'Avisos a tiempo',
      subtitle: switch (_enabled) {
        null => 'Revisando…',
        true => 'Activado: los avisos llegan a la hora exacta',
        false =>
          'Desactivado: los avisos pueden llegar unos minutos tarde. Toca para activarlo',
      },
      onTap: _onTap,
    );
  }
}
