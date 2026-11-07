import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_task.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.task});
  final StudyTask? task;
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subject;
  late final TextEditingController _minutes;
  late String _type;
  late int _difficulty;
  int? _confidence;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _subject = TextEditingController(text: t?.subject ?? '');
    _minutes = TextEditingController(text: (t?.estimatedMinutes ?? 30).toString());
    _type = t?.taskType ?? 'Revision';
    _difficulty = t?.difficulty ?? 2;
    _confidence = t?.confidence;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() { _title.dispose(); _subject.dispose(); _minutes.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 18), Text(widget.task == null ? 'Add a study task ✨' : 'Edit your task', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6), const Text('Break big goals into small, doable steps.', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 20),
      TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Task or chapter name', prefixIcon: Icon(Icons.menu_book_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a task name' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.school_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Task type'), items: const ['Exam', 'Assignment', 'Revision', 'Project', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => _type = v ?? 'Revision')),
      const SizedBox(height: 12),
      TextFormField(controller: _minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated time (minutes)', prefixIcon: Icon(Icons.timer_outlined)), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 1 || n > 1440 ? 'Enter a time from 1 to 1440 minutes' : null; }),
      const SizedBox(height: 14),
      const Text('How difficult is it?', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 1, label: Text('Easy')), ButtonSegment(value: 2, label: Text('Medium')), ButtonSegment(value: 3, label: Text('Hard'))], selected: {_difficulty}, onSelectionChanged: (s) => setState(() => _difficulty = s.first)),
      const SizedBox(height: 14),
      const Text('How confident do you feel? (optional)', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('😕 Confused'), selected: _confidence == 1, onSelected: (_) => setState(() => _confidence = _confidence == 1 ? null : 1)),
        ChoiceChip(label: const Text('😐 Learning'), selected: _confidence == 2, onSelected: (_) => setState(() => _confidence = _confidence == 2 ? null : 2)),
        ChoiceChip(label: const Text('😊 Confident'), selected: _confidence == 3, onSelected: (_) => setState(() => _confidence = _confidence == 3 ? null : 3)),
      ]),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () async {
        final selected = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100), helpText: 'Choose a deadline');
        if (selected != null) setState(() => _dueDate = selected);
      }, icon: const Icon(Icons.calendar_month_outlined), label: Text(_dueDate == null ? 'Add deadline (optional)' : 'Due ${DateFormat('EEE, MMM d, yyyy').format(_dueDate!)}')),
      if (_dueDate != null) TextButton(onPressed: () => setState(() => _dueDate = null), child: const Text('Remove deadline')),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () {
        if (!_formKey.currentState!.validate()) return;
        final now = DateTime.now();
        final old = widget.task;
        final task = StudyTask(
          id: old?.id,
          title: _title.text.trim(), subject: _subject.text.trim(), taskType: _type,
          dueDate: _dueDate, estimatedMinutes: int.parse(_minutes.text), difficulty: _difficulty,
          confidence: _confidence, status: old?.status ?? 'pending', createdAt: old?.createdAt ?? now,
          completedAt: old?.completedAt,
        );
        Navigator.pop(context, task);
      }, icon: const Icon(Icons.check_rounded), label: Text(widget.task == null ? 'Save task' : 'Save changes'))),
    ]))),
  ));
}
