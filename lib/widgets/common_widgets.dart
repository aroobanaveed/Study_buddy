import 'package:flutter/material.dart';
import '../models/study_task.dart';
import '../services/priority_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.trailing,
    this.onTrailing,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTrailing,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
              ),
              child: Text(trailing!),
            ),
        ],
      );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    this.showPriority = false,
    this.onDelete,
  });

  final StudyTask task;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final bool showPriority;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate;
    final overdue = !task.isCompleted &&
        due != null &&
        due.isBefore(DateTime.now());

    final priority = PriorityService.label(task);

    final priorityColor = priority == 'High priority'
        ? AppColors.red
        : priority == 'Medium priority'
            ? AppColors.orange
            : AppColors.green;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (v) => onToggle(v ?? false),
                activeColor: AppColors.green,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? AppColors.muted
                            : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.subject} • ${task.estimatedMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (due != null)
                          _MiniTag(
                            text: overdue
                                ? 'Overdue'
                                : DateFormat('MMM d').format(due),
                            color: overdue
                                ? const Color(0xFFF7DEDA)
                                : AppColors.sageLight,
                            textColor: overdue
                                ? AppColors.red
                                : AppColors.ink,
                          ),
                        if (showPriority && !task.isCompleted)
                          _MiniTag(
                            text: priority,
                            color: priority == 'High priority'
                                ? const Color(0xFFF7DEDA)
                                : priority == 'Medium priority'
                                    ? const Color(0xFFF7E9C9)
                                    : AppColors.sageLight,
                            textColor: priorityColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete task',
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.muted,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.text,
    required this.color,
    this.textColor = AppColors.ink,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      );
}
