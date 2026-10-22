import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'main_shell.dart';

/// Pantalla de bienvenida.
/// Minimalista: logo, una frase, tres beneficios y un solo botón "Empezar".
/// (Sin login: la app es de uso individual, sin registro y 100% offline.)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showLegalSheet(BuildContext context, String title) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Floria funciona sin cuenta y sin conexión. Tus tareas, sesiones e '
                'historial se guardan únicamente en este dispositivo. El texto legal '
                'completo se agregará más adelante.',
                style: Theme.of(ctx).textTheme.bodyMedium!.copyWith(color: p.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/branding/floria_isotipo_claro.png'
                          : 'assets/branding/floria_isotipo_verde.png',
                      width: 112,
                      height: 112,
                      semanticLabel: 'Logo de Floria',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Floria', style: t.headlineMedium!.copyWith(fontSize: 34)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Concéntrate en una tarea a la vez, sin distracciones.',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge!.copyWith(color: p.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),

                  // Beneficios (lista simple, sin tarjetas)
                  const _Benefit(
                    icon: Icons.block_outlined,
                    title: 'Bloquea las apps que te distraen',
                    subtitle: 'Mientras dura tu sesión de enfoque.',
                  ),
                  const _Benefit(
                    icon: Icons.flag_outlined,
                    title: 'Una meta clara por sesión',
                    subtitle: 'Declara qué quieres lograr antes de empezar.',
                  ),
                  const _Benefit(
                    icon: Icons.wifi_off_rounded,
                    title: 'Sin cuenta y sin internet',
                    subtitle: 'Todo se guarda solo en tu teléfono.',
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _start(context),
                      child: const Text('Empezar'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Pie: enlaces legales
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showLegalSheet(context, 'Términos de servicio'),
                        child: const Text('Términos', style: TextStyle(fontSize: 13)),
                      ),
                      Text('·', style: TextStyle(color: p.onSurfaceVariant)),
                      TextButton(
                        onPressed: () => _showLegalSheet(context, 'Política de privacidad'),
                        child: const Text('Privacidad', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: p.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
