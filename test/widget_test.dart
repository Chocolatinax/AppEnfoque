import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/data/blockable_apps.dart';
import 'package:enfoque_app/models/task_model.dart';
import 'package:enfoque_app/theme/app_theme.dart';
import 'package:enfoque_app/widgets/task_form_screen.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester) async {
    // Pantalla de tamaño móvil realista
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const TaskFormScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('El formulario rechaza datos inválidos antes de guardar',
      (tester) async {
    await pumpForm(tester);

    // Elementos clave de la interfaz
    expect(find.text('Nueva tarea'), findsOneWidget);
    expect(find.text('Guardar e iniciar enfoque'), findsOneWidget);
    expect(find.text('Solo guardar'), findsOneWidget);

    // Modo "Tiempo libre" (por defecto): título, objetivo y duración
    expect(find.byType(TextFormField), findsNWidgets(3));

    // Presionar guardar con el formulario vacío
    final saveButton = find.text('Guardar e iniciar enfoque');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Los validadores rechazan título y objetivo vacíos
    expect(
        find.text('Por favor ingresa el título de la tarea'), findsOneWidget);
    expect(
        find.text('Declara qué quieres lograr en esta sesión'), findsOneWidget);

    // Aviso general de datos inválidos
    expect(find.text('Revisa los campos marcados antes de guardar.'),
        findsOneWidget);
  });

  testWidgets('El modo Pomodoro reemplaza el campo de minutos por rondas',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Pomodoro'));
    await tester.pumpAndSettle();

    // Ya no se escribe la duración: se eligen rondas (4 por defecto = 100 min)
    expect(find.byType(TextFormField), findsNWidgets(2));
    // 4 rondas: 100 min de enfoque + (5 + 5 + 5 + 25) = 40 min de descanso
    expect(find.text('Total: 100 min de enfoque + 40 min de descanso'),
        findsOneWidget);

    // Agregar una ronda: 5 x 25 = 125 min
    await tester.tap(find.byTooltip('Agregar una ronda'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 125 min de enfoque + 45 min de descanso'),
        findsOneWidget);
  });

  testWidgets('Exige al menos una app si el bloqueo está activo',
      (tester) async {
    await pumpForm(tester);

    // Por defecto vienen marcadas las recomendadas (las 9 redes sociales del catálogo)
    expect(find.text('9 apps elegidas'), findsOneWidget);

    // Abrir la pantalla de apps y desmarcar una por una (no hay atajo "Ninguna")
    await tester.ensureVisible(find.text('9 apps elegidas'));
    await tester.tap(find.text('9 apps elegidas'));
    await tester.pumpAndSettle();
    expect(find.text('Ninguna'), findsNothing);
    for (final app in BlockableApps.all) {
      await tester.ensureVisible(find.text(app.name));
      await tester.tap(find.text(app.name));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Listo (ninguna)'));
    await tester.pumpAndSettle();

    expect(find.text('Ninguna app elegida'), findsOneWidget);

    final saveButton = find.text('Guardar e iniciar enfoque');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Debes seleccionar al menos una app para bloquear'),
        findsOneWidget);
  });

  testWidgets(
      'Editar tarea carga sus datos y muestra Guardar cambios y Eliminar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final task = Task(
      id: '1',
      title: 'Estudiar Cálculo',
      goal: 'Resolver 5 ejercicios de integrales',
      durationMinutes: 45,
      priority: 'Alta',
      blockedApps: const ['Instagram'],
    );
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light, home: TaskFormScreen(initialTask: task)));
    await tester.pumpAndSettle();

    expect(find.text('Editar tarea'), findsOneWidget);
    expect(find.text('Estudiar Cálculo'), findsOneWidget);
    expect(find.text('Resolver 5 ejercicios de integrales'), findsOneWidget);
    expect(find.text('45'), findsOneWidget); // duración
    expect(find.text('1 app elegida'),
        findsOneWidget); // conserva sus apps, no las recomendadas
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Eliminar tarea'), findsOneWidget);
    expect(find.text('Guardar e iniciar enfoque'), findsNothing);
  });
}
