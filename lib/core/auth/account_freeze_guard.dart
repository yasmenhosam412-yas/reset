import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens for session events and signs out when [ProfileCols.frozenUntil] is in the future.
void registerAccountFreezeGuard(
  SupabaseClient client, {
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
}) {
  client.auth.onAuthStateChange.listen((data) async {
    final session = data.session;
    if (session == null) return;

    switch (data.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        break;
      default:
        return;
    }

    try {
      final row = await client
          .from(HomeTable.profiles)
          .select(ProfileCols.frozenUntil)
          .eq(ProfileCols.id, session.user.id)
          .maybeSingle();

      final raw = row?[ProfileCols.frozenUntil];
      if (raw == null) return;

      DateTime? until;
      if (raw is String) {
        until = DateTime.tryParse(raw);
      } else if (raw is DateTime) {
        until = raw;
      }
      if (until == null) return;

      if (until.isAfter(DateTime.now().toUtc())) {
        await client.auth.signOut();
        final messenger = scaffoldMessengerKey?.currentState;
        if (messenger != null && messenger.mounted) {
          final local = until.toLocal();
          final y = local.year.toString().padLeft(4, '0');
          final mo = local.month.toString().padLeft(2, '0');
          final da = local.day.toString().padLeft(2, '0');
          final h = local.hour.toString().padLeft(2, '0');
          final mi = local.minute.toString().padLeft(2, '0');
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'This account is suspended until $y-$mo-$da $h:$mi (local time).',
              ),
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('AccountFreezeGuard: $e\n$st');
    }
  });
}
