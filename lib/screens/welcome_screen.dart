import 'package:flutter/material.dart';
import 'legal_screen.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'main_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(document: document)),
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
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/branding/floria_isotipo_claro.png'
                        : 'assets/branding/floria_isotipo_verde.png',
                    width: 112,
                    height: 112,
                    semanticLabel: 'Logo de Floria',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Floria',
                      style: t.headlineMedium!.copyWith(fontSize: 34)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Concéntrate en una tarea a la vez, sin distracciones.',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge!.copyWith(color: p.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openLegal(context, LegalDocument.terms),
                        child: const Text('Términos',
                            style: TextStyle(fontSize: 13)),
                      ),
                      Text('·', style: TextStyle(color: p.onSurfaceVariant)),
                      TextButton(
                        onPressed: () =>
                            _openLegal(context, LegalDocument.privacy),
                        child: const Text('Privacidad',
                            style: TextStyle(fontSize: 13)),
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

  const _Benefit(
      {required this.icon, required this.title, required this.subtitle});

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
                  Text(subtitle,
                      style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
