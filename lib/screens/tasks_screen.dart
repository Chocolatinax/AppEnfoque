import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/ui_feedback.dart';
import '../widgets/common/enfoque_app_bar.dart';
import 'main_shell.dart';

/// Datos de ejemplo para mostrar la lista mientras no hay persistencia.
class _DemoTask {
  final String title;
  final String goal;
  final String priority; // 'alta' | 'media' | 'baja'
  final String duration;
  final String schedule;
  final bool hasDeadlineFlag;
  final IconData actionIcon;
  bool done = false;

  _DemoTask({
    required this.title,
    required this.goal,
    required this.priority,
    required this.duration,
    required this.schedule,
    required this.actionIcon,
    this.hasDeadlineFlag = false,
  });
}

/// Pantalla 2 del flujo: Tareas (inicio de la app).
class TasksScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenProfile;

  const TasksScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenProfile,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // ---------- Pomodoro rápido ----------
  static const int _pomodoroSeconds = 25 * 60;
  int _secondsLeft = _pomodoroSeconds;
  Timer? _timer;
  bool _isRunning = false;

  // ---------- Filtros y tareas ----------
  String _filter = 'todas';

  final List<_DemoTask> _tasks = [
    _DemoTask(
      title: 'Preparar presentación del proyecto',
      goal: 'Objetivo: Dejar listos los slides 1 al 10 sin distracciones',
      priority: 'alta',
      duration: '45 min',
      schedule: '14:00',
      hasDeadlineFlag: true,
      actionIcon: Icons.play_arrow_rounded,
    ),
    _DemoTask(
      title: 'Reunión con el equipo de diseño',
      goal: 'Objetivo: Revisar prototipo de UI',
      priority: 'media',
      duration: '30 min',
      schedule: '15:30 - 16:30',
      actionIcon: Icons.calendar_today_outlined,
    ),
    _DemoTask(
      title: 'Revisar correos pendientes',
      goal: 'Bandeja de entrada secundaria',
      priority: 'baja',
      duration: '20 min',
      schedule: 'Sin límite',
      actionIcon: Icons.edit_outlined,
    ),
  ];

  List<_DemoTask> get _visibleTasks => _filter == 'todas'
      ? _tasks
      : _tasks.where((t) => t.priority == _filter).toList();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    // Si ya terminó, el botón reinicia el temporizador.
    if (_secondsLeft == 0) {
      setState(() => _secondsLeft = _pomodoroSeconds);
      return;
    }

    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        if (_secondsLeft == 0) {
          timer.cancel();
          _isRunning = false;
        }
      });
    });
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------- Saludo y fecha en español ----------
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días, Usuario!';
    if (h < 19) return '¡Buenas tardes, Usuario!';
    return '¡Buenas noches, Usuario!';
  }

  IconData get _greetingIcon {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_sunny_outlined;
    if (h < 19) return Icons.wb_twilight;
    return Icons.nightlight_outlined;
  }

  String get _todayText {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} de ${_months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: EnfoqueAppBar(title: 'Tareas', onAvatarTap: widget.onOpenProfile),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.onNavigate(MainShell.tabNueva),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Nueva tarea',
        child: const Icon(Icons.add, size: 28),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 24),
            _buildQuickCards(),
            const SizedBox(height: 24),
            _buildTasksHeader(),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 12),
            ..._visibleTasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTaskCard(t),
              ),
            ),
            if (_visibleTasks.isEmpty) _buildEmptyFilter(),
            const SizedBox(height: 16),
            _buildEcoCard(),
            const SizedBox(height: 16),
            _buildQuoteCard(),
          ],
        ),
      ),
    );
  }

  // ---------- Secciones ----------

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greeting,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.secondaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(_greetingIcon, size: 18, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_todayText,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.onSurfaceVariant)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: AppColors.outlineVariant, shape: BoxShape.circle),
            ),
            const Text(
              'Modo Offline activo',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildPomodoroCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildBlockCard()),
        ],
      ),
    );
  }

  Widget _buildPomodoroCard() {
    final finished = _secondsLeft == 0;
    final paused = !_isRunning && _secondsLeft < _pomodoroSeconds && !finished;

    String label = 'Iniciar Enfoque';
    IconData icon = Icons.play_arrow_rounded;
    if (_isRunning) {
      label = 'Pausar';
      icon = Icons.pause_rounded;
    } else if (finished) {
      label = '¡Completado!';
      icon = Icons.replay_rounded;
    } else if (paused) {
      label = 'Reanudar';
    }

    return _QuickCard(
      leadingIcon: Icons.timer_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x99E2DFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'POMODORO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timerText,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: AppColors.onSurface,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text('Sesión rápida',
              style:
                  TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
      button: _SmallButton(
        label: label,
        icon: icon,
        background: _isRunning ? AppColors.tertiary : AppColors.primary,
        foreground: Colors.white,
        onTap: _toggleTimer,
      ),
    );
  }

  Widget _buildBlockCard() {
    return _QuickCard(
      leadingIcon: Icons.do_not_disturb_on_outlined,
      trailing: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bloqueo Activo',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface),
          ),
          SizedBox(height: 2),
          Text(
            '3 apps bloqueadas (Instagram, TikTok, YT)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      button: _SmallButton(
        label: 'Configurar',
        icon: Icons.tune,
        background: AppColors.surfaceContainer,
        foreground: AppColors.primary,
        onTap: () => showComingSoon(context, 'La configuración de bloqueo'),
      ),
    );
  }

  Widget _buildTasksHeader() {
    return Row(
      children: [
        const Text(
          'Tareas para hoy',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${_visibleTasks.length}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () =>
              showComingSoon(context, 'La lista completa de tareas'),
          child: const Text(
            'Ver todas',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = {
      'todas': 'Todas',
      'alta': 'Alta',
      'media': 'Media',
      'baja': 'Baja'
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _filter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _filter = entry.key),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color:
                          selected ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(_DemoTask task) {
    final (chipBg, chipFg, chipLabel) = switch (task.priority) {
      'alta' => (AppColors.tertiaryFixed, AppColors.tertiary, 'Alta prioridad'),
      'media' => (
          AppColors.secondaryFixed,
          AppColors.onSecondaryFixedVariant,
          'Media prioridad'
        ),
      _ => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
          'Baja prioridad'
        ),
    };
    final isPlay = task.actionIcon == Icons.play_arrow_rounded;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: task.done ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox personalizado
                InkWell(
                  onTap: () => setState(() => task.done = !task.done),
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: task.done
                          ? AppColors.primary
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: task.done
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: task.done
                              ? AppColors.outline
                              : AppColors.onSurface,
                          decoration:
                              task.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.goal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: isPlay
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainer,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _onTaskAction(task),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        task.actionIcon,
                        size: 18,
                        color: isPlay
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: chipBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: chipFg),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.schedule,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(task.duration,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
                const Spacer(),
                if (task.hasDeadlineFlag) ...[
                  const Icon(Icons.flag_outlined,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 3),
                ],
                Text(task.schedule,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTaskAction(_DemoTask task) {
    if (task.actionIcon == Icons.play_arrow_rounded) {
      widget.onNavigate(MainShell.tabEnfoque);
    } else if (task.actionIcon == Icons.edit_outlined) {
      widget.onNavigate(MainShell.tabNueva);
    } else {
      showComingSoon(context, 'Agregar al calendario');
    }
  }

  Widget _buildEmptyFilter() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'No hay tareas con esta prioridad',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildEcoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Icons.eco_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTUDIO SOSTENIBLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Planta árboles mientras estudias',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Cada sesión de enfoque completada contribuye a reforestar áreas protegidas '
            'locales en modo offline sincronizable.',
            style: TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.park_outlined,
                  iconColor: AppColors.primary,
                  value: '12',
                  label: 'Árboles plantados',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.hourglass_bottom,
                  iconColor: AppColors.secondary,
                  value: '6.5h',
                  label: 'Enfoque completado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.format_quote, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '"El éxito no es la meta final, sino el camino que recorres cada día con pasión y propósito."',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets pequeños reutilizables de esta pantalla ----------

class _QuickCard extends StatelessWidget {
  final IconData leadingIcon;
  final Widget trailing;
  final Widget body;
  final Widget button;

  const _QuickCard({
    required this.leadingIcon,
    required this.trailing,
    required this.body,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F4648D4), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(leadingIcon, size: 17, color: AppColors.primary),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          body,
          const Spacer(),
          const SizedBox(height: 12),
          button,
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
