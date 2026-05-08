import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.theme,
    required this.scheme,
    required this.dashboard,
    required this.onEditTap,
    this.editBusy = false,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final ProfileDashboardModel dashboard;
  final VoidCallback onEditTap;
  final bool editBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = dashboard.user;
    final displayName = user.username.trim().isEmpty
        ? l10n.player
        : user.username;
   
    final avatarUrl = user.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final email = dashboard.email;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.08),
              scheme.surfaceContainerHighest.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: hasAvatar
                        ? scheme.surfaceContainerHighest
                        : scheme.primaryContainer,
                    foregroundColor: hasAvatar
                        ? null
                        : scheme.onPrimaryContainer,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: editBusy ? null : onEditTap,
                icon: editBusy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onSecondaryContainer,
                        ),
                      )
                    : const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.editProfile),
              ),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String handleFromProfileEmail(String? email, {required String fallbackBase}) {
  if (email != null && email.contains('@')) {
    return '@${email.split('@').first}';
  }
  return '@$fallbackBase';
}
