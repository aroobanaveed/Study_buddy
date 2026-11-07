
import '../models/study_task.dart';
import 'priority_service.dart';

class StudyPlanItem {
  final StudyTask task;
  final int plannedMinutes;
  final String reason;
  final bool isPartial;
  final int breakAfterMinutes;

  const StudyPlanItem({
    required this.task,
    required this.plannedMinutes,
    required this.reason,
    required this.isPartial,
    this.breakAfterMinutes = 0,
  });
}

class StudyPlan {
  final List<StudyPlanItem> items;
  final List<StudyTask> remainingTasks;
  final int availableMinutes;
  final int totalStudyMinutes;
  final int totalBreakMinutes;

  const StudyPlan({
    required this.items,
    required this.remainingTasks,
    required this.availableMinutes,
    required this.totalStudyMinutes,
    required this.totalBreakMinutes,
  });

  int get totalPlannedMinutes =>
      totalStudyMinutes + totalBreakMinutes;
}

class StudyPlannerService {
  static const int breakMinutes = 5;

  static StudyPlan generate({
    required List<StudyTask> tasks,
    required int availableMinutes,
  }) {
    final rankedTasks = PriorityService.rank(tasks);

    final selectedItems = <StudyPlanItem>[];
    final remainingTasks = <StudyTask>[];

    int usedMinutes = 0;
    int studyMinutes = 0;
    int breakTotal = 0;

    if (availableMinutes <= 0) {
      return StudyPlan(
        items: selectedItems,
        remainingTasks: rankedTasks,
        availableMinutes: availableMinutes,
        totalStudyMinutes: 0,
        totalBreakMinutes: 0,
      );
    }

    for (int i = 0; i < rankedTasks.length; i++) {
      final task = rankedTasks[i];
      final remainingTime = availableMinutes - usedMinutes;

      if (remainingTime <= 0) {
        remainingTasks.addAll(rankedTasks.skip(i));
        break;
      }

      final plannedMinutes =
          task.estimatedMinutes.clamp(1, remainingTime).toInt();

      final isPartial = plannedMinutes < task.estimatedMinutes;
      int breakAfter = 0;

      final hasMoreTasks = i < rankedTasks.length - 1;
      final timeAfterTask = remainingTime - plannedMinutes;

      // Break tabhi add hoga jab aglay task ke liye
      // bhi kam az kam 1 minute available ho.
      if (!isPartial &&
          hasMoreTasks &&
          timeAfterTask > breakMinutes) {
        breakAfter = breakMinutes;
      }

      selectedItems.add(
        StudyPlanItem(
          task: task,
          plannedMinutes: plannedMinutes,
          reason: _getReason(task),
          isPartial: isPartial,
          breakAfterMinutes: breakAfter,
        ),
      );

      usedMinutes += plannedMinutes;
      studyMinutes += plannedMinutes;

      if (breakAfter > 0) {
        usedMinutes += breakAfter;
        breakTotal += breakAfter;
      }

      if (isPartial) {
        remainingTasks.add(task);
        remainingTasks.addAll(rankedTasks.skip(i + 1));
        break;
      }
    }

    return StudyPlan(
      items: selectedItems,
      remainingTasks: remainingTasks,
      availableMinutes: availableMinutes,
      totalStudyMinutes: studyMinutes,
      totalBreakMinutes: breakTotal,
    );
  }

  static String _getReason(StudyTask task) {
    final reasons = <String>[];

    if (task.dueDate != null) {
      final hours =
          task.dueDate!.difference(DateTime.now()).inHours;

      if (hours < 0) {
        reasons.add('Deadline has passed');
      } else if (hours <= 24) {
        reasons.add('Deadline is approaching');
      } else if (hours <= 72) {
        reasons.add('Due within the next 3 days');
      }
    }

    if (task.difficulty == 3) {
      reasons.add('This is a difficult task');
    }

    if (task.confidence != null && task.confidence! <= 1) {
      reasons.add('You need more practice with this topic');
    }

    if (task.confidence == 2) {
      reasons.add('A little more practice will help');
    }

    if (reasons.isEmpty) {
      reasons.add(
        'A good next step based on your task priorities',
      );
    }

    return reasons.join(' • ');
  }
}
