
class StudyReminder {
  final int? id;
  final int taskId;
  final DateTime reminderTime;
  final String message;
  final bool isActive;
  final bool isSent;

  const StudyReminder({
    this.id,
    required this.taskId,
    required this.reminderTime,
    required this.message,
    this.isActive = true,
    this.isSent = false,
  });

  StudyReminder copyWith({
    int? id,
    int? taskId,
    DateTime? reminderTime,
    String? message,
    bool? isActive,
    bool? isSent,
  }) {
    return StudyReminder(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      reminderTime: reminderTime ?? this.reminderTime,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      isSent: isSent ?? this.isSent,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'reminderTime': reminderTime.toIso8601String(),
      'message': message,
      'isActive': isActive ? 1 : 0,
      'isSent': isSent ? 1 : 0,
    };
  }

  factory StudyReminder.fromMap(Map<String, Object?> map) {
    return StudyReminder(
      id: map['id'] as int?,
      taskId: map['taskId'] as int,
      reminderTime: DateTime.parse(map['reminderTime'] as String),
      message: map['message'] as String,
      isActive: (map['isActive'] as int) == 1,
      isSent: (map['isSent'] as int) == 1,
    );
  }
}
