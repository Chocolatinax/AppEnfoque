import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';

class EnfoqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSettingsTap;

  const EnfoqueAppBar({
    super.key,
    required this.title,
    this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      toolbarHeight: kToolbarHeight + 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: p.onSurface, fontWeight: FontWeight.w800, fontSize: 24),
          ),
          Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 13, color: p.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Sin internet · datos en tu teléfono',
                style: TextStyle(
                    color: p.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SettingsButton(onTap: onSettingsTap),
        ),
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SettingsButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Ajustes',
      icon: Icon(Icons.settings_outlined,
          color: context.palette.onSurfaceVariant),
    );
  }
}
