
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/study_reminder.dart';
import '../models/study_task.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';

class RemindersSection extends StatelessWidget {
  const RemindersSection({super.key});

  Future<void> _openReminderForm(
    BuildContext context, {
    StudyReminder? reminder,
  }) async {
    final provider = context.read<StudyProvider>();

    final pendingTasks = provider.tasks
        .where((task) => !task.isCompleted && task.id != null)
        .toList();

    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a pending task before creating a reminder.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      builder: (_) => ReminderFormSheet(
        tasks: pendingTasks,
        reminder: reminder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();

    final reminders = provider.reminders
        .where((reminder) => reminder.isActive && !reminder.isSent)
        .toList()
      ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Study Reminders 🌼',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openReminderForm(context),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reminders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.sageLight.withOpacity(.35),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.sage,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No reminders yet. Add one to stay on track!',
                    style: TextStyle(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...reminders.map((reminder) {
            final matchingTasks = provider.tasks
                .where((task) => task.id == reminder.taskId)
                .toList();

            final taskTitle = matchingTasks.isEmpty
                ? 'Study task'
                : matchingTasks.first.title;

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sageLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.sage,
                    size: 25,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.message,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat('EEE, d MMM • h:mm a')
                              .format(reminder.reminderTime),
                          style: const TextStyle(
                            color: AppColors.sage,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit reminder',
                    onPressed: () => _openReminderForm(
                      context,
                      reminder: reminder,
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete reminder',
                    onPressed: () async {
                      await context
                          .read<StudyProvider>()
                          .deleteReminder(reminder);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class ReminderFormSheet extends StatefulWidget {
  const ReminderFormSheet({
    super.key,
    required this.tasks,
    this.reminder,
  });

  final List<StudyTask> tasks;
  final StudyReminder? reminder;

  @override
  State<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<ReminderFormSheet> {
  final _messageController = TextEditingController();

  int? _selectedTaskId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final reminder = widget.reminder;
    final now = DateTime.now();

    _selectedTaskId = reminder?.taskId;

    if (_selectedTaskId == null ||
        !widget.tasks.any((task) => task.id == _selectedTaskId)) {
      _selectedTaskId = widget.tasks.first.id;
    }

    _selectedDate = reminder?.reminderTime ?? now;
    _selectedTime = reminder != null
        ? TimeOfDay.fromDateTime(reminder.reminderTime)
        : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)));

    _messageController.text =
        reminder?.message ?? 'Time to work on your study task!';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveReminder() async {
    if (_selectedTaskId == null || _saving) return;

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder message.')),
      );
      return;
    }

    final reminderTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (!reminderTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<StudyProvider>();
      final existing = widget.reminder;

      if (existing == null) {
        await provider.addReminder(
          StudyReminder(
            taskId: _selectedTaskId!,
            reminderTime: reminderTime,
            message: message,
          ),
        );
      } else {
        await provider.updateReminder(
          existing.copyWith(
            taskId: _selectedTaskId!,
            reminderTime: reminderTime,
            message: message,
            isActive: true,
            isSent: false,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTasks = widget.tasks;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reminder == null
                  ? 'Create a Reminder 🌼'
                  : 'Edit Reminder 🌼',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select task',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedTaskId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a task',
              ),
              items: availableTasks.map((task) {
                return DropdownMenuItem<int>(
                  value: task.id,
                  child: Text(
                    task.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTaskId = value);
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Reminder date',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.sage,
              ),
              title: Text(DateFormat('EEEE, d MMM yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            const Text(
              'Reminder time',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.access_time_rounded,
                color: AppColors.sage,
              ),
              title: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            const Text(
              'Reminder message',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Time to revise your lecture!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveReminder,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save Reminder',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
