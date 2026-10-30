import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/screens/legal_screen.dart';
import 'package:enfoque_app/theme/app_theme.dart';

/// Pruebas de Términos de uso y Política de privacidad, incluidas las guías
/// automáticas de accesibilidad de Flutter (contraste y áreas táctiles).
void main() {
  Future<void> pump(WidgetTester tester, LegalDocument document,
      {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light,
      home: LegalScreen(document: document),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Términos de uso muestra el resumen y sus secciones',
      (tester) async {
    await pump(tester, LegalDocument.terms);
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.textContaining('Última actualización'), findsOneWidget);
    expect(find.text('1. Qué es Floria'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('10. Contacto'), 300);
    expect(find.text('10. Contacto'), findsOneWidget);
  });

  testWidgets('La privacidad explica los dos modos y los permisos',
      (tester) async {
    await pump(tester, LegalDocument.privacy);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.textContaining('Sin cuenta, todo se queda en tu teléfono'),
        findsOneWidget);
    await tester.scrollUntilVisible(
        find.textContaining('Accesibilidad (solo Android)'), 300);
    expect(find.text('5. Permisos y para qué sirven'), findsOneWidget);
    expect(find.textContaining('Accesibilidad (solo Android)'), findsOneWidget);
  });

  for (final (name, theme) in [
    ('claro', AppTheme.light),
    ('oscuro', AppTheme.dark)
  ]) {
    testWidgets('Cumple las guías de accesibilidad (modo $name)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, LegalDocument.privacy, theme: theme);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('Se lee bien con el texto al 200 %', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2.0)),
        child: child!,
      ),
      home: const LegalScreen(document: LegalDocument.terms),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // sin desbordes
  });
}
