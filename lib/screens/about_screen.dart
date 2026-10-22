import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';

/// Acerca de Floria: versión, equipo y "Próximamente en Floria".
///
/// "Próximamente" muestra la visión del producto: son las funciones que la
/// ficha del proyecto declara FUERA de alcance para esta versión
/// ("no eliminadas del concepto de negocio"). Es solo informativo, no hay botones.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _team = [
    'Alejandra Arriola',
    'Alisson Quijano',
    'Gabriel Martínez',
    'Christian Renderos',
    'Melisa Rivas',
  ];

  static const _upcoming = [
    (Icons.local_florist_outlined, 'Un jardín que crece con tus sesiones', 'Cada sesión completada hará crecer tu jardín.'),
    (Icons.cloud_outlined, 'Respaldo en la nube', 'Usa Floria en varios dispositivos sin perder tu historial.'),
    (Icons.group_outlined, 'Sesiones acompañadas', 'Enfócate al mismo tiempo que tus amigos.'),
    (Icons.auto_awesome_outlined, 'Asistente para dividir tareas', 'Convierte una tarea grande en varias sesiones.'),
    (Icons.headphones_outlined, 'Música ambiental', 'Sonidos para acompañar tu concentración.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Floria')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xxl),
        children: [
          Center(
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/branding/floria_isotipo_claro.png'
                  : 'assets/branding/floria_isotipo_verde.png',
              width: 88,
              height: 88,
              semanticLabel: 'Logo de Floria',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Floria', textAlign: TextAlign.center, style: t.headlineSmall),
          Text('Versión 1.0', textAlign: TextAlign.center, style: t.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Floria ayuda a estudiantes a concentrarse en una tarea a la vez, '
            'bloqueando las apps que los distraen. Funciona sin cuenta y sin internet.',
            textAlign: TextAlign.center,
            style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant),
          ),

          const SizedBox(height: AppSpacing.xxl),
          Semantics(header: true, child: Text('Próximamente en Floria', style: t.titleLarge)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ideas que forman parte de nuestra visión, pero no de esta versión.',
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                for (final (icon, title, subtitle) in _upcoming)
                  ListTile(
                    leading: Icon(icon, color: p.secondary),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(subtitle, style: TextStyle(color: p.onSurfaceVariant)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          Semantics(header: true, child: Text('Hecha por el Grupo 6', style: t.titleLarge)),
          const SizedBox(height: AppSpacing.sm),
          Text(_team.join(' · '), style: t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text('ESEN · 2026', style: t.bodySmall),
        ],
      ),
    );
  }
}
