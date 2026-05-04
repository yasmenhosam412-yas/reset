import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/constants/team_stat_colors.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_ui_utils.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_stat_mini_bar.dart';

class TeamPlayerToken extends StatelessWidget {
  const TeamPlayerToken({
    super.key,
    required this.player,
    this.onTap,
  });

  final TeamRosterPlayer player;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final p = player;
    final avatarProv = _teamAvatarImageProvider(p.avatarBase64);

    final card = Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.94 : 1),
            scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.55,
            ),
          ],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                  ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.surface,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: teamAvatarColor(p.name),
                        foregroundColor: Colors.white,
                        backgroundImage: avatarProv,
                        child: avatarProv == null
                            ? Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              )
                            : null,
                      ),
                    ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (onTap != null)
                        Text(
                          'Tap to edit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TeamStatMiniBar(
                  label: 'ATK',
                  value: p.attack,
                  accent: TeamStatColors.attack,
                ),
                const SizedBox(width: 3),
                TeamStatMiniBar(
                  label: 'DEF',
                  value: p.defense,
                  accent: TeamStatColors.defense,
                ),
                const SizedBox(width: 3),
                TeamStatMiniBar(
                  label: 'SPD',
                  value: p.speed,
                  accent: TeamStatColors.speed,
                ),
                const SizedBox(width: 3),
                TeamStatMiniBar(
                  label: 'STM',
                  value: p.stamina,
                  accent: TeamStatColors.stamina,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: card,
            )
          : card,
    );
  }
}

ImageProvider? _teamAvatarImageProvider(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  try {
    return MemoryImage(base64Decode(b64));
  } catch (_) {
    return null;
  }
}
