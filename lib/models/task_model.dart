import 'dart:convert';

/// Reglas del modo Pomodoro de Floria (técnica estándar):
/// 25 min de enfoque + 5 min de descanso por ronda; después de la 4.ª ronda,
/// un descanso largo de 25 min (la técnica recomienda entre 15 y 30).
class Pomodoro {
  Pomodoro._();

  static const int focusMinutes = 25;
  static const int shortBreakMinutes = 5;
  static const int longBreakMinutes = 25;

  /// Cada cuántas rondas el descanso pasa a ser largo.
  static const int longBreakEvery = 4;

  static const int minRounds = 1;
  static const int maxRounds = 6; // 6 x 25 = 150 min (dentro del límite de 180)

  /// Duración del descanso que sigue a la ronda [round] (empieza en 1).
  /// Toda ronda, incluida la última, termina con su descanso.
  static int breakAfterRound(int round) =>
      round % longBreakEvery == 0 ? longBreakMinutes : shortBreakMinutes;
}

/// Modos de tiempo de una tarea.
class TimerMode {
  TimerMode._();
  static const String free = 'libre';
  static const String pomodoro = 'pomodoro';
}

/// Modelo de datos para las tareas de concentración y estudio
class Task {
  final String id;
  final String title;
  final String goal;

  /// Minutos de enfoque totales (en Pomodoro = rondas x 25).
  final int durationMinutes;
  final String priority; // 'Alta', 'Media', 'Baja'
  final String timerMode; // TimerMode.free | TimerMode.pomodoro
  final int pomodoroRounds; // solo en modo Pomodoro
  final List<String> tags; // ya no se usa en la interfaz (se conserva por compatibilidad)
  final bool blockDistractions;
  final List<String> blockedApps; // nombres visibles ("Instagram")
  final List<String> blockedPackages; // paquetes de Android ("com.instagram.android"), mismo orden
  final bool isDone;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.goal,
    required this.durationMinutes,
    this.priority = 'Alta',
    this.timerMode = TimerMode.free,
    this.pomodoroRounds = 0,
    this.tags = const [],
    this.blockDistractions = true,
    this.blockedApps = const [],
    this.blockedPackages = const [],
    this.isDone = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPomodoro => timerMode == TimerMode.pomodoro;

  /// Texto corto para listas: "45 min" o "4 pomodoros · 100 min".
  String get durationLabel => isPomodoro
      ? '$pomodoroRounds ${pomodoroRounds == 1 ? 'pomodoro' : 'pomodoros'} · $durationMinutes min'
      : '$durationMinutes min';

  /// Orden de importancia para listar primero lo más urgente.
  static int priorityRank(String priority) => switch (priority) {
        'Alta' => 0,
        'Media' => 1,
        _ => 2,
      };

  Task copyWith({bool? isDone}) {
    return Task(
      id: id,
      title: title,
      goal: goal,
      durationMinutes: durationMinutes,
      priority: priority,
      timerMode: timerMode,
      pomodoroRounds: pomodoroRounds,
      tags: tags,
      blockDistractions: blockDistractions,
      blockedApps: blockedApps,
      blockedPackages: blockedPackages,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }

  // ---------- SQLite ----------
  // SQLite no tiene listas ni booleanos: las listas se guardan como texto JSON
  // y los booleanos como 0 / 1.

  /// Convierte la tarea en una fila de la tabla `tasks`.
  Map<String, Object?> toDbMap() {
    return {
      'id': id,
      'title': title,
      'goal': goal,
      'duration_minutes': durationMinutes,
      'priority': priority,
      'timer_mode': timerMode,
      'pomodoro_rounds': pomodoroRounds,
      'tags': jsonEncode(tags),
      'block_distractions': blockDistractions ? 1 : 0,
      'blocked_apps': jsonEncode(blockedApps),
      'blocked_packages': jsonEncode(blockedPackages),
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea una tarea a partir de una fila de la tabla `tasks`.
  factory Task.fromDbMap(Map<String, Object?> row) {
    List<String> decodeList(Object? value) =>
        value is String && value.isNotEmpty ? List<String>.from(jsonDecode(value) as List) : <String>[];

    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      goal: row['goal'] as String,
      durationMinutes: row['duration_minutes'] as int,
      priority: row['priority'] as String,
      timerMode: row['timer_mode'] as String? ?? TimerMode.free,
      pomodoroRounds: row['pomodoro_rounds'] as int? ?? 0,
      tags: decodeList(row['tags']),
      blockDistractions: (row['block_distractions'] as int? ?? 1) == 1,
      blockedApps: decodeList(row['blocked_apps']),
      blockedPackages: decodeList(row['blocked_packages']),
      isDone: (row['is_done'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ---------- Mapa genérico (exportar a JSON) ----------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'goal': goal,
      'durationMinutes': durationMinutes,
      'priority': priority,
      'tags': tags,
      'blockDistractions': blockDistractions,
      'blockedApps': blockedApps,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      goal: map['goal'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 25,
      priority: map['priority'] ?? 'Alta',
      tags: List<String>.from(map['tags'] ?? []),
      blockDistractions: map['blockDistractions'] ?? true,
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      isDone: map['isDone'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Modelo para las aplicaciones bloqueadas durante la sesión de estudio
class BlockedAppItem {
  final String name;
  final String packageName;
  final String category;
  bool isBlocked;

  BlockedAppItem({
    required this.name,
    required this.packageName,
    this.category = 'Redes Sociales',
    this.isBlocked = false,
  });
}
