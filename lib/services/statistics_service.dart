import '../models/study_session.dart';
import '../models/study_task.dart';

class StatisticsService {
  static int totalSeconds(List<StudySession> sessions) => sessions
      .where((s) => s.sessionStatus == 'completed')
      .fold(0, (sum, s) => sum + s.durationSeconds);

  static int todaySeconds(List<StudySession> sessions, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return sessions.where((s) => s.sessionStatus == 'completed' && _sameDay(s.startedAt, today))
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  static int weeklySeconds(List<StudySession> sessions, DateTime day) {
    final start = DateTime(day.year, day.month, day.day).subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return sessions.where((s) => s.sessionStatus == 'completed' && !s.startedAt.isBefore(start) && s.startedAt.isBefore(end))
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  static Map<String, int> secondsBySubject(List<StudyTask> tasks, List<StudySession> sessions) {
    final taskById = {for (final t in tasks) if (t.id != null) t.id!: t};
    final result = <String, int>{};
    for (final s in sessions.where((s) => s.sessionStatus == 'completed')) {
      final subject = s.taskId == null ? 'Free study' : (taskById[s.taskId]?.subject ?? 'Other');
      result[subject] = (result[subject] ?? 0) + s.durationSeconds;
    }
    return result;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
