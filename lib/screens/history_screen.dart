import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/ui_feedback.dart';
import '../widgets/common/enfoque_app_bar.dart';

/// Pantalla 4 del flujo: Historial / estadísticas semanales.
/// Por ahora usa datos de ejemplo; más adelante se conectará al almacenamiento local.
class HistoryScreen extends StatefulWidget {
  final VoidCallback onOpenProfile;

  const HistoryScreen({super.key, required this.onOpenProfile});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _weekOffset = 0; // 0 = semana actual, -1 = semana anterior, etc.
  int _selectedDay = 2; // Miércoles (día pico en los datos de ejemplo)
  bool _onlyWithGoal = false;

  // Horas de enfoque por día (L a D) — datos de ejemplo
  static const List<double> _hours = [2.0, 2.5, 3.5, 1.8, 2.7, 1.5, 0.5];
  static const List<String> _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const double _maxHours = 3.5;
  static const double _goalHours = 2.0;

  static const _monthsShort = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static const List<_Session> _sessions = [
    _Session(
      title: 'Ejercicios de Cálculo Diferencial',
      meta: '45 min • Mié 10:45 AM',
      tag: '#Estudio',
      tagBg: AppColors.primaryFixed,
      tagFg: AppColors.primary,
      result: 'Objetivo cumplido: 5 problemas',
      hasGoal: true,
    ),
    _Session(
      title: 'Preparar presentación de proyecto',
      meta: '50 min • Mié 08:30 AM',
      tag: '#Proyecto',
      tagBg: AppColors.secondaryFixed,
      tagFg: AppColors.secondary,
      result: 'Objetivo cumplido: Diapos 1-8',
      hasGoal: true,
    ),
    _Session(
      title: 'Revisar correos y notas pendientes',
      meta: '20 min • Mar 05:15 PM',
      tag: '#Informe',
      tagBg: AppColors.tertiaryFixed,
      tagFg: AppColors.tertiary,
      result: 'Sesión completada',
      hasGoal: false,
    ),
  ];

  // ---------- Cálculo del rango de la semana ----------
  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: 7 * _weekOffset));
  }

  String get _weekLabel {
    final start = _weekStart;
    final end = start.add(const Duration(days: 6));
    final range = start.month == end.month
        ? '${start.day} - ${end.day} ${_monthsShort[end.month - 1]}'
        : '${start.day} ${_monthsShort[start.month - 1]} - ${end.day} ${_monthsShort[end.month - 1]}';
    if (_weekOffset == 0) return 'Semana actual ($range)';
    return 'Semana ($range)';
  }

  /// Número de semana ISO 8601.
  int get _weekNumber {
    final thursday = _weekStart.add(const Duration(days: 3));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart =
        firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    return 1 + thursday.difference(firstWeekStart).inDays ~/ 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar:
          EnfoqueAppBar(title: 'Historial', onAvatarTap: widget.onOpenProfile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekSelector(),
            const SizedBox(height: 16),
            _buildMotivation(),
            const SizedBox(height: 16),
            _buildKpiGrid(),
            const SizedBox(height: 16),
            _buildDailyChart(),
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 16),
            _buildRecentSessions(),
          ],
        ),
      ),
    );
  }

  // ---------- Secciones ----------

  Widget _buildWeekSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RoundIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Semana anterior',
              onTap: () => setState(() => _weekOffset--),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _weekLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface),
              ),
            ),
            const SizedBox(width: 4),
            _RoundIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Semana siguiente',
              // No se puede avanzar más allá de la semana actual
              onTap:
                  _weekOffset < 0 ? () => setState(() => _weekOffset++) : null,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Semana $_weekNumber',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumen de productividad y constancia',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildMotivation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Excelente ritmo semanal!',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                ),
                Text(
                  'Has superado tu tiempo de enfoque anterior por 2.2 horas.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.access_time,
                iconBg: Color(0x66E2DFFF),
                iconColor: AppColors.primary,
                badge: _Badge(
                    '+18%', AppColors.surfaceContainerHigh, AppColors.primary),
                value: '14.5 h',
                label: 'Tiempo total',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _KpiCard(
                icon: Icons.task_alt,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.secondary,
                trailingText: 'Meta: 20',
                value: '18',
                label: 'Sesiones hechas',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.track_changes,
                iconBg: Color(0x80E1E0FF),
                iconColor: AppColors.secondary,
                badge: _Badge(
                    'Logrado', AppColors.surfaceContainer, AppColors.onSurface),
                value: '92%',
                label: 'Cumplimiento',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _KpiCard(
                icon: Icons.local_fire_department_outlined,
                iconBg: Color(0x99FFD9E4),
                iconColor: AppColors.tertiary,
                badge: _Badge(
                    'Activa', AppColors.surfaceContainer, AppColors.tertiary),
                value: '5 días',
                label: 'Racha actual',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    const chartHeight = 128.0;
    const goalFraction = _goalHours / _maxHours;
    final avg = _hours.reduce((a, b) => a + b) / _hours.length;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actividad Diaria',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface),
                    ),
                    Text(
                      'Promedio: ${avg.toStringAsFixed(1)} h / día',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(width: 10, height: 2, color: AppColors.outlineVariant),
              const SizedBox(width: 4),
              const Text(
                'Meta: 2h',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: chartHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Línea punteada de la meta
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: chartHeight * goalFraction,
                  child: _DashedLine(color: AppColors.outlineVariant),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_hours.length,
                      (i) => Expanded(child: _buildBar(i, chartHeight))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              _dayLetters.length,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    _dayLetters[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          i == _selectedDay ? FontWeight.w800 : FontWeight.w600,
                      color: i == _selectedDay
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(int i, double chartHeight) {
    final selected = i == _selectedDay;
    final isWeekend = i >= 5;
    final barHeight = chartHeight * (_hours[i] / _maxHours);
    final color = selected
        ? AppColors.primary
        : (isWeekend
            ? AppColors.surfaceContainerHigh
            : AppColors.secondaryFixed);

    // Toda la columna es presionable para seleccionar el día.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedDay = i),
      child: SizedBox(
        height: chartHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            // Etiqueta con las horas sobre la barra seleccionada
            if (selected)
              Positioned(
                left: 0,
                right: 0,
                bottom: barHeight + 4,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_hours[i]} h',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Tiempo por Área de Enfoque',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                ),
              ),
              Text('3 categorías',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                      flex: 45, child: ColoredBox(color: AppColors.primary)),
                  Expanded(
                      flex: 31,
                      child: ColoredBox(color: AppColors.secondaryContainer)),
                  Expanded(
                      flex: 24,
                      child: ColoredBox(color: AppColors.tertiaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _CategoryRow(
            icon: Icons.menu_book_outlined,
            iconBg: AppColors.primaryFixed,
            iconColor: AppColors.primary,
            name: '#Estudio',
            percent: '45% del tiempo',
            hours: '6.5 h',
          ),
          const SizedBox(height: 8),
          const _CategoryRow(
            icon: Icons.desktop_windows_outlined,
            iconBg: AppColors.secondaryFixed,
            iconColor: AppColors.secondary,
            name: '#Proyecto',
            percent: '31% del tiempo',
            hours: '4.5 h',
          ),
          const SizedBox(height: 8),
          const _CategoryRow(
            icon: Icons.description_outlined,
            iconBg: AppColors.tertiaryFixed,
            iconColor: AppColors.tertiary,
            name: '#Informe',
            percent: '24% del tiempo',
            hours: '3.5 h',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    final sessions =
        _onlyWithGoal ? _sessions.where((s) => s.hasGoal).toList() : _sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sesiones Recientes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _SegmentChip(
                    label: 'Todas',
                    selected: !_onlyWithGoal,
                    onTap: () => setState(() => _onlyWithGoal = false),
                  ),
                  _SegmentChip(
                    label: 'Con objetivo',
                    selected: _onlyWithGoal,
                    onTap: () => setState(() => _onlyWithGoal = true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sessions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionCard(
              session: s,
              onTap: () => showComingSoon(context, 'El detalle de la sesión'),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Modelos y widgets auxiliares ----------

class _Session {
  final String title;
  final String meta;
  final String tag;
  final Color tagBg;
  final Color tagFg;
  final String result;
  final bool hasGoal;

  const _Session({
    required this.title,
    required this.meta,
    required this.tag,
    required this.tagBg,
    required this.tagFg,
    required this.result,
    required this.hasGoal,
  });
}

class _Badge {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge(this.text, this.bg, this.fg);
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundIconButton(
      {required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.onSurface : AppColors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final _Badge? badge;
  final String? trailingText;
  final String value;
  final String label;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.badge,
    this.trailingText,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: badge!.bg,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    badge!.text,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badge!.fg),
                  ),
                ),
              if (trailingText != null)
                Text(trailingText!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String name;
  final String percent;
  final String hours;

  const _CategoryRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.name,
    required this.percent,
    required this.hours,
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
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                ),
                Text(percent,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            hours,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? AppColors.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _Session session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final checkColor =
        session.hasGoal ? session.tagFg : AppColors.onSurfaceVariant;

    // Ink pinta el fondo sobre el Material para que el efecto de toque se vea encima.
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(session.meta,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: session.tagBg,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        session.tag,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: session.tagFg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 14, color: checkColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.result,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Línea horizontal punteada (para marcar la meta diaria en la gráfica).
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: color,
            ),
          ),
        );
      },
    );
  }
}
