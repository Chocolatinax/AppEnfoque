import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String fileName = 'floria.db';
  static const int version = 5;

  final Database db;

  AppDatabase._(this.db);

  static Future<AppDatabase> open(
      {DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id                 TEXT PRIMARY KEY,
        title              TEXT NOT NULL,
        goal               TEXT NOT NULL,
        duration_minutes   INTEGER NOT NULL CHECK (duration_minutes BETWEEN 5 AND 180),
        priority           TEXT NOT NULL CHECK (priority IN ('Alta', 'Media', 'Baja')),
        timer_mode         TEXT NOT NULL DEFAULT 'libre' CHECK (timer_mode IN ('libre', 'pomodoro')),
        pomodoro_rounds    INTEGER NOT NULL DEFAULT 0,
        tags               TEXT NOT NULL DEFAULT '[]',
        block_distractions INTEGER NOT NULL DEFAULT 1,
        blocked_apps       TEXT NOT NULL DEFAULT '[]',
        blocked_packages   TEXT NOT NULL DEFAULT '[]',
        is_done            INTEGER NOT NULL DEFAULT 0,
        created_at         TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id               TEXT PRIMARY KEY,
        task_id          TEXT REFERENCES tasks(id) ON DELETE SET NULL,
        task_title       TEXT NOT NULL,
        planned_minutes  INTEGER NOT NULL,
        focus_seconds    INTEGER NOT NULL DEFAULT 0,
        started_at       TEXT NOT NULL,
        ended_at         TEXT,
        status           TEXT NOT NULL CHECK (status IN ('en_curso', 'completada', 'abandonada')),
        goal_result      TEXT CHECK (goal_result IN ('si', 'en_parte', 'no'))
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_sessions_started_at ON sessions(started_at)');

    await db.execute('''
      CREATE TABLE active_session (
        id                INTEGER PRIMARY KEY CHECK (id = 1),
        session_id        TEXT NOT NULL,
        task_id           TEXT NOT NULL,
        started_at        TEXT NOT NULL,
        paused_seconds    INTEGER NOT NULL DEFAULT 0,
        pause_started_at  TEXT,
        skipped_seconds   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // v2: pomodoro, v3: paquetes de apps, v4: sesión en curso, v5: ajustes
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE tasks ADD COLUMN timer_mode TEXT NOT NULL DEFAULT 'libre'");
      await db.execute(
          'ALTER TABLE tasks ADD COLUMN pomodoro_rounds INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE sessions ADD COLUMN focus_seconds INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE tasks ADD COLUMN blocked_packages TEXT NOT NULL DEFAULT '[]'");
    }
    if (oldVersion < 4) {
      await db.execute('''
      CREATE TABLE active_session (
        id                INTEGER PRIMARY KEY CHECK (id = 1),
        session_id        TEXT NOT NULL,
        task_id           TEXT NOT NULL,
        started_at        TEXT NOT NULL,
        paused_seconds    INTEGER NOT NULL DEFAULT 0,
        pause_started_at  TEXT,
        skipped_seconds   INTEGER NOT NULL DEFAULT 0
      )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() => db.close();
}
