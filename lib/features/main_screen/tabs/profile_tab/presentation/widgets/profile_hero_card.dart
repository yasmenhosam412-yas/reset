import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.theme,
    required this.scheme,
    required this.dashboard,
    required this.onEditTap,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final ProfileDashboardModel dashboard;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final user = dashboard.user;
    final displayName = user.username.trim().isEmpty ? 'Player' : user.username;
    final handle = handleFromProfileEmail(dashboard.email);
    final avatarUrl = user.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final email = dashboard.email;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: hasAvatar
                  ? scheme.surfaceContainerHighest
                  : scheme.primaryContainer,
              foregroundColor: hasAvatar ? null : scheme.onPrimaryContainer,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    handle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onEditTap,
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

String handleFromProfileEmail(String? email) {
  if (email != null && email.contains('@')) {
    return '@${email.split('@').first}';
  }
  return '@player';
}
