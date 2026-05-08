import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/constants/team_stat_colors.dart';

const int kTeamTrainingCost = 15;

/// Spend [kTeamTrainingCost] skill points for +1 on one stat (server-side, max 99).
class TeamSkillTrainingStrip extends StatelessWidget {
  const TeamSkillTrainingStrip({
    super.key,
    required this.players,
    required this.skillPoints,
    required this.selectedSlot,
    required this.busy,
    required this.onSlotChanged,
    required this.onTrain,
  });

  final List<TeamRosterPlayer> players;
  final int skillPoints;
  final int selectedSlot;
  final bool busy;
  final ValueChanged<int> onSlotChanged;
  final void Function(String statKey) onTrain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    if (players.length != 6) return const SizedBox.shrink();

    final p = players[selectedSlot.clamp(0, 5)];
    final canAfford = skillPoints >= kTeamTrainingCost;

    Widget trainChip(String label, String key, int value, Color color) {
      final maxed = value >= 99;
      return Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: ActionChip(
          avatar: Icon(Icons.add_rounded, size: 18, color: color),
          label: Text(l10n.teamStatPlusOne(label)),
          onPressed: busy || !canAfford || maxed ? null : () => onTrain(key),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.teamSkillTrainingTitle(kTeamTrainingCost),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.teamPlayerTrainingBalance(
                  selectedSlot + 1,
                  p.name,
                  skillPoints,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: List.generate(6, (i) {
                  final sel = i == selectedSlot;
                  return ChoiceChip(
                    label: Text('${i + 1}'),
                    selected: sel,
                    onSelected: busy ? null : (_) => onSlotChanged(i),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  trainChip(
                    l10n.teamAttackShort,
                    'attack',
                    p.attack,
                    TeamStatColors.attack,
                  ),
                  trainChip(
                    l10n.teamDefenseShort,
                    'defense',
                    p.defense,
                    TeamStatColors.defense,
                  ),
                  trainChip('SPD', 'speed', p.speed, TeamStatColors.speed),
                  trainChip('STM', 'stamina', p.stamina, TeamStatColors.stamina),
                ],
              ),
              if (!canAfford)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.teamEarnMoreFromDailyChallenges,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
