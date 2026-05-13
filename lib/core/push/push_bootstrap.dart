import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';

/// Registers FCM, syncs [profiles.fcm_token] when signed in, and listens for refresh.
/// Honors [profiles.push_notifications_enabled]: when off, deletes the device token and
/// clears [fcm_token] so the server queue cannot target this device.
class PushBootstrap {
  PushBootstrap._();

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<AuthState>? _authSub;

  static Future<void> register(SupabaseClient client) async {
    if (kIsWeb) return;

    // Subscribe before the first sync so we never miss an early [onAuthStateChange]
    // emission where [event.session] is set but [currentUser] is not updated yet.
    await _authSub?.cancel();
    _authSub = client.auth.onAuthStateChange.listen((event) {
      final uid = event.session?.user.id;
      if (uid != null) {
        unawaited(_syncTokenForUser(client, uid));
      }
    });

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (t) {
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          unawaited(_onTokenRefresh(client, uid, t));
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('PushBootstrap: onTokenRefresh stream error: $e\n$st');
      },
    );

    final initialUid =
        client.auth.currentUser?.id ?? client.auth.currentSession?.user.id;
    await _syncTokenForUser(client, initialUid);
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _authSub?.cancel();
    _authSub = null;
  }

  /// Call after [profiles.push_notifications_enabled] changes (e.g. Profile toggle).
  static Future<void> syncPushPreferenceWithProfile(SupabaseClient client) async {
    if (kIsWeb) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final enabled = await _readPushEnabled(client, uid);
    if (!enabled) {
      await _optOutDeviceAndClearRow(client, uid);
      return;
    }
    await _syncTokenForUser(client, uid);
  }

  static Future<void> _syncTokenForUser(
    SupabaseClient client,
    String? uid,
  ) async {
    if (uid == null) {
      debugPrint(
        'PushBootstrap: skip sync (no signed-in user yet — will run after login)',
      );
      return;
    }
    final enabled = await _readPushEnabled(client, uid);
    if (!enabled) {
      await _optOutDeviceAndClearRow(client, uid);
      return;
    }

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e, st) {
      // e.g. Android SERVICE_NOT_AVAILABLE: no/outdated Google Play services
      // (many emulators), network issues, or misconfigured Firebase.
      debugPrint(
        'PushBootstrap: FCM getToken failed — push unavailable for now ($e). '
        'If on an emulator, use one with Google Play; on device, update Play '
        'Services and check network. Will retry on token refresh or next sign-in.\n'
        '$st',
      );
      return;
    }
    if (token == null || token.isEmpty) {
      debugPrint(
        'PushBootstrap: FCM getToken() was null/empty — physical device, '
        'Firebase config (google-services/GoogleService-Info), and iOS APNs '
        'capability must be set; simulator often has no token.',
      );
      return;
    }
    await _writeToken(client, uid, token);
  }

  static Future<void> _onTokenRefresh(
    SupabaseClient client,
    String uid,
    String newToken,
  ) async {
    final enabled = await _readPushEnabled(client, uid);
    if (!enabled) {
      await _optOutDeviceAndClearRow(client, uid);
      return;
    }
    await _writeToken(client, uid, newToken);
  }

  static Future<bool> _readPushEnabled(
    SupabaseClient client,
    String uid,
  ) async {
    try {
      final row = await client
          .from(HomeTable.profiles)
          .select(ProfileCols.pushNotificationsEnabled)
          .eq(ProfileCols.id, uid)
          .maybeSingle();
      if (row == null) return true;
      final v = row[ProfileCols.pushNotificationsEnabled];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'false' || s == 'f' || s == '0') return false;
      }
      return true;
    } catch (e, st) {
      debugPrint('PushBootstrap: read push flag failed: $e\n$st');
      return true;
    }
  }

  static Future<void> _optOutDeviceAndClearRow(
    SupabaseClient client,
    String uid,
  ) async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      debugPrint('PushBootstrap: deleteToken: $e\n$st');
    }
    try {
      await client.from(HomeTable.profiles).update({
        ProfileCols.fcmToken: null,
      }).eq(ProfileCols.id, uid);
      debugPrint('PushBootstrap: cleared fcm_token (push disabled) for $uid');
    } catch (e, st) {
      debugPrint('PushBootstrap: failed to clear fcm_token: $e\n$st');
    }
  }

  static Future<void> _writeToken(
    SupabaseClient client,
    String uid,
    String token,
  ) async {
    try {
      await client.from(HomeTable.profiles).update({
        ProfileCols.fcmToken: token,
      }).eq(ProfileCols.id, uid);
      debugPrint('PushBootstrap: saved fcm_token for user $uid');
    } catch (e, st) {
      debugPrint('PushBootstrap: failed to save FCM token: $e\n$st');
    }
  }
}
