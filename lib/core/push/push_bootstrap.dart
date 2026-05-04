import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';

/// Registers FCM, syncs [profiles.fcm_token] when signed in, and listens for refresh.
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
        if (uid != null) unawaited(_writeToken(client, uid, t));
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
    final token = await FirebaseMessaging.instance.getToken();
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

  static Future<void> _writeToken(
    SupabaseClient client,
    String uid,
    String token,
  ) async {
    try {
      await client.from(HomeTable.profiles).update({
        'fcm_token': token,
      }).eq(ProfileCols.id, uid);
      debugPrint('PushBootstrap: saved fcm_token for user $uid');
    } catch (e, st) {
      debugPrint('PushBootstrap: failed to save FCM token: $e\n$st');
    }
  }
}
