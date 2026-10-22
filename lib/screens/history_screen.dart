import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../models/focus_session.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/enfoque_app_bar.dart';

/// Historial semanal construido con las sesiones guardadas en SQLite.
///
/// Muestra solo el progreso propio del usuario (los gráficos comparativos entre
/// usuarios están fuera de alcance según la ficha del proyecto).
class HistoryScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;

  const HistoryScreen({super.key, required this.onOpenSettings});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _weekOffset = 0; // 0 = esta semana, -1 = la anterior...
  int? _selectedDay; // 0 = lunes ... 6 = domingo
  String _filter = 'Todas';

  static const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _dayShort = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _monthsShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  DateTime get _weekStart {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day + 7 * _weekOffset);
  }

  String get _weekLabel {
    final start = _weekStart;
    final end = DateTime(start.year, start.month, start.day + 6);
    final range = start.month == end.month
        ? '${start.day} – ${end.day} ${_monthsShort[end.month - 1]}'
        : '${start.day} ${_monthsShort[start.month - 1]} – ${end.day} ${_monthsShort[end.month - 1]}';
    return _weekOffset == 0 ? 'Esta semana · $range' : range;
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static int _minutesOf(Iterable<FocusSession> sessions) =>
      sessions.fold<int>(0, (sum, s) => sum + s.focusSeconds) ~/ 60;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final repo = SessionScope.of(context);

    final start = _weekStart;
    final end = DateTime(start.year, start.month, start.day + 7);
    final prevStart = DateTime(start.year, start.month, start.day - 7);
    final week = repo.between(start, end);
    final prevWeek = repo.between(prevStart, start);

    final totalMinutes = _minutesOf(week);
    final completed = week.where((s) => s.isCompleted).length;

    return Scaffold(
      appBar: EnfoqueAppBar(title: 'Historial', onSettingsTap: widget.onOpenSettings),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
        children: [
          // Selector de semana
          Row(
            children: [
              IconButton(
                tooltip: 'Semana anterior',
                onPressed: () => setState(() {
                  _weekOffset--;
                  _selectedDay = null;
                }),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(child: Text(_weekLabel, textAlign: TextAlign.center, style: t.titleMedium)),
              IconButton(
                tooltip: 'Semana siguiente',
                onPressed: _weekOffset < 0
                    ? () => setState(() {
                          _weekOffset++;
                          _selectedDay = null;
                        })
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (week.isEmpty)
            _buildEmptyWeek(p, t)
          else ...[
            // Métricas principales (3)
            Row(
              children: [
                Expanded(child: _Metric(label: 'Enfoque', value: _formatMinutes(totalMinutes))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _Metric(label: 'Completadas', value: '$completed de ${week.length}')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _Metric(label: 'Racha', value: '${repo.currentStreak()} días')),
              ],
            ),
            if (_weekOffset == 0 && prevWeek.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildComparison(totalMinutes, _minutesOf(prevWeek), p, t),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildDailyChart(week, start, p, t),
            const SizedBox(height: AppSpacing.xl),
            _buildByTask(week, p, t),
            const SizedBox(height: AppSpacing.xl),
            _buildSessionList(week, p, t),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyWeek(AppPalette p, TextTheme t) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 40, color: p.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Aún no hay sesiones', style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _weekOffset == 0
                ? 'Cuando completes o abandones una sesión de enfoque, aparecerá aquí.'
                : 'No registraste sesiones esta semana.',
            textAlign: TextAlign.center,
            style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison(int now, int before, AppPalette p, TextTheme t) {
    final diff = now - before;
    final text = diff == 0
        ? 'Igual tiempo de enfoque que la semana pasada.'
        : diff > 0
            ? '${_formatMinutes(diff)} más de enfoque que la semana pasada.'
            : '${_formatMinutes(-diff)} menos de enfoque que la semana pasada.';
    return Row(
      children: [
        Icon(diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 18, color: p.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant))),
      ],
    );
  }

  Widget _buildDailyChart(List<FocusSession> week, DateTime start, AppPalette p, TextTheme t) {
    // Minutos de enfoque por día (lunes a domingo)
    final perDay = List<int>.filled(7, 0);
    for (final s in week) {
      final index = DateUtils.dateOnly(s.startedAt).difference(start).inDays;
      if (index >= 0 && index < 7) perDay[index] += s.focusSeconds;
    }
    for (var i = 0; i < 7; i++) {
      perDay[i] ~/= 60;
    }
    final maxMinutes = perDay.reduce((a, b) => a > b ? a : b).clamp(30, 100000);
    const chartHeight = 120.0;

    final summary = [
      for (var i = 0; i < 7; i++) '${_dayNames[i]}: ${_formatMinutes(perDay[i])}',
    ].join('. ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Enfoque por día', style: t.titleMedium)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              // El lector de pantalla lee el resumen en texto en vez de las barras
              Semantics(
                label: 'Gráfica de enfoque por día. $summary',
                excludeSemantics: true,
                child: SizedBox(
                  height: chartHeight + 44,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selectedDay = _selectedDay == i ? null : i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: perDay[i] == 0 ? 3 : chartHeight * perDay[i] / maxMinutes,
                                  decoration: BoxDecoration(
                                    color: _selectedDay == i
                                        ? p.primary
                                        : perDay[i] == 0
                                            ? p.surfaceContainerHigh
                                            : p.secondaryContainer,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dayLetters[i],
                                  style: t.labelSmall!.copyWith(
                                    color: _selectedDay == i ? p.primary : p.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _selectedDay == null
                    ? 'Toca un día para ver su tiempo de enfoque'
                    : '${_dayNames[_selectedDay!]}: ${_formatMinutes(perDay[_selectedDay!])}',
                style: t.bodyMedium!.copyWith(
                  color: _selectedDay == null ? p.onSurfaceVariant : p.onSurface,
                  fontWeight: _selectedDay == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildByTask(List<FocusSession> week, AppPalette p, TextTheme t) {
    final byTask = <String, int>{};
    for (final s in week) {
      byTask[s.taskTitle] = (byTask[s.taskTitle] ?? 0) + s.focusSeconds;
    }
    final entries = byTask.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(4).toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Tiempo por tarea', style: t.titleMedium)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              for (final e in top) ...[
                Row(
                  children: [
                    Expanded(child: Text(e.key, style: t.bodyMedium, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_formatMinutes(e.value ~/ 60), style: t.titleSmall),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : e.value / total,
                    minHeight: 8,
                    color: p.primary,
                    backgroundColor: p.surfaceContainerHigh,
                    semanticsLabel: e.key,
                    semanticsValue: '${total == 0 ? 0 : (e.value * 100 / total).round()} por ciento del tiempo',
                  ),
                ),
                if (e != top.last) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionList(List<FocusSession> week, AppPalette p, TextTheme t) {
    const filters = ['Todas', 'Completadas', 'Abandonadas'];
    final visible = switch (_filter) {
      'Completadas' => week.where((s) => s.isCompleted).toList(),
      'Abandonadas' => week.where((s) => !s.isCompleted).toList(),
      _ => week,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Sesiones', style: t.titleMedium)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final f in filters)
              ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                showCheckmark: false,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, color: _filter == f ? p.onPrimary : p.onSurface),
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          Text('No hay sesiones con este filtro.', style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
        for (final s in visible) ...[
          _SessionTile(session: s, dateText: _sessionDate(s.startedAt)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  String _sessionDate(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_dayShort[d.weekday - 1]} ${d.day} · $hh:$mm';
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: t.titleMedium, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FocusSession session;
  final String dateText;
  const _SessionTile({required this.session, required this.dateText});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final ok = session.isCompleted;
    final minutes = session.focusSeconds ~/ 60;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined, color: ok ? p.primary : p.tertiary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.taskTitle, style: t.titleSmall),
                  const SizedBox(height: 2),
                  Text('$dateText · $minutes min de enfoque', style: t.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    ok ? GoalResult.label(session.goalResult) : 'Abandonada',
                    style: t.bodySmall!.copyWith(
                      color: ok ? p.onSurface : p.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
