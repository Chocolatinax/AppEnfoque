import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Encabezado compartido por las pestañas principales (Tareas, Enfoque, Historial).
/// Sigue el mismo estilo del encabezado de la pantalla "Nueva":
/// título grande + indicador "100% OFFLINE / LOCAL" + avatar del perfil.
class EnfoqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAvatarTap;

  const EnfoqueAppBar({
    super.key,
    required this.title,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      toolbarHeight: kToolbarHeight + 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '100% OFFLINE / LOCAL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: ProfileAvatarButton(onTap: onAvatarTap),
        ),
      ],
    );
  }
}

/// Avatar circular que abre el perfil de invitado.
class ProfileAvatarButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double radius;

  const ProfileAvatarButton({super.key, this.onTap, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Perfil',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, color: Colors.white, size: radius + 2),
        ),
      ),
    );
  }
}
