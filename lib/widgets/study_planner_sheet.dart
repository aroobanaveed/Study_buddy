
import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../services/study_planner_service.dart';
import '../theme/app_theme.dart';

class StudyPlannerSheet extends StatefulWidget {
  const StudyPlannerSheet({
    super.key,
    required this.tasks,
    required this.onStartFocus,
  });

  final List<StudyTask> tasks;
  final ValueChanged<StudyTask?> onStartFocus;

  @override
  State<StudyPlannerSheet> createState() => _StudyPlannerSheetState();
}

class _StudyPlannerSheetState extends State<StudyPlannerSheet> {
  final _hoursController = TextEditingController(text: '2');
  final _minutesController = TextEditingController(text: '0');

  StudyPlan? _plan;
  String? _error;

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;

    if (hours < 0 || minutes < 0 || minutes > 59) {
      setState(() {
        _error = 'Please enter valid hours and minutes.';
        _plan = null;
      });
      return;
    }

    final totalMinutes = (hours * 60) + minutes;

    if (totalMinutes <= 0) {
      setState(() {
        _error = 'Please select at least 1 minute.';
        _plan = null;
      });
      return;
    }

    if (widget.tasks.where((task) => !task.isCompleted).isEmpty) {
      setState(() {
        _error = 'Add a pending task first to generate your plan.';
        _plan = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _plan = StudyPlannerService.generate(
        tasks: widget.tasks,
        availableMinutes: totalMinutes,
      );
    });
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';

    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Plan My Study Day ✨',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'How much time do you have available today?',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _timeInput(
                      controller: _hoursController,
                      label: 'Hours',
                      hint: '2',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeInput(
                      controller: _minutesController,
                      label: 'Minutes',
                      hint: '0',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generatePlan,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate My Plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sage,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.red),
                ),
              ],

              if (_plan != null) ...[
                const SizedBox(height: 24),
                _buildPlan(_plan!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: label == 'Hours' ? 'hr' : 'min',
            filled: true,
            fillColor: AppColors.sageLight.withOpacity(.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlan(StudyPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your study schedule',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sageLight.withOpacity(.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryValue('Study', _formatMinutes(plan.totalStudyMinutes)),
              _summaryValue('Breaks', _formatMinutes(plan.totalBreakMinutes)),
              _summaryValue(
                'Total',
                _formatMinutes(plan.totalPlannedMinutes),
              ),
            ],
          ),
        ),

        const SizedBox(height: 17),

        if (plan.items.isEmpty)
          const Text(
            'No tasks could fit into the selected time. Try choosing more time.',
            style: TextStyle(color: AppColors.muted),
          ),

        ...plan.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.sageLight),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.sageLight,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            item.task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          _formatMinutes(item.plannedMinutes),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.sage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${item.task.subject} • ${item.task.taskType}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    if (item.isPartial) ...[
                      const SizedBox(height: 7),
                      const Text(
                        'Partial study block — continue this task later.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final task = item.task;
                          Navigator.pop(context);
                          widget.onStartFocus(task);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Session'),
                      ),
                    ),
                  ],
                ),
              ),

              if (item.breakAfterMinutes > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.coffee_rounded,
                        size: 18,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${item.breakAfterMinutes}-minute break',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),

        if (plan.remainingTasks.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Save for later',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ...plan.remainingTasks.map(
            (task) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.sage,
              ),
              title: Text(task.title),
              subtitle: Text(task.subject),
              dense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryValue(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
