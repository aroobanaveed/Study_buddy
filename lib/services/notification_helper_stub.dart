
Future<bool> requestPermission() async => false;

Future<void> showNotification({
  required String title,
  required String message,
}) async {}

Future<void> scheduleReminder({
  required int id,
  required String title,
  required String message,
  required DateTime reminderTime,
}) async {}

Future<void> cancelReminder(int id) async {}

Future<void> cancelAllReminders() async {}

Future<void> playReminderSound() async {}
