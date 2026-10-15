import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/ui_feedback.dart';

/// Pantalla de Sesión Activa (enfoque en curso).
/// Se abre al presionar "Guardar e Iniciar Enfoque" en el formulario.
///
/// Reglas de esta pantalla:
/// - No hay botón de "volver": mientras la sesión corre, la única salida es
///   terminar el tiempo o abandonar la sesión (que se registra como fallida).
/// - El usuario puede tomar una pausa de emergencia de 2 minutos.
class ActiveSessionScreen extends StatefulWidget {
  final Task task;

  const ActiveSessionScreen({super.key, required this.task});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with SingleTickerProviderStateMixin {
  static const int _pauseSeconds = 2 * 60;

  late int _secondsLeft = widget.task.durationMinutes * 60;
  int _pauseSecondsLeft = 0;
  Timer? _timer;
  bool _finished = false;

  late final AnimationController _breathController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  bool get _isPaused => _pauseSecondsLeft > 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _finished) return;
    setState(() {
      if (_isPaused) {
        // Durante la pausa el bloque de enfoque se detiene
        _pauseSecondsLeft--;
        if (_pauseSecondsLeft == 0) {
          showAppSnackBar(context, 'Pausa terminada. ¡De vuelta al enfoque!');
        }
        return;
      }
      if (_secondsLeft > 0) _secondsLeft--;
      if (_secondsLeft == 0) {
        _finished = true;
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) => _showCompletedDialog());
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _pauseSecondsLeft = 0; // Reanudar antes de que acabe la pausa
      } else {
        _pauseSecondsLeft = _pauseSeconds;
      }
    });
  }

  Future<void> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Abandonar sesión?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          '¿Seguro que deseas rendirte? Esta sesión se registrará como fallida y tu árbol en crecimiento se marchitará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir enfocado'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abandonar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _timer?.cancel();
    showAppSnackBar(
      context,
      'Sesión registrada como fallida',
      icon: Icons.cancel_outlined,
      backgroundColor: AppColors.error,
    );
    Navigator.of(context).pop();
  }

  Future<void> _showCompletedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 36),
        title: const Text('¡Sesión completada!', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Terminaste ${widget.task.durationMinutes} minutos de enfoque en "${widget.task.title}".',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terminar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _format(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // PopScope bloquea el botón "atrás" del sistema mientras la sesión está activa.
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showAppSnackBar(
            context,
            'Tu sesión sigue activa. Usa la pausa o abandona la sesión.',
            icon: Icons.lock_outline,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Sin botón de volver
          titleSpacing: 20,
          title: const Text(
            'Sesión Activa',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_outline, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBreathingHeader(),
              const SizedBox(height: 20),
              _buildCountdownCard(),
              const SizedBox(height: 16),
              _buildCommitmentCard(),
              const SizedBox(height: 16),
              _buildFrictionCard(),
              const SizedBox(height: 20),
              _buildPauseButton(),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _confirmAbandon,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Abandonar sesión (Registrará sesión fallida)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Secciones ----------

  Widget _buildBreathingHeader() {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Aura que "respira" (crece y se encoge lentamente)
              ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0x40E2DFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: Color(0x80E1E0FF),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x333525CD), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.spa, color: Colors.white, size: 34),
              ),
              Positioned(
                right: 26,
                bottom: 22,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isPaused ? 'Pausa de emergencia' : '¡Respira profundo!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isPaused
              ? 'Tu bloque está detenido. Volverás al enfoque en ${_format(_pauseSecondsLeft)}.'
              : 'Tienes una sesión de enfoque activa en este momento.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCountdownCard() {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hourglass_top, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIEMPO RESTANTE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _format(_secondsLeft),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                        color: _isPaused ? AppColors.outline : AppColors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'de tu bloque',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isPaused ? AppColors.tertiaryFixed : AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isPaused ? AppColors.tertiary : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPaused ? 'En pausa' : 'En curso',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isPaused ? AppColors.tertiary : AppColors.onSecondaryFixedVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('Pomodoro #1', style: TextStyle(fontSize: 12, color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentCard() {
    final (chipBg, chipFg) = switch (widget.task.priority) {
      'Alta' => (AppColors.errorContainer, const Color(0xFF93000A)),
      'Media' => (AppColors.secondaryFixed, AppColors.onSecondaryFixedVariant),
      _ => (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant),
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'TU COMPROMISO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  '${widget.task.priority} prioridad',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: chipFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '“${widget.task.goal}”',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.35,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.task_alt, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tarea vinculada',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      widget.task.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrictionCard() {
    final apps = widget.task.blockedApps;
    final appName = apps.isNotEmpty ? apps.first : 'otra app';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_alt, color: AppColors.secondary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '¿Realmente necesitas abrir $appName ahora? Esta pausa romperá tu racha '
              'de concentración y retrasará tu descanso.',
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return Material(
      color: _isPaused ? AppColors.primary : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _togglePause,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                size: 20,
                color: _isPaused ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isPaused
                      ? 'Reanudar ahora (${_format(_pauseSecondsLeft)})'
                      : 'Pausa de emergencia de 2 minutos',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isPaused ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
