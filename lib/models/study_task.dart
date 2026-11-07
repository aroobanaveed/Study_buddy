class StudyTask {
  final int? id;
  final String title;
  final String subject;
  final String taskType;
  final DateTime? dueDate;
  final int estimatedMinutes;
  final int difficulty; // 1 easy, 2 medium, 3 hard
  final int? confidence; // 1 confused, 2 getting there, 3 confident
  final String status; // pending, completed
  final DateTime createdAt;
  final DateTime? completedAt;

  const StudyTask({
    this.id,
    required this.title,
    required this.subject,
    required this.taskType,
    this.dueDate,
    required this.estimatedMinutes,
    required this.difficulty,
    this.confidence,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';

  StudyTask copyWith({
    int? id,
    String? title,
    String? subject,
    String? taskType,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? estimatedMinutes,
    int? difficulty,
    int? confidence,
    bool clearConfidence = false,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => StudyTask(
        id: id ?? this.id,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        taskType: taskType ?? this.taskType,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        difficulty: difficulty ?? this.difficulty,
        confidence: clearConfidence ? null : (confidence ?? this.confidence),
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'subject': subject,
        'taskType': taskType,
        'dueDate': dueDate?.toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'difficulty': difficulty,
        'confidence': confidence,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory StudyTask.fromMap(Map<String, Object?> map) => StudyTask(
        id: map['id'] as int?,
        title: map['title'] as String,
        subject: map['subject'] as String,
        taskType: map['taskType'] as String,
        dueDate: map['dueDate'] == null ? null : DateTime.parse(map['dueDate'] as String),
        estimatedMinutes: map['estimatedMinutes'] as int,
        difficulty: map['difficulty'] as int,
        confidence: map['confidence'] as int?,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedAt: map['completedAt'] == null ? null : DateTime.parse(map['completedAt'] as String),
      );
}
