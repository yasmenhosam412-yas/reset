import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM does not show a system notification on Android while the app is in the
/// foreground. This uses [flutter_local_notifications] to mirror server pushes
/// in the tray (and improves consistency on iOS when the app is active).
abstract final class ForegroundPushNotifications {
  static const _channelId = 'social_ball_push';
  static const _channelName = 'Notifications';
  static const _channelDescription =
      'Likes, comments, friend requests, and game invites.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Shared by other features (e.g. scheduled digests) after [register].
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static bool _registered = false;

  static Future<void> register() async {
    if (kIsWeb || _registered) return;
    _registered = true;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await androidImpl?.requestNotificationsPermission();
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  static int _notificationId(RemoteMessage m) {
    final mid = m.messageId;
    if (mid != null && mid.isNotEmpty) {
      return mid.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }

  static Future<bool> _profileAllowsPushMirror() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await Supabase.instance.client
          .from(HomeTable.profiles)
          .select(ProfileCols.pushNotificationsEnabled)
          .eq(ProfileCols.id, uid)
          .maybeSingle();
      if (row == null) return true;
      final v = row[ProfileCols.pushNotificationsEnabled];
      if (v is bool) return v;
      if (v is num) return v != 0;
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (!await _profileAllowsPushMirror()) {
      return;
    }
    final n = message.notification;
    final title =
        n?.title ?? (message.data['title'] as String?) ?? 'Notification';
    final body = n?.body ?? (message.data['body'] as String?) ?? '';

    await _plugin.show(
      id: _notificationId(message),
      title: title,
      body: body.isEmpty ? null : body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          // Omit FCM android.smallIcon — may not match a drawable in this app.
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }
}
