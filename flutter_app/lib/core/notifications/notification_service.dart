import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps `flutter_local_notifications` behind a small, purpose-specific
/// API. No backend involved — every notification is scheduled entirely
/// on-device (product spec §24).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      // Fall back to UTC if the platform can't resolve a local timezone;
      // notifications will still fire, just without DST-aware offsets.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'studai_reminders',
    'Reminders',
    channelDescription:
        'Homework deadlines, tests, lessons, and study sessions',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Stable, deterministic int ID derived from a string ID (homework id,
  /// lesson id, etc.) plus a purpose salt, so re-scheduling the same
  /// entity's notification overwrites rather than duplicates it.
  int _idFor(String sourceId, int salt) =>
      (sourceId.hashCode ^ salt) & 0x7FFFFFFF;

  Future<void> scheduleHomeworkDeadline({
    required String homeworkId,
    required String title,
    required String body,
    required DateTime deadline,
    required int minutesBefore,
  }) async {
    final fireAt = deadline.subtract(Duration(minutes: minutesBefore));
    if (fireAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _idFor(homeworkId, 1),
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleLesson({
    required String lessonId,
    required String title,
    required String body,
    required DateTime nextOccurrence,
    required int minutesBefore,
  }) async {
    final fireAt = nextOccurrence.subtract(Duration(minutes: minutesBefore));
    if (fireAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _idFor(lessonId, 2),
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleTestReminder({
    required String testId,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    if (fireAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _idFor(testId, 3),
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showOverdueNotification({
    required String homeworkId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(_idFor(homeworkId, 4), title, body, _details);
  }

  Future<void> cancelForHomework(String homeworkId) async {
    await _plugin.cancel(_idFor(homeworkId, 1));
    await _plugin.cancel(_idFor(homeworkId, 4));
  }

  Future<void> cancelForLesson(String lessonId) async {
    await _plugin.cancel(_idFor(lessonId, 2));
  }

  Future<void> cancelForTest(String testId) async {
    await _plugin.cancel(_idFor(testId, 3));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
