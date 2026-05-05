import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:new_project/core/push/foreground_local_notifications.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battle_daily_digest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Daily local notification at **12:00 PM** (device timezone) for global battle results.
abstract final class GlobalBattleDigestNotifications {
  static const _notifId = 91001;
  static const _channelId = 'global_battle_daily_digest';
  static const _channelName = 'Daily battle results';
  static const _channelDescription =
      'Noon summary of yesterday’s global battle champions.';

  static Future<void> ensureScheduled() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    try {
      tzdata.initializeTimeZones();
      var tzName = 'UTC';
      try {
        tzName = await FlutterTimezone.getLocalTimezone();
      } catch (_) {}
      tz.Location location;
      try {
        location = tz.getLocation(tzName);
      } catch (_) {
        location = tz.getLocation('UTC');
      }
      tz.setLocalLocation(location);

      final plugin = ForegroundPushNotifications.plugin;

      final androidImpl = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.defaultImportance,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs
          .getString(GlobalBattleDigestPrefs.summaryKey)
          ?.trim();
      final body = (cached == null || cached.isEmpty)
          ? 'Open the Team tab to see yesterday’s global battle winners.'
          : cached;

      await plugin.cancel(id: _notifId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        12,
        0,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'splash',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await plugin.zonedSchedule(
        id: _notifId,
        title: 'Daily global battle champions',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation.localTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'global_battle_digest',
      );
    } catch (e, st) {
      debugPrint('GlobalBattleDigestNotifications: $e\n$st');
    }
  }
}
