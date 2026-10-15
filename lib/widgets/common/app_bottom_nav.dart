import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Barra de navegación inferior de la app.
/// Mantiene el mismo aspecto que la barra original de la pantalla "Nueva",
/// pero ahora cada ítem es presionable y avisa qué pestaña se eligió.
///
/// Índices: 0 = Tareas, 1 = Nueva, 2 = Enfoque, 3 = Historial
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavData> _items = [
    _NavData(Icons.check_circle_outline, 'Tareas'),
    _NavData(Icons.add_circle_outline, 'Nueva'),
    _NavData(Icons.adjust_outlined, 'Enfoque'),
    _NavData(Icons.show_chart_outlined, 'Historial'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F1F7), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  data: _items[i],
                  isSelected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData(this.icon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFECEEFD) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                data.icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
