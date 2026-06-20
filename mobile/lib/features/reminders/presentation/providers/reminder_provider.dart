import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/theme_provider.dart' show sharedPreferencesProvider;

/// Injected in `main` after [NotificationService.init].
final notificationServiceProvider = Provider<NotificationService>(
  (_) => throw UnimplementedError(),
);

const _kEnabled = 'reminder_enabled';
const _kHour = 'reminder_hour';
const _kMinute = 'reminder_minute';

/// Default reminder time: 9:00 PM.
const _defaultTime = TimeOfDay(hour: 21, minute: 0);

@immutable
class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.time});

  final bool enabled;
  final TimeOfDay time;

  ReminderSettings copyWith({bool? enabled, TimeOfDay? time}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        time: time ?? this.time,
      );
}

class ReminderNotifier extends StateNotifier<ReminderSettings> {
  ReminderNotifier(this._ref) : super(_load(_ref)) {
    // If a reminder was enabled in a previous session, make sure it is
    // (re)scheduled on startup — covers reinstalls and cancelled alarms.
    if (state.enabled) {
      _service.scheduleDailyReminder(state.time);
    }
  }

  final Ref _ref;

  NotificationService get _service => _ref.read(notificationServiceProvider);

  static ReminderSettings _load(Ref ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final hour = prefs.getInt(_kHour) ?? _defaultTime.hour;
    final minute = prefs.getInt(_kMinute) ?? _defaultTime.minute;
    return ReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  /// Turns the reminder on/off. When turning on, requests OS permission first.
  /// Returns `false` if permission was denied (state stays off).
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _service.requestPermission();
      if (!granted) return false;
      await _service.scheduleDailyReminder(state.time);
    } else {
      await _service.cancelReminder();
    }
    _persist(enabled: enabled);
    state = state.copyWith(enabled: enabled);
    return true;
  }

  Future<void> setTime(TimeOfDay time) async {
    _persist(time: time);
    state = state.copyWith(time: time);
    if (state.enabled) {
      await _service.scheduleDailyReminder(time);
    }
  }

  void _persist({bool? enabled, TimeOfDay? time}) {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (enabled != null) prefs.setBool(_kEnabled, enabled);
    if (time != null) {
      prefs.setInt(_kHour, time.hour);
      prefs.setInt(_kMinute, time.minute);
    }
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderSettings>((ref) {
  return ReminderNotifier(ref);
});
