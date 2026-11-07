
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<void>? _initialization;

Future<void> _initializeNotifications() {
  return _initialization ??= _initialize();
}

Future<void> _initialize() async {
  tz_data.initializeTimeZones();

  // Pakistan Standard Time (UTC+5)
  tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

  await _notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    ),
  );
}

Future<bool> requestPermission() async {
  await _initializeNotifications();

  final androidPlugin = _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return false;

  // Check notification permission before requesting it.
  final notificationsEnabled =
      await androidPlugin.areNotificationsEnabled();

  bool notificationGranted = notificationsEnabled ?? false;

  if (!notificationGranted) {
    notificationGranted =
        await androidPlugin.requestNotificationsPermission() ?? false;
  }

  // Check exact alarm permission before requesting it.
  bool exactAlarmGranted =
      await androidPlugin.canScheduleExactNotifications() ?? false;

  if (!exactAlarmGranted) {
    await androidPlugin.requestExactAlarmsPermission();

    exactAlarmGranted =
        await androidPlugin.canScheduleExactNotifications() ?? false;
  }

  return notificationGranted && exactAlarmGranted;
}

const AndroidNotificationDetails _androidDetails =
    AndroidNotificationDetails(
  'studybuddy_reminders',
  'StudyBuddy Reminders',
  channelDescription: 'Notifications for study reminders',
  importance: Importance.max,
  priority: Priority.high,
);

Future<void> showNotification({
  required String title,
  required String message,
}) async {
  await _initializeNotifications();

  const details = NotificationDetails(
    android: _androidDetails,
  );

  final notificationId =
      ('${title}_$message').hashCode & 0x7fffffff;

  await _notifications.show(
    notificationId,
    title,
    message,
    details,
  );
}

Future<void> scheduleReminder({
  required int id,
  required String title,
  required String message,
  required DateTime reminderTime,
}) async {
  await _initializeNotifications();

  final scheduledTime = tz.TZDateTime.from(
    reminderTime,
    tz.local,
  );

  if (!scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
    await _notifications.cancel(id);
    return;
  }

  final androidPlugin = _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  final canUseExactAlarms =
      await androidPlugin?.canScheduleExactNotifications() ?? false;

  await _notifications.zonedSchedule(
    id,
    title,
    message,
    scheduledTime,
    const NotificationDetails(
      android: _androidDetails,
    ),
    androidScheduleMode: canUseExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

Future<void> cancelReminder(int id) async {
  await _initializeNotifications();
  await _notifications.cancel(id);
}

Future<void> cancelAllReminders() async {
  await _initializeNotifications();
  await _notifications.cancelAll();
}

Future<void> playReminderSound() async {}
