import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] for the daily expense/savings
/// reminder. A single recurring notification (id [_reminderId]) is scheduled at
/// the user-chosen time and repeats every day at that local time.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderId = 1001;
  static const int _secondReminderId = 1003;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Daily reminder';
  static const String _channelDesc =
      'Reminds you to log your expenses and savings.';

  /// Called when the user taps a reminder. Set by the app once the router is
  /// available so taps can deep-link into the add-expense flow.
  void Function(String? payload)? onTap;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't request iOS permissions on init; we ask explicitly when the user
    // enables the reminder so the prompt is contextual.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) => onTap?.call(
        response.payload,
      ),
    );

    _initialized = true;
  }

  /// Requests OS notification permission. Returns whether it is granted.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Whether notifications are currently authorized at the OS level.
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    return false;
  }

  /// (Re)schedules the primary daily reminder at [time], cancelling any prior
  /// one. Use [scheduleSecondReminder] for the optional second reminder.
  Future<void> scheduleDailyReminder(TimeOfDay time) =>
      _schedule(_reminderId, time);

  /// (Re)schedules the optional second daily reminder at [time].
  Future<void> scheduleSecondReminder(TimeOfDay time) =>
      _schedule(_secondReminderId, time);

  Future<void> _schedule(int id, TimeOfDay time) async {
    await _plugin.cancel(id);

    await _plugin.zonedSchedule(
      id,
      'Log today\'s spending',
      'Take a moment to record your expenses and savings for today.',
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'add_expense',
    );
  }

  /// Cancels both the primary and optional second daily reminders.
  Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderId);
    await _plugin.cancel(_secondReminderId);
  }

  /// Cancels only the optional second daily reminder.
  Future<void> cancelSecondReminder() => _plugin.cancel(_secondReminderId);

  /// Fires a one-off notification immediately, for the "send test" action.
  Future<void> showTestNotification() async {
    await _plugin.show(
      _reminderId + 1,
      'Reminders are on',
      'This is what your daily reminder will look like.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'add_expense',
    );
  }

  /// Next [time] occurrence in local tz; rolls to tomorrow if already passed.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
