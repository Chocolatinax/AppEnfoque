import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/ui_feedback.dart';
import 'welcome_screen.dart';

/// Pantalla 5 del flujo: Perfil de invitado.
/// Se abre desde el avatar del encabezado en cualquier pestaña.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ---------- Acciones ----------

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _InfoDialog(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Vincular Cuenta',
        message: 'Conexión no disponible en modo offline estricto. '
            'Conéctate a internet para respaldar.',
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showStorageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(
                  'Almacenamiento y datos locales',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined,
                    color: AppColors.primary),
                title: const Text('Exportar datos (JSON)'),
                subtitle:
                    const Text('Guarda una copia de tus tareas y sesiones'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnackBar(
                      context, 'Exportador de datos JSON preparado');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined,
                    color: AppColors.primary),
                title: const Text('Limpiar caché'),
                subtitle: const Text('Libera espacio sin borrar tus tareas'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnackBar(context, 'Caché limpiada correctamente');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _InfoDialog(
        icon: Icons.lock_outline,
        title: 'Privacidad y modo estricto',
        message:
            'Aquí podrás conceder los permisos de bloqueo de apps y activar '
            'el modo estricto. Se configurará en una siguiente versión.',
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _InfoDialog(
        icon: Icons.info_outline,
        title: 'Acerca de Enfoque',
        message:
            'Enfoque v1.0.0 (Offline Edition) — Motor de productividad local.\nBuild 104',
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Reiniciar datos?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          '¿Estás seguro de reiniciar todos los datos locales? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reiniciar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // TODO: borrar los datos reales cuando exista la persistencia local.
    showAppSnackBar(context, 'Datos locales vaciados correctamente');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Perfil De Invitado',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.onSurfaceVariant),
            onPressed: () => showAppSnackBar(
              context,
              'No tienes notificaciones nuevas',
              icon: Icons.notifications_none_rounded,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBadges(),
            const SizedBox(height: 16),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStorageCard(),
            const SizedBox(height: 16),
            _buildSyncCard(context),
            const SizedBox(height: 16),
            _buildSettingsList(context),
            const SizedBox(height: 16),
            _buildResetSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _pill(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.primary,
          text: 'Modo Offline Activo',
          bg: AppColors.surfaceContainerHigh,
          fg: AppColors.onSurfaceVariant,
        ),
        _pill(
          icon: Icons.shield_outlined,
          iconColor: AppColors.onSecondaryFixedVariant,
          text: '100% Privado',
          bg: AppColors.secondaryFixed,
          fg: AppColors.onSecondaryFixedVariant,
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return _Card(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    size: 42, color: AppColors.primary),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Usuario Invitado',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sesión local anónima • Sin cuenta vinculada',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ID Efímero: #LOC-8821',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return _Card(
      crossAxisAlignment: CrossAxisAlignment.start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.inbox_outlined, AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almacenamiento en Dispositivo',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface),
                    ),
                    Text(
                      'Datos resguardados en sandbox local',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tus tareas, sesiones y rachas se guardan únicamente en la memoria de este '
            'dispositivo (100% privado y offline).',
            style: TextStyle(
                fontSize: 14, height: 1.5, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.check_box_outlined,
                  iconColor: AppColors.primary,
                  value: '3',
                  label: 'Tareas locales',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.secondary,
                  value: '1',
                  label: 'Sesión activa',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Quieres sincronizar o hacer respaldo?',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Crea una cuenta en la nube para acceder a tus estadísticas en múltiples '
                      'dispositivos y evitar pérdidas al cambiar de teléfono.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _showSyncDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Crear cuenta o Iniciar sesión',
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.north_east_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.inbox_outlined,
              title: 'Almacenamiento y datos locales',
              subtitle: 'Exportar JSON o limpiar caché',
              onTap: () => _showStorageSheet(context),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacidad y modo estricto',
              subtitle: 'Permisos de bloqueo de apps locales',
              onTap: () => _showPrivacyDialog(context),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Acerca de Enfoque',
              subtitle: 'v1.0 (Offline Architecture)',
              badge: 'Build 104',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _confirmReset(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Reiniciar datos de invitado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const Text(
          'Eliminará las tareas y temporizadores almacenados en este teléfono.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

// ---------- Widgets auxiliares ----------

class _Card extends StatelessWidget {
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  const _Card(
      {required this.child,
      this.crossAxisAlignment = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: crossAxisAlignment == CrossAxisAlignment.center
          ? Alignment.center
          : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniMetric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.surface, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onClose;

  const _InfoDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Entendido',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
