import 'package:flutter/material.dart';

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
            title: const Text('Push notifications'),
            subtitle: const Text('Scores, invites, and reminders'),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: matchInvites,
            onChanged: onMatchInvitesChanged,
            secondary: Icon(
              Icons.mail_outline_rounded,
              color: scheme.primary,
            ),
            title: const Text('Match invites'),
            subtitle: const Text('Friends can invite you to play'),
          ),
        ],
      ),
    );
  }
}
