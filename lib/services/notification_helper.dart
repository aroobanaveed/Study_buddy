import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

import 'notification_helper_stub.dart'
    if (dart.library.html) 'notification_helper_web.dart'
    if (dart.library.io) 'notification_helper_android.dart' as platform;

class NotificationHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<bool> requestPermission() =>
      platform.requestPermission();

  static Future<void> show({
    required String title,
    required String message,
  }) =>
      platform.showNotification(title: title, message: message);

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String message,
    required DateTime reminderTime,
  }) =>
      platform.scheduleReminder(
        id: id,
        title: title,
        message: message,
        reminderTime: reminderTime,
      );

  static Future<void> cancelReminder(int id) =>
      platform.cancelReminder(id);

  static Future<void> cancelAllReminders() =>
      platform.cancelAllReminders();

  static Future<void> playReminderSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/reminder.ogg'),
      );
    } catch (e) {
      debugPrint('Reminder sound error: $e');
    }
  }

  static Future<void> stopReminderSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Stop reminder sound error: $e');
    }
  }
}
