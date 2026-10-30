import 'dart:convert';

class Pomodoro {
  Pomodoro._();

  static const int focusMinutes = 25;
  static const int shortBreakMinutes = 5;
  static const int longBreakMinutes = 25;

  static const int longBreakEvery = 4;

  static const int minRounds = 1;
  static const int maxRounds = 6;

  static int breakAfterRound(int round) =>
      round % longBreakEvery == 0 ? longBreakMinutes : shortBreakMinutes;
}

class TimerMode {
  TimerMode._();
  static const String free = 'libre';
  static const String pomodoro = 'pomodoro';
}

class Task {
  final String id;
  final String title;
  final String goal;

  final int durationMinutes;
  final String priority;
  final String timerMode;
  final int pomodoroRounds;
  final List<String> tags;
  final bool blockDistractions;
  final List<String> blockedApps;
  final List<String> blockedPackages;
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

  String get durationLabel => isPomodoro
      ? '$pomodoroRounds ${pomodoroRounds == 1 ? 'pomodoro' : 'pomodoros'} · $durationMinutes min'
      : '$durationMinutes min';

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

  factory Task.fromDbMap(Map<String, Object?> row) {
    List<String> decodeList(Object? value) =>
        value is String && value.isNotEmpty
            ? List<String>.from(jsonDecode(value) as List)
            : <String>[];

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
