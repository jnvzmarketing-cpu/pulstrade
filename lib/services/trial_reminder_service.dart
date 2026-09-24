// Schedules a local "your trial ends in 2 days" reminder — the single
// strongest trust element of the Cal-AI paywall pattern. No charge
// surprise → fewer refunds, fewer 1-star reviews.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class TrialReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _notifId = 7001;

  static Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    await _plugin.initialize(
        settings: const InitializationSettings(iOS: ios, android: android));
    _initialized = true;
  }

  /// Schedule the reminder for day 5 of a 7-day trial.
  static Future<void> scheduleTrialEndingReminder({int trialDays = 7}) async {
    try {
      await _init();
      final when = tz.TZDateTime.now(tz.local).add(Duration(days: trialDays - 2));
      await _plugin.zonedSchedule(
        id: _notifId,
        title: 'Your trial ends in 2 days',
        body: 'Cancel anytime in Settings — or keep your edge and do nothing.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'trial_reminders',
            'Trial reminders',
            channelDescription: 'Reminder before your free trial ends',
            importance: Importance.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('⏰ trial reminder scheduled for $when');
    } catch (e) {
      debugPrint('trial reminder scheduling failed: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await _init();
      await _plugin.cancel(id: _notifId);
    } catch (_) {}
  }
}
