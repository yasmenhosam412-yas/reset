import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';

class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({
    super.key,
    required this.scheme,
    required this.pushNotifications,
    required this.matchInvites,
    required this.onPushChanged,
    required this.onMatchInvitesChanged,
  });

  final ColorScheme scheme;
  final bool pushNotifications;
  final bool matchInvites;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onMatchInvitesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: pushNotifications,
            onChanged: onPushChanged,
            secondary: Icon(
              Icons.notifications_active_outlined,
              color: scheme.primary,
            ),
            title: Text(l10n.pushNotifications),
            subtitle: Text(
              l10n.pushNotificationsSubtitle,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: matchInvites,
            onChanged: onMatchInvitesChanged,
            secondary: Icon(
              Icons.mail_outline_rounded,
              color: scheme.primary,
            ),
            title: Text(l10n.matchInvites),
            subtitle: Text(
              l10n.matchInvitesSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
