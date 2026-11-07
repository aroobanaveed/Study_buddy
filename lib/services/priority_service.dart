import '../models/study_task.dart';

class PriorityService {
  static double score(StudyTask task, {DateTime? now}) {
    if (task.isCompleted) return -1;
    final current = now ?? DateTime.now();
    double urgency;
    if (task.dueDate == null) {
      urgency = 0.35;
    } else {
      final hours = task.dueDate!.difference(current).inHours;
      if (hours < 0) {
        urgency = 1.0;
      } else if (hours <= 24) {
        urgency = 1.0;
      } else if (hours <= 72) {
        urgency = 0.8;
      } else if (hours <= 168) {
        urgency = 0.6;
      } else if (hours <= 336) {
        urgency = 0.4;
      } else {
        urgency = 0.2;
      }
    }
    final difficulty = (task.difficulty.clamp(1, 3) / 3.0).toDouble();
    final effort = (task.estimatedMinutes / 180.0).clamp(0.0, 1.0).toDouble();
    final knowledgeGap = task.confidence == null ? 0.5 : ((4 - task.confidence!.clamp(1, 3)) / 3.0).toDouble();
    return 0.40 * urgency + 0.25 * difficulty + 0.20 * effort + 0.15 * knowledgeGap;
  }

  static List<StudyTask> rank(List<StudyTask> tasks, {DateTime? now}) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    pending.sort((a, b) => score(b, now: now).compareTo(score(a, now: now)));
    return pending;
  }

  static String label(StudyTask task) {
    final s = score(task);
    if (s >= 0.70) return 'High priority';
    if (s >= 0.48) return 'Medium priority';
    return 'Low priority';
  }
}
