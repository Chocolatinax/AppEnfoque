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
import '../data/app_data.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import 'account_flow.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reiniciar tus datos?'),
        content: Text(
          AuthScope.read(context)?.isSignedIn == true
              ? 'Se borrarán las tareas, sesiones e historial guardados en tu cuenta. '
                  'Esta acción no se puede deshacer.'
              : 'Se borrarán las tareas, sesiones e historial guardados en este teléfono. '
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

    await SessionScope.read(context)?.clearAll();
    if (!context.mounted) return;
    await TaskScope.read(context)?.clearAll();
    if (!context.mounted) return;

    showAppSnackBar(context, 'Datos borrados');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context)?.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
            AppSpacing.screen, AppSpacing.xxl),
        children: [
          _SettingsGroup(children: [
            if (user == null)
              _SettingsTile(
                icon: Icons.account_circle_outlined,
                title: 'Iniciar sesión con Google',
                subtitle: 'Respalda tus tareas y úsalas en otro teléfono',
                onTap: () => signInWithGoogleFlow(context),
              )
            else
              _AccountTile(user: user),
          ]),
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
            if (NotificationService.instance.supportsExactAlarms)
              const _ExactAlarmTile(),
          ]),
          const _SectionLabel('Tus datos'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Reiniciar datos',
              subtitle: user == null
                  ? 'Borra todo lo guardado en este teléfono'
                  : 'Borra las tareas e historial de tu cuenta',
              destructive: true,
              onTap: () => _confirmReset(context),
            ),
            const _AnalyticsTile(),
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
          if (user != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _SettingsGroup(children: [
              _SettingsTile(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                subtitle: 'Tus datos quedan guardados en tu cuenta',
                onTap: () => signOutFlow(context),
              ),
              _SettingsTile(
                icon: Icons.person_remove_outlined,
                title: 'Eliminar mi cuenta',
                subtitle: 'Borra tu cuenta y los datos guardados en ella',
                destructive: true,
                onTap: () => deleteAccountFlow(context),
              ),
            ]),
          ],
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

class _AccountTile extends StatelessWidget {
  final AppUser user;
  const _AccountTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = (user.name?.isNotEmpty ?? false) ? user.name![0] : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.primaryFixed,
        foregroundImage:
            user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
        onForegroundImageError: user.photoUrl == null ? null : (_, __) {},
        child: Text(initial, style: TextStyle(color: p.onPrimaryFixed)),
      ),
      title: Text(user.name ?? 'Tu cuenta',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle:
          Text(user.email ?? '', style: TextStyle(color: p.onSurfaceVariant)),
    );
  }
}

class _AnalyticsTile extends StatefulWidget {
  const _AnalyticsTile();

  @override
  State<_AnalyticsTile> createState() => _AnalyticsTileState();
}

class _AnalyticsTileState extends State<_AnalyticsTile> {
  bool _allowed = Analytics.instance.enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SwitchListTile(
      secondary: Icon(Icons.insights_outlined, color: p.onSurfaceVariant),
      value: _allowed,
      onChanged: (value) async {
        setState(() => _allowed = value);
        await setAnalyticsAllowed(AppDataScope.read(context), value);
      },
      title: const Text('Compartir datos de uso anónimos',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Nunca incluye tus tareas ni las apps que usas',
          style: TextStyle(color: p.onSurfaceVariant)),
    );
  }
}
