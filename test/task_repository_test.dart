import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enfoque_app/data/app_database.dart';
import 'package:enfoque_app/data/task_repository.dart';
import 'package:enfoque_app/models/task_model.dart';

/// Pruebas de persistencia local: usan una base SQLite en memoria
/// (sqflite_common_ffi), así corren en la computadora sin emulador.
void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late TaskRepository repo;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repo = TaskRepository(database);
    await repo.load();
  });

  tearDown(() => database.close());

  Task buildTask(String id, String priority, {int minutes = 25}) => Task(
        id: id,
        title: 'Tarea $id',
        goal: 'Objetivo de la tarea $id',
        durationMinutes: minutes,
        priority: priority,
        tags: const ['Estudio'],
        blockedApps: const ['Instagram', 'TikTok'],
      );

  group('Persistencia de tareas (SQLite)', () {
    test('Guarda una tarea y la recupera completa al volver a cargar', () async {
      await repo.add(buildTask('1', 'Alta', minutes: 45));

      // Un repositorio nuevo simula cerrar y volver a abrir la app
      final reopened = TaskRepository(database);
      await reopened.load();

      expect(reopened.tasks, hasLength(1));
      final saved = reopened.tasks.single;
      expect(saved.title, 'Tarea 1');
      expect(saved.goal, 'Objetivo de la tarea 1');
      expect(saved.durationMinutes, 45);
      expect(saved.priority, 'Alta');
      expect(saved.tags, ['Estudio']);
      expect(saved.blockedApps, ['Instagram', 'TikTok']);
      expect(saved.blockDistractions, isTrue);
      expect(saved.isDone, isFalse);
    });

    test('Ordena las pendientes por prioridad y sugiere la más importante', () async {
      await repo.add(buildTask('baja', 'Baja'));
      await repo.add(buildTask('alta', 'Alta'));
      await repo.add(buildTask('media', 'Media'));

      expect(repo.tasks.map((t) => t.priority), ['Alta', 'Media', 'Baja']);
      expect(repo.nextTask?.id, 'alta');
    });

    test('Marcar como hecha se guarda y la tarea pasa al final', () async {
      await repo.add(buildTask('alta', 'Alta'));
      await repo.add(buildTask('media', 'Media'));

      await repo.toggleDone('alta');

      final reopened = TaskRepository(database);
      await reopened.load();
      expect(reopened.tasks.last.id, 'alta');
      expect(reopened.tasks.last.isDone, isTrue);
      expect(reopened.nextTask?.id, 'media');
    });

    test('Reiniciar datos borra todas las tareas', () async {
      await repo.add(buildTask('1', 'Alta'));
      await repo.add(buildTask('2', 'Baja'));

      await repo.clearAll();

      final reopened = TaskRepository(database);
      await reopened.load();
      expect(reopened.tasks, isEmpty);
    });

    test('La base rechaza duraciones fuera de 5 a 180 minutos', () async {
      expect(
        () => repo.add(buildTask('x', 'Alta', minutes: 500)),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
