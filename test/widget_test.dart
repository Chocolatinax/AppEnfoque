import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/widgets/task_form_screen.dart';

void main() {
  testWidgets('Verifica renderizado de formulario de tareas y validaciones', (WidgetTester tester) async {
    // Configura pantalla de tamaño móvil realista
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Renderiza la aplicación
    // La app ahora inicia en la Bienvenida, así que se prueba el formulario directamente
    await tester.pumpWidget(const MaterialApp(home: TaskFormScreen()));
    await tester.pumpAndSettle();

    // Comprueba elementos clave de la interfaz según el diseño (AppBar y BottomBar tienen "Nueva")
    expect(find.text('Nueva'), findsNWidgets(2));
    expect(find.text('100% OFFLINE / LOCAL'), findsOneWidget);
    expect(find.text('Crear Nueva Tarea'), findsOneWidget);
    expect(find.text('Guardar e Iniciar Enfoque'), findsOneWidget);
    expect(find.text('Solo Guardar en Lista'), findsOneWidget);

    // Comprueba que los campos de texto existen
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3)); // Título, Objetivo, Duración

    // Prueba de rechazo: Borra el título para dejarlo inválido y presiona guardar
    final titleFinder = find.widgetWithText(TextFormField, 'Finalizar informe de métricas Q2');
    await tester.enterText(titleFinder, '');
    await tester.pumpAndSettle();

    // Presiona el botón de guardar
    final saveButton = find.text('Guardar e Iniciar Enfoque');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Comprueba que el validador del campo 1 rechazó la entrada y mostró el mensaje de error
    expect(find.text('Por favor ingresa el título de la tarea'), findsOneWidget);

    // Comprueba que apareció el SnackBar de error indicando datos inválidos
    expect(find.text('Datos inválidos: Revisa los campos marcados en rojo antes de guardar.'), findsOneWidget);
  });
}
