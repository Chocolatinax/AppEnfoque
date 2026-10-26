import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/utils/form_validators.dart';

void main() {
  group('Pruebas Unitarias - Validación de Formulario de Tareas y Enfoque', () {
    // Campo 1: Título de la tarea
    test('TC-1: Título vacío o solo espacios es rechazado', () {
      expect(
        FormValidators.validateTitle('   '),
        'Por favor ingresa el título de la tarea',
      );
      expect(
        FormValidators.validateTitle(''),
        'Por favor ingresa el título de la tarea',
      );
    });

    test('TC-2: Título con menos de 3 caracteres es rechazado', () {
      expect(
        FormValidators.validateTitle('AB'),
        'El título debe tener al menos 3 caracteres',
      );
      expect(
        FormValidators.validateTitle('a'),
        'El título debe tener al menos 3 caracteres',
      );
    });

    test('TC-3: Título con más de 50 caracteres es rechazado', () {
      final longTitle = 'A' * 51;
      expect(
        FormValidators.validateTitle(longTitle),
        'El título no puede superar los 50 caracteres',
      );
    });

    test('Título válido es aceptado', () {
      expect(
        FormValidators.validateTitle('Finalizar informe de métricas Q2'),
        isNull,
      );
    });

    // Campo 2: Declaración del objetivo
    test('TC-4: Objetivo vacío es rechazado', () {
      expect(
        FormValidators.validateGoal(''),
        'Declara qué quieres lograr en esta sesión',
      );
      expect(
        FormValidators.validateGoal('    '),
        'Declara qué quieres lograr en esta sesión',
      );
    });

    test('TC-5: Objetivo con menos de 4 palabras es rechazado', () {
      expect(
        FormValidators.validateGoal('estudiar'),
        'Escribe al menos 4 palabras',
      );
      expect(
        FormValidators.validateGoal('estudiar mucho hoy'),
        'Escribe al menos 4 palabras',
      );
    });

    test('TC-5b: Objetivo de 4 palabras pero muy corto es rechazado', () {
      expect(
        FormValidators.validateGoal('a b c d'),
        'Escribe al menos 15 caracteres',
      );
    });

    test(
        'Objetivo corto pero concreto (4 palabras, 15+ caracteres) es aceptado',
        () {
      expect(FormValidators.validateGoal('Leer el capítulo 3'), isNull);
      // Espacios de más no cuentan como palabras
      expect(
          FormValidators.validateGoal('  Leer   el   capítulo   3  '), isNull);
    });

    test('Objetivo válido es aceptado', () {
      expect(
        FormValidators.validateGoal(
          'Completar el análisis de retención de usuarios y redactar las 3 conclusiones clave.',
        ),
        isNull,
      );
    });

    // Campo 3: Duración estimada
    test('TC-6: Duración no numérica o decimal es rechazada', () {
      expect(
        FormValidators.validateDuration('veinticinco'),
        'Ingresa un número entero válido (sin letras ni decimales)',
      );
      expect(
        FormValidators.validateDuration('25.5'),
        'Ingresa un número entero válido (sin letras ni decimales)',
      );
    });

    test('TC-7: Duración menor a 5 minutos es rechazada', () {
      expect(
        FormValidators.validateDuration('0'),
        'La duración debe estar entre 5 y 180 minutos',
      );
      expect(
        FormValidators.validateDuration('4'),
        'La duración debe estar entre 5 y 180 minutos',
      );
      expect(
        FormValidators.validateDuration('-15'),
        'La duración debe estar entre 5 y 180 minutos',
      );
    });

    test('TC-8: Duración mayor a 180 minutos es rechazada', () {
      expect(
        FormValidators.validateDuration('181'),
        'La duración debe estar entre 5 y 180 minutos',
      );
      expect(
        FormValidators.validateDuration('300'),
        'La duración debe estar entre 5 y 180 minutos',
      );
    });

    test('Duración válida es aceptada', () {
      expect(FormValidators.validateDuration('45'), isNull);
      expect(FormValidators.validateDuration('25'), isNull);
      expect(FormValidators.validateDuration('180'), isNull);
    });

    // Campo 4: Apps bloqueadas
    test('TC-9: Bloqueo activo sin apps seleccionadas es rechazado', () {
      expect(
        FormValidators.validateBlockedApps(
          isBlockingEnabled: true,
          apps: [],
        ),
        'Debes seleccionar al menos una app para bloquear',
      );
    });

    test('TC-10: Configuración completa válida pasa todas las validaciones',
        () {
      const title = 'Estudiar Cálculo III';
      const goal = 'Resolver los 5 ejercicios de integrales triples';
      const duration = '45';
      const apps = ['Instagram', 'TikTok'];

      expect(FormValidators.validateTitle(title), isNull);
      expect(FormValidators.validateGoal(goal), isNull);
      expect(FormValidators.validateDuration(duration), isNull);
      expect(
        FormValidators.validateBlockedApps(
          isBlockingEnabled: true,
          apps: apps,
        ),
        isNull,
      );
    });
  });
}
