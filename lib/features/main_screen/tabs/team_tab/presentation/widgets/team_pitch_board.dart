import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_pitch_lines_painter.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_player_token.dart';

class TeamPitchBoard extends StatelessWidget {
  const TeamPitchBoard({
    super.key,
    required this.formationLabel,
    required this.slotRows,
    required this.players,
    this.onPlayerTap,
  });

  final String formationLabel;
  final List<List<int>> slotRows;
  final List<TeamRosterPlayer> players;
  final ValueChanged<int>? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pitchDeep = Color.lerp(
      const Color(0xFF042F2E),
      scheme.surfaceContainerLow,
      isDark ? 0.08 : 0.55,
    )!;
    final pitchLight = Color.lerp(
      const Color(0xFF0F766E),
      scheme.primaryContainer,
      isDark ? 0.25 : 0.4,
    )!;

    return AspectRatio(
      aspectRatio: 0.74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [pitchLight, pitchDeep],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: TeamPitchLinesPainter(
                  line: Colors.white.withValues(alpha: 0.22),
                  subtle: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Row(
                children: [
                  _EndZoneTag(theme: theme, text: 'DEF'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formationLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _EndZoneTag(theme: theme, text: 'ATK'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 44, 12, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: slotRows.map((slotIndices) {
                  return Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < slotIndices.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: Center(
                              child: TeamPlayerToken(
                                player: players[slotIndices[i]],
                                onTap: onPlayerTap != null
                                    ? () => onPlayerTap!(slotIndices[i])
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndZoneTag extends StatelessWidget {
  const _EndZoneTag({required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.75),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}
