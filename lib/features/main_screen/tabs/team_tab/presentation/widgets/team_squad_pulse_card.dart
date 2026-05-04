import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/constants/team_stat_colors.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_squad_scoring.dart';

/// At-a-glance squad strength using the same formulas as weekly lineup races.
class TeamSquadPulseCard extends StatelessWidget {
  const TeamSquadPulseCard({
    super.key,
    required this.players,
    required this.formationLabel,
  });

  final List<TeamRosterPlayer> players;
  final String formationLabel;

  @override
  Widget build(BuildContext context) {
    if (players.length != 6) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final power = squadPowerScore(players);
    final speed = squadSpeedDashScore(players);
    final balance = squadBalanceScore(players);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.tertiaryContainer.withValues(alpha: 0.45),
              scheme.primaryContainer.withValues(alpha: 0.35),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Squad pulse',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      formationLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Live preview of the three weekly race modes — train, then climb the shared leaderboard.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              _ScoreBar(
                label: 'Power race',
                value: power,
                max: kSquadPowerScoreMax,
                accent: TeamStatColors.attack,
                scheme: scheme,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _ScoreBar(
                label: 'Speed dash',
                value: speed,
                max: kSquadSpeedDashScoreMax,
                accent: TeamStatColors.speed,
                scheme: scheme,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _ScoreBar(
                label: 'Balance',
                value: balance,
                max: kSquadBalanceScoreMax,
                accent: TeamStatColors.defense,
                scheme: scheme,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.max,
    required this.accent,
    required this.scheme,
    required this.theme,
  });

  final String label;
  final int value;
  final int max;
  final Color accent;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final frac = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: scheme.surface.withValues(alpha: 0.55),
            color: accent,
          ),
        ),
      ],
    );
  }
}
