import 'package:flutter/material.dart';
import 'legal_screen.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'account_flow.dart';
import 'main_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _signingIn = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _signingIn = true);
    final ok = await signInWithGoogleFlow(context);
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (ok) _start(context);
  }

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
        // Cabe completa en un teléfono normal; con letra muy grande se puede deslizar
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/branding/floria_isotipo_claro.png'
                            : 'assets/branding/floria_isotipo_verde.png',
                        width: 80,
                        height: 80,
                        semanticLabel: 'Logo de Floria',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Floria',
                          style: t.headlineMedium!.copyWith(fontSize: 32)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Concéntrate en una tarea a la vez, sin distracciones.',
                        textAlign: TextAlign.center,
                        style:
                            t.bodyLarge!.copyWith(color: p.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
                        icon: Icons.cloud_outlined,
                        title: 'Con o sin cuenta',
                        subtitle: 'Respalda tus tareas con Google o guárdalas solo en tu teléfono.',
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _signingIn ? null : _continueWithGoogle,
                          icon: _signingIn
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.account_circle_outlined),
                          label: const Text('Continuar con Google'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              _signingIn ? null : () => _start(context),
                          child: const Text('Continuar sin cuenta'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                          Text('·',
                              style: TextStyle(color: p.onSurfaceVariant)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
