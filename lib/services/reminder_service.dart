
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/study_reminder.dart';

class ReminderService {
  Timer? _timer;
  bool _isChecking = false;
  bool _disposed = false;

  void start({
    required List<StudyReminder> Function() getReminders,
    required Future<void> Function(StudyReminder reminder) onReminderDue,
  }) {
    stop();
    _disposed = false;

    // Check immediately when service starts.
    _checkReminders(
      getReminders: getReminders,
      onReminderDue: onReminderDue,
    );

    // Check again every 15 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _checkReminders(
          getReminders: getReminders,
          onReminderDue: onReminderDue,
        );
      },
    );
  }

  Future<void> _checkReminders({
    required List<StudyReminder> Function() getReminders,
    required Future<void> Function(StudyReminder reminder) onReminderDue,
  }) async {
    if (_isChecking || _disposed) return;

    _isChecking = true;

    try {
      final now = DateTime.now();

      final dueReminders = getReminders().where((reminder) {
        return reminder.isActive &&
            !reminder.isSent &&
            !reminder.reminderTime.isAfter(now);
      }).toList();

      for (final reminder in dueReminders) {
        if (_disposed) break;

        try {
          await onReminderDue(reminder);
        } catch (e) {
          debugPrint('Reminder processing error: $e');
        }
      }
    } catch (e) {
      debugPrint('Reminder checking error: $e');
    } finally {
      _isChecking = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
  }
}
