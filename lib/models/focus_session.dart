class GoalResult {
  GoalResult._();
  static const String yes = 'si';
  static const String partly = 'en_parte';
  static const String no = 'no';

  static String label(String? value) => switch (value) {
        yes => 'Objetivo cumplido',
        partly => 'Objetivo cumplido en parte',
        no => 'Objetivo no cumplido',
        _ => 'Sin respuesta',
      };
}

class SessionStatus {
  SessionStatus._();
  static const String completed = 'completada';
  static const String abandoned = 'abandonada';
}

class FocusSession {
  final String id;
  final String? taskId;
  final String taskTitle;
  final int plannedMinutes;
  final int focusSeconds;
  final DateTime startedAt;
  final DateTime endedAt;
  final String status;
  final String? goalResult;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.plannedMinutes,
    required this.focusSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    this.goalResult,
  });

  bool get isCompleted => status == SessionStatus.completed;

  Map<String, Object?> toDbMap() => {
        'id': id,
        'task_id': taskId,
        'task_title': taskTitle,
        'planned_minutes': plannedMinutes,
        'focus_seconds': focusSeconds,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'status': status,
        'goal_result': goalResult,
      };

  factory FocusSession.fromDbMap(Map<String, Object?> row) => FocusSession(
        id: row['id'] as String,
        taskId: row['task_id'] as String?,
        taskTitle: row['task_title'] as String,
        plannedMinutes: row['planned_minutes'] as int,
        focusSeconds: row['focus_seconds'] as int? ?? 0,
        startedAt: DateTime.parse(row['started_at'] as String),
        endedAt:
            DateTime.parse((row['ended_at'] ?? row['started_at']) as String),
        status: row['status'] as String,
        goalResult: row['goal_result'] as String?,
      );
}
