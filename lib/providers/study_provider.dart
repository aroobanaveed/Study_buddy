
import 'package:flutter/foundation.dart';

import '../data/study_repository.dart';
import '../models/study_session.dart';
import '../models/study_task.dart';
import '../models/sticky_note.dart';
import '../models/study_reminder.dart';
import '../services/notification_helper.dart';

class StudyProvider extends ChangeNotifier {
  StudyProvider(this._repository);

  final StudyRepository _repository;

  List<StudyTask> _tasks = [];
  List<StudySession> _sessions = [];
  List<StickyNote> _notes = [];
  List<StudyReminder> _reminders = [];

  bool _loading = true;
  String? _error;

  List<StudyTask> get tasks => List.unmodifiable(_tasks);
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  List<StickyNote> get notes => List.unmodifiable(_notes);
  List<StudyReminder> get reminders => List.unmodifiable(_reminders);

  bool get loading => _loading;
  String? get error => _error;

  // ---------------- NOTIFICATION SYNC ----------------

  Future<void> _scheduleReminder(StudyReminder reminder) async {
    if (kIsWeb || reminder.id == null) return;

    if (!reminder.isActive ||
        reminder.isSent ||
        !reminder.reminderTime.isAfter(DateTime.now())) {
      await NotificationHelper.cancelReminder(reminder.id!);
      return;
    }

    await NotificationHelper.scheduleReminder(
      id: reminder.id!,
      title: 'StudyBuddy Reminder 🌼',
      message: reminder.message,
      reminderTime: reminder.reminderTime,
    );
  }

  Future<void> _syncAllReminders() async {
    if (kIsWeb) return;

    for (final reminder in _reminders) {
      try {
        await _scheduleReminder(reminder);
      } catch (e) {
        debugPrint('Reminder sync error (${reminder.id}): $e');
      }
    }
  }

  // ---------------- LOAD DATA ----------------

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
      _sessions = await _repository.getSessions();
      _notes = await _repository.getNotes();
      _reminders = await _repository.getReminders();

      await _syncAllReminders();

      _error = null;
    } catch (e) {
      _error = 'Could not load saved study data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------------- TASKS ----------------

  Future<void> addTask(StudyTask task) async {
    await _repository.insertTask(task);
    await _refresh();
  }

  Future<void> updateTask(StudyTask task) async {
    await _repository.updateTask(task);
    await _refresh();
  }

  Future<void> toggleTask(StudyTask task, bool completed) async {
    await updateTask(task.copyWith(
      status: completed ? 'completed' : 'pending',
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    ));

    if (completed && task.id != null) {
      final taskReminders = _reminders
          .where((r) =>
              r.taskId == task.id && r.isActive && !r.isSent)
          .toList();

      for (final reminder in taskReminders) {
        await _repository.updateReminder(
          reminder.copyWith(isActive: false),
        );

        if (!kIsWeb && reminder.id != null) {
          await NotificationHelper.cancelReminder(reminder.id!);
        }
      }

      await _refresh();
    }
  }

  Future<void> deleteTask(StudyTask task) async {
    if (task.id == null) return;

    final taskReminders = _reminders
        .where((r) => r.taskId == task.id)
        .toList();

    for (final reminder in taskReminders) {
      if (!kIsWeb && reminder.id != null) {
        await NotificationHelper.cancelReminder(reminder.id!);
      }
    }

    await _repository.deleteTask(task.id!);
    await _refresh();
  }

  // ---------------- STUDY SESSIONS ----------------

  Future<void> recordSession({
    required int? taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required String status,
    int? confidenceAfter,
  }) async {
    if (durationSeconds <= 0) return;

    await _repository.insertSession(StudySession(
      taskId: taskId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      sessionStatus: status,
      confidenceAfter: confidenceAfter,
    ));

    await _refresh();

    if (taskId != null && confidenceAfter != null) {
      final matching = _tasks.where((t) => t.id == taskId).toList();

      if (matching.isNotEmpty) {
        await updateTask(
          matching.first.copyWith(confidence: confidenceAfter),
        );
      }
    }
  }

  // ---------------- STICKY NOTES ----------------

  Future<void> addNote(StickyNote note) async {
    await _repository.insertNote(note);
    await _refresh();
  }

  Future<void> updateNote(StickyNote note) async {
    await _repository.updateNote(
      note.copyWith(updatedAt: DateTime.now()),
    );
    await _refresh();
  }

  Future<void> deleteNote(StickyNote note) async {
    if (note.id == null) return;

    await _repository.deleteNote(note.id!);
    await _refresh();
  }

  Future<void> toggleNotePin(StickyNote note) async {
    if (note.id == null) return;

    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  // ---------------- STUDY REMINDERS ----------------

  Future<void> addReminder(StudyReminder reminder) async {
    if (!kIsWeb) {
      await NotificationHelper.requestPermission();
    }

    final insertedId = await _repository.insertReminder(reminder);

    final savedReminder = reminder.copyWith(id: insertedId);

    _reminders = await _repository.getReminders();
    notifyListeners();

    await _scheduleReminder(savedReminder);
  }

  Future<void> updateReminder(StudyReminder reminder) async {
    await _repository.updateReminder(reminder);
    await _scheduleReminder(reminder);
    await _refresh();
  }

  Future<void> deleteReminder(StudyReminder reminder) async {
    if (reminder.id == null) return;

    if (!kIsWeb) {
      await NotificationHelper.cancelReminder(reminder.id!);
    }

    await _repository.deleteReminder(reminder.id!);
    await _refresh();
  }

  // ---------------- REFRESH DATA ----------------

  Future<void> _refresh() async {
    _tasks = await _repository.getTasks();
    _sessions = await _repository.getSessions();
    _notes = await _repository.getNotes();
    _reminders = await _repository.getReminders();

    notifyListeners();
  }
}
