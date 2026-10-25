import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/app_blocker.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';

/// Pantalla de recordatorio (requerimiento R1).
///
/// Aparece cuando el usuario abre una app bloqueada durante una sesión de enfoque.
/// Si mientras está abierta intenta abrir OTRA app bloqueada, se actualiza con el
/// nombre de la nueva ([event] cambia). Los minutos restantes se actualizan en vivo.
class BlockedAppReminderScreen extends StatefulWidget {
  final ValueListenable<BlockedAppEvent> event;
  final ValueListenable<int> secondsLeft;
  final String Function(String packageName) appNameFor;
  final String goal;

  const BlockedAppReminderScreen({
    super.key,
    required this.event,
    required this.secondsLeft,
    required this.appNameFor,
    required this.goal,
  });

  @override
  State<BlockedAppReminderScreen> createState() => _BlockedAppReminderScreenState();
}

class _BlockedAppReminderScreenState extends State<BlockedAppReminderScreen> {
  int? _latencyMs;

  @override
  void initState() {
    super.initState();
    widget.event.addListener(_measureLatency);
    _measureLatency();
  }

  @override
  void dispose() {
    widget.event.removeListener(_measureLatency);
    super.dispose();
  }

  /// Evidencia para R1: tiempo entre que se detectó la app y que se ve esta pantalla.
  void _measureLatency() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final event = widget.event.value;
      final ms = DateTime.now().difference(event.detectedAt).inMilliseconds;
      debugPrint('[R1] Recordatorio de ${widget.appNameFor(event.packageName)} mostrado en $ms ms (meta: < 2000 ms)');
      if (mounted && kDebugMode) setState(() => _latencyMs = ms);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: p.tertiaryFixed, shape: BoxShape.circle),
                  child: Icon(Icons.block_rounded, size: 48, color: p.onTertiaryFixed),
                ),
                const SizedBox(height: AppSpacing.xl),
                ValueListenableBuilder<BlockedAppEvent>(
                  valueListenable: widget.event,
                  builder: (context, event, _) => Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      '${widget.appNameFor(event.packageName)} está bloqueada',
                      textAlign: TextAlign.center,
                      style: t.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ValueListenableBuilder<int>(
                  valueListenable: widget.secondsLeft,
                  builder: (context, seconds, _) {
                    final minutes = (seconds / 60).ceil();
                    return Text(
                      'Estás en una sesión de enfoque. '
                      '${minutes <= 1 ? 'Te queda menos de un minuto' : 'Te quedan $minutes minutos'}.',
                      textAlign: TextAlign.center,
                      style: t.bodyLarge!.copyWith(color: p.onSurfaceVariant),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu objetivo', style: t.labelMedium!.copyWith(color: p.primary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.goal, style: t.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver a mi sesión'),
                  ),
                ),
                if (_latencyMs != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  // Solo en modo debug, como evidencia para las pruebas de R1
                  Text('Modo debug · mostrado en $_latencyMs ms', style: t.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
