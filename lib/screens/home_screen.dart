
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/study_task.dart';
import '../providers/study_provider.dart';
import '../services/priority_service.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/common_widgets.dart';
import '../widgets/study_planner_sheet.dart';
import '../widgets/reminders_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTasks,
    required this.onStartFocus,
  });

  final VoidCallback onOpenTasks;
  final ValueChanged<StudyTask?> onStartFocus;

  Future<void> _addTask(BuildContext context) async {
    final task = await showModalBottomSheet<StudyTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => const AddTaskSheet(),
    );

    if (task != null && context.mounted) {
      await context.read<StudyProvider>().addTask(task);
    }
  }

  void _openStudyPlanner(BuildContext context) {
    final provider = context.read<StudyProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => StudyPlannerSheet(
        tasks: provider.tasks,
        onStartFocus: onStartFocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final tasks = provider.tasks;
    final pending = PriorityService.rank(tasks).take(3).toList();
    final completed = tasks.where((t) => t.isCompleted).length;
    final todaySeconds =
        StatisticsService.todaySeconds(provider.sessions);
    final now = DateTime.now();

    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          // GREETING
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d')
                          .format(now)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$greeting,\nlet’s make today count ✨',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.sage,
                  size: 27,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // DAILY RESET
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEAE6FF),
                  Color(0xFFF1EEFF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.sage,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'YOUR DAILY RESET',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .7,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  pending.isEmpty
                      ? 'A fresh start is waiting for you.'
                      : 'One small step is enough to get started.',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pending.isEmpty
                      ? 'Add a task and we’ll help you choose what to do first.'
                      : 'You have ${tasks.where((t) => !t.isCompleted).length} task(s) left. Let’s take them one at a time.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // START STUDYING AND ADD TASK
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onStartFocus(
                          pending.isEmpty ? null : pending.first,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start studying'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    IconButton.filledTonal(
                      tooltip: 'Add task',
                      onPressed: () => _addTask(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                // SMART STUDY PLANNER
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openStudyPlanner(context),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Plan My Study Day'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sage,
                      side: const BorderSide(
                        color: AppColors.sage,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // STUDY STATISTICS
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                icon: Icons.task_alt_rounded,
                value: '$completed/${tasks.length}',
                label: 'Tasks completed',
                color: AppColors.sageLight,
              ),
              StatCard(
                icon: Icons.schedule_rounded,
                value: _formatDuration(todaySeconds),
                label: 'Study time today',
                color: AppColors.butterYellow,
              ),
            ],
          ),

          const SizedBox(height: 23),

          // STUDY REMINDERS
          const RemindersSection(),

          const SizedBox(height: 23),

          // NEXT PRIORITIES
          SectionHeading(
            'Your next priorities',
            trailing: 'See all',
            onTrailing: onOpenTasks,
          ),

          const SizedBox(height: 10),

          if (pending.isEmpty)
            EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'You’re all caught up!',
              subtitle:
                  'Add a task whenever you’re ready for your next small win.',
              actionLabel: 'Add a task',
              onAction: () => _addTask(context),
            )
          else
            ...pending.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(
                  task: task,
                  showPriority: true,
                  onTap: () => onStartFocus(task),
                  onToggle: (v) =>
                      context.read<StudyProvider>().toggleTask(task, v),
                  onDelete: () => _showTaskActions(context, task),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // MOTIVATIONAL MESSAGE
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.butterYellow.withOpacity(.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppColors.orange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You don’t need a perfect day. Just a little progress, at your own pace. 🌱',
                    style: TextStyle(
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;

    if (mins < 60) return '${mins}m';

    return '${mins ~/ 60}h ${mins % 60}m';
  }

  Future<void> _showTaskActions(
    BuildContext context,
    StudyTask task,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Start focus session'),
              onTap: () => Navigator.pop(ctx, 'focus'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit task'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.red,
              ),
              title: const Text('Delete task'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice == 'focus') {
      onStartFocus(task);
      return;
    }

    if (choice == 'edit') {
      final updated = await showModalBottomSheet<StudyTask>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (_) => AddTaskSheet(task: task),
      );

      if (updated != null && context.mounted) {
        await context.read<StudyProvider>().updateTask(updated);
      }
    } else if (choice == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFFFAF8EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Task?',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.muted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await context.read<StudyProvider>().deleteTask(task);
      }
    }
  }
}
