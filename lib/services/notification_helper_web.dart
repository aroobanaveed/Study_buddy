
import 'dart:html' as html;

Future<bool> requestPermission() async {
  if (!html.Notification.supported) return false;
  final permission = await html.Notification.requestPermission();
  return permission == 'granted';
}

Future<void> showNotification({
  required String title,
  required String message,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  html.Notification(title, body: message);
}

Future<void> scheduleReminder({
  required int id,
  required String title,
  required String message,
  required DateTime reminderTime,
}) async {}

Future<void> cancelReminder(int id) async {}

Future<void> cancelAllReminders() async {}

Future<void> playReminderSound() async {
  try {
    final audio = html.AudioElement(
      'https://actions.google.com/sounds/v1/cartoon/mechanical_clock_ring.ogg',
    );
    audio.volume = 0.5;
    await audio.play();
  } catch (e) {}
}
