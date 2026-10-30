import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enfoque_app/data/app_database.dart';
import 'package:enfoque_app/data/firestore_session_repository.dart';
import 'package:enfoque_app/data/firestore_task_repository.dart';
import 'package:enfoque_app/data/sqlite_session_repository.dart';
import 'package:enfoque_app/models/focus_session.dart';
import 'package:enfoque_app/models/session_clock.dart';
import 'package:enfoque_app/models/task_model.dart';

void main() {
  sqfliteFfiInit();

  late FakeFirebaseFirestore firestore;
  const uid = 'usuario-1';

  setUp(() => firestore = FakeFirebaseFirestore());

  Task buildTask(String id, String priority) => Task(
        id: id,
        title: 'Tarea $id',
        goal: 'Objetivo de la tarea $id',
        durationMinutes: 25,
        priority: priority,
        blockedApps: const ['Instagram'],
      );

  FocusSession buildSession(String id, DateTime start) => FocusSession(
        id: id,
        taskId: 't1',
        taskTitle: 'Tarea t1',
        plannedMinutes: 25,
        focusSeconds: 25 * 60,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 25)),
        status: SessionStatus.completed,
        goalResult: GoalResult.yes,
      );

  group('Tareas en Firestore', () {
    test('Se guardan en users/{uid}/tasks y se ven al volver a cargar',
        () async {
      final repo = FirestoreTaskRepository(firestore, uid);
      await repo.load();
      await repo.add(buildTask('1', 'Media'));
      await repo.add(buildTask('2', 'Alta'));
      await pumpEventQueue();

      final docs = await firestore.collection('users/$uid/tasks').get();
      expect(docs.docs.map((d) => d.id), containsAll(['1', '2']));

      final reopened = FirestoreTaskRepository(firestore, uid);
      await reopened.load();
      expect(reopened.tasks.map((t) => t.id), ['2', '1']);
      repo.dispose();
      reopened.dispose();
    });

    test('Marcar como hecha y eliminar se reflejan en la nube', () async {
      final repo = FirestoreTaskRepository(firestore, uid);
      await repo.load();
      await repo.add(buildTask('1', 'Alta'));
      await repo.add(buildTask('2', 'Baja'));
      await repo.toggleDone('1');
      await repo.delete('2');
      await pumpEventQueue();

      final doc = await firestore.doc('users/$uid/tasks/1').get();
      expect(doc.data()!['is_done'], 1);
      expect((await firestore.doc('users/$uid/tasks/2').get()).exists, isFalse);
      repo.dispose();
    });

    test('Un usuario no ve las tareas de otro', () async {
      final mine = FirestoreTaskRepository(firestore, uid);
      await mine.load();
      await mine.add(buildTask('1', 'Alta'));
      await pumpEventQueue();

      final other = FirestoreTaskRepository(firestore, 'otro-usuario');
      await other.load();
      expect(other.tasks, isEmpty);
      mine.dispose();
      other.dispose();
    });

    test('Sube las tareas que estaban solo en el teléfono', () async {
      final repo = FirestoreTaskRepository(firestore, uid);
      await repo.load();
      await repo.importAll([buildTask('a', 'Alta'), buildTask('b', 'Baja')]);
      await pumpEventQueue();
      expect(repo.tasks, hasLength(2));
      expect((await firestore.collection('users/$uid/tasks').get()).docs,
          hasLength(2));
      repo.dispose();
    });
  });

  group('Historial en Firestore', () {
    test('Guarda sesiones y la sesión en curso queda en el teléfono', () async {
      final database = await AppDatabase.open(
          factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      final local = SqliteSessionRepository(database);
      final repo = FirestoreSessionRepository(firestore, uid, local: local);
      await repo.load();

      final today = DateTime(2026, 10, 30, 10);
      await repo.record(buildSession('s1', today));
      await repo
          .record(buildSession('s2', today.subtract(const Duration(days: 1))));
      await pumpEventQueue();
      expect(repo.currentStreak(today: today), 2);
      expect((await firestore.collection('users/$uid/sessions').get()).docs,
          hasLength(2));

      await repo.saveActive(
          ActiveSessionRecord(sessionId: 's3', taskId: 't1', startedAt: today));
      expect((await local.loadActive())!.sessionId, 's3');
      expect(
          (await firestore.collection('users/$uid/active_session').get()).docs,
          isEmpty);

      repo.dispose();
      await database.close();
    });
  });
}
