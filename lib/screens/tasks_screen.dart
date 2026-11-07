
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_task.dart';
import '../providers/study_provider.dart';
import '../services/priority_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/common_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onStartFocus});

  final ValueChanged<StudyTask?> onStartFocus;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  String _sort = 'Priority';

  Future<void> _add(BuildContext context, {StudyTask? task}) async {
    final result = await showModalBottomSheet<StudyTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => AddTaskSheet(task: task),
    );

    if (result != null && context.mounted) {
      if (task == null) {
        await context.read<StudyProvider>().addTask(result);
      } else {
        await context.read<StudyProvider>().updateTask(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final now = DateTime.now();

    var list = provider.tasks.where((t) {
      switch (_filter) {
        case 'Today':
          return !t.isCompleted &&
              t.dueDate != null &&
              t.dueDate!.year == now.year &&
              t.dueDate!.month == now.month &&
              t.dueDate!.day == now.day;

        case 'Upcoming':
          return !t.isCompleted &&
              (t.dueDate == null ||
                  !t.dueDate!.isBefore(
                    DateTime(now.year, now.month, now.day),
                  ));

        case 'Completed':
          return t.isCompleted;

        default:
          return true;
      }
    }).toList();

    list.sort((a, b) {
      if (_sort == 'Deadline') {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        return a.dueDate!.compareTo(b.dueDate!);
      }

      if (_sort == 'Newest') {
        return b.createdAt.compareTo(a.createdAt);
      }

      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      return PriorityService.score(b).compareTo(
        PriorityService.score(a),
      );
    });

    return Scaffold(
      // AppBar: duplicate Add button removed.
      appBar: AppBar(
        title: const Text('My tasks'),
      ),

      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    'Everything on your mind, in one place.',
                    style: TextStyle(
                      color: AppColors.muted,
                    ),
                  ),
                ),

                // FILTERS
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    children: [
                      for (final f in [
                        'All',
                        'Today',
                        'Upcoming',
                        'Completed',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (_) {
                              setState(() => _filter = f);
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // SORTING
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${list.length} task(s)',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Sort: ',
                        style: TextStyle(
                          color: AppColors.muted,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Priority',
                            child: Text('Priority'),
                          ),
                          DropdownMenuItem(
                            value: 'Deadline',
                            child: Text('Deadline'),
                          ),
                          DropdownMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _sort = v ?? 'Priority';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // TASK LIST
                Expanded(
                  child: list.isEmpty
                      ? EmptyState(
                          icon: Icons.checklist_rounded,
                          title: 'Nothing here yet',
                          subtitle: _filter == 'Completed'
                              ? 'Completed tasks will show up here.'
                              : 'Add your first task and let’s make a simple plan.',
                          actionLabel: 'Add a task',
                          onAction: () => _add(context),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            24,
                          ),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = list[index];

                            return TaskCard(
                              task: task,
                              showPriority: !task.isCompleted,
                              onTap: () => _showActions(
                                context,
                                task,
                              ),
                              onToggle: (v) => context
                                  .read<StudyProvider>()
                                  .toggleTask(task, v),
                              onDelete: () => _showActions(
                                context,
                                task,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // SINGLE ADD TASK BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    StudyTask task,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
              ),
              title: const Text('Start focus session'),
              onTap: () => Navigator.pop(ctx, 'focus'),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
              ),
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
      widget.onStartFocus(task);
    }

    if (choice == 'edit') {
      await _add(context, task: task);
    }

    if (choice == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFFAF8EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete task?',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '“${task.title}” will be removed from your task list.',
            style: const TextStyle(
              color: AppColors.muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await context.read<StudyProvider>().deleteTask(task);
      }
    }
  }
}
