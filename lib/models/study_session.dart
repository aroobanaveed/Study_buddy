class StudySession {
  final int? id;
  final int? taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String sessionStatus; // completed, cancelled, interrupted
  final int? confidenceAfter;

  const StudySession({
    this.id,
    this.taskId,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.sessionStatus,
    this.confidenceAfter,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'taskId': taskId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'sessionStatus': sessionStatus,
        'confidenceAfter': confidenceAfter,
      };

  factory StudySession.fromMap(Map<String, Object?> map) => StudySession(
        id: map['id'] as int?,
        taskId: map['taskId'] as int?,
        startedAt: DateTime.parse(map['startedAt'] as String),
        endedAt: map['endedAt'] == null ? null : DateTime.parse(map['endedAt'] as String),
        durationSeconds: map['durationSeconds'] as int,
        sessionStatus: map['sessionStatus'] as String,
        confidenceAfter: map['confidenceAfter'] as int?,
      );
}
