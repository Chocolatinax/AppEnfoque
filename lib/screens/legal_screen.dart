import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';

enum LegalDocument { terms, privacy }

class _LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _LegalSection(this.title, this.paragraphs, [this.bullets = const []]);
}

class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  static const String lastUpdated = '25 de octubre de 2026';

  static const String contactEmail = '20245233@esen.edu.sv';

  String get _title => switch (document) {
        LegalDocument.terms => 'Términos de uso',
        LegalDocument.privacy => 'Política de privacidad',
      };

  String get _summary => switch (document) {
        LegalDocument.terms =>
          'Floria es una app gratuita para estudiar con enfoque. Úsala para ti, '
              'recuerda que tus datos solo existen en tu teléfono y que el bloqueo es una ayuda, '
              'no un control.',
        LegalDocument.privacy =>
          'Floria no recopila, no envía y no vende tus datos. No hay cuenta, anuncios ni '
              'analíticas. Todo lo que escribes se queda en tu teléfono.',
      };

  List<_LegalSection> get _sections => switch (document) {
        LegalDocument.terms => _terms,
        LegalDocument.privacy => _privacy,
      };

  static const _terms = [
    _LegalSection('1. Qué es Floria', [
      'Floria es una app para organizar tareas de estudio y hacer sesiones de enfoque, con '
          'temporizador, técnica Pomodoro, historial y bloqueo de apps que distraen.',
      'Es un proyecto académico del Grupo 6 de la ESEN (2026). Es gratuita y no tiene compras ni anuncios.',
    ]),
    _LegalSection('2. Aceptación', [
      'Al usar Floria aceptas estos términos. Si no estás de acuerdo, no uses la app y puedes desinstalarla en cualquier momento.',
    ]),
    _LegalSection('3. Uso de la app', [
      'Floria es para uso personal. No necesitas crear una cuenta ni conectarte a internet.',
    ], [
      'Usa la app para organizar tu estudio y tus sesiones de enfoque.',
      'No intentes modificar la app para dañar tu teléfono o el de otras personas.',
    ]),
    _LegalSection('4. Bloqueo de apps', [
      'El bloqueo es una ayuda para concentrarte, no un control parental: tú eliges qué apps bloquear '
          'y puedes dejar de usarlo cuando quieras.',
      'Solo está disponible en Android. En iPhone, el resto de la app funciona igual.',
    ]),
    _LegalSection('5. Tus datos', [
      'Nosotros no tenemos una copia de tus datos. Si desinstalas la app, reinicias tus datos o pierdes '
          'el teléfono, no los podremos recuperar.',
      'Para saber qué guarda Floria y para qué usa cada permiso, lee la Política de privacidad.',
    ]),
    _LegalSection('6. Sin garantías', [
      'Floria se ofrece "tal como está". Hacemos lo posible para que funcione bien, pero puede tener '
          'errores. No somos responsables por la pérdida de datos ni por los resultados de tus estudios.',
    ]),
    _LegalSection('7. Menores de edad', [
      'Floria está pensada para estudiantes desde los 15 años. Si eres menor de 18, úsala con el '
          'conocimiento de tu madre, padre o tutor.',
    ]),
    _LegalSection('8. Cambios', [
      'Podemos actualizar estos términos. Si lo hacemos, cambiará la fecha de "Última actualización".',
    ]),
    _LegalSection('9. Contacto', [
      'Si tienes dudas, escríbele al equipo de Floria (Grupo 6, ESEN) a $contactEmail.',
    ]),
  ];

  static const _privacy = [
    _LegalSection('1. Lo que se guarda en tu teléfono', [
      'Floria guarda en tu teléfono solo lo que necesita para funcionar:',
    ], [
      'Tus tareas: título, objetivo, duración, prioridad y las apps que elegiste bloquear.',
      'Tu historial: cuándo hiciste cada sesión, cuánto duró, si la completaste o la abandonaste y si cumpliste tu objetivo.',
      'La sesión en curso, para retomarla si cierras la app.',
    ]),
    _LegalSection('2. Lo que NO hacemos', [], [
      'No pedimos nombre, correo ni ningún dato para registrarte: no hay cuentas.',
      'No enviamos tus datos a internet. En Android, la app ni siquiera tiene permiso para usar internet.',
      'No usamos anuncios, analíticas ni rastreo.',
      'No vendemos ni compartimos tus datos con nadie.',
    ]),
    _LegalSection('3. Permisos y para qué sirven', [], [
      'Notificaciones: para avisarte que hay una sesión en curso y cuándo termina cada ronda, descanso o sesión.',
      'Accesibilidad (solo Android): para saber qué app abres durante una sesión de enfoque y mostrarte el '
          'recordatorio si es una de las que bloqueaste. Floria solo ve el nombre de la app; no lee lo que hay '
          'en tu pantalla y no guarda la lista de apps que abres. Puedes quitar este permiso cuando quieras '
          'en los ajustes del teléfono.',
      'Lista de apps instaladas (solo Android): para que elijas qué apps bloquear. Solo se guardan las que eliges.',
      'Alarmas exactas e inicio del teléfono (solo Android): para que los avisos lleguen a tiempo, incluso si reinicias el teléfono.',
    ]),
    _LegalSection('4. Copias de seguridad del teléfono', [
      'Si tienes activadas las copias de seguridad de tu teléfono (Google o iCloud), el sistema puede incluir '
          'los datos de Floria en ellas. Eso lo controla tu teléfono, no Floria, y lo puedes desactivar en sus ajustes.',
    ]),
    _LegalSection('5. Cómo borrar tus datos', [
      'Puedes borrar todo cuando quieras en Ajustes → Reiniciar datos, o desinstalando la app.',
    ]),
    _LegalSection('6. Menores de edad', [
      'Floria no recopila datos de nadie, tampoco de menores de edad.',
    ]),
    _LegalSection('7. Cambios', [
      'Si cambiamos esta política, cambiará la fecha de "Última actualización".',
    ]),
    _LegalSection('8. Contacto', [
      'Si tienes dudas sobre tu privacidad, escríbele al equipo de Floria (Grupo 6, ESEN) a $contactEmail.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.xxl),
          children: [
            Text('Última actualización: $lastUpdated', style: t.bodySmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    document == LegalDocument.privacy
                        ? Icons.lock_outline
                        : Icons.description_outlined,
                    color: p.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(_summary, style: t.bodyLarge)),
                ],
              ),
            ),
            for (final section in _sections) ...[
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                  header: true,
                  child: Text(section.title, style: t.titleMedium)),
              for (final paragraph in section.paragraphs) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(paragraph, style: t.bodyMedium),
              ],
              for (final bullet in section.bullets)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                          child: Text('•  ',
                              style: t.bodyMedium!.copyWith(color: p.primary))),
                      Expanded(child: Text(bullet, style: t.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
