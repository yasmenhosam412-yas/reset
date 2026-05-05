import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

class ProfileStatsOverviewRow extends StatelessWidget {
  const ProfileStatsOverviewRow({
    super.key,
    required this.theme,
    required this.scheme,
    required this.stats,
    this.onPostsTap,
    this.onFriendsTap,
    this.onChallengesTap,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final UserProfileStats stats;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onChallengesTap;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (Icons.article_outlined, 'Posts', stats.postsCount, () {
        onPostsTap?.call();
      }),
      (Icons.groups_outlined, 'Friends', stats.friendsCount, () {
        onFriendsTap?.call();
      }),
      (
        Icons.sports_esports_outlined,
        'Challenges',
        stats.challengesCount,
        () {
          onChallengesTap?.call();
        },
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ProfileStatTile(
              icon: tiles[i].$1,
              label: tiles[i].$2,
              value: '${tiles[i].$3}',
              scheme: scheme,
              theme: theme,
              onTap: tiles[i].$4,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
