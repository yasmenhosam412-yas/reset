import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/dialogs/team_name_dialog.dart';

class TeamSquadHeader extends StatelessWidget {
  const TeamSquadHeader({
    super.key,
    required this.teamName,
    required this.formationLabel,
    required this.onTeamRenamed,
    this.skillPoints = 0,
  });

  final String teamName;
  final String formationLabel;
  final ValueChanged<String> onTeamRenamed;
  final int skillPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, scheme.tertiary, 0.45)!,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.hexagon_outlined,
                size: 120,
                color: scheme.onPrimary.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 12, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.yourSquad,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _HeaderChip(
                              scheme: scheme,
                              icon: Icons.groups_rounded,
                              label: l10n.playersMax(6),
                            ),
                            _HeaderChip(
                              scheme: scheme,
                              icon: Icons.grid_view_rounded,
                              label: formationLabel,
                            ),
                            _HeaderChip(
                              scheme: scheme,
                              icon: Icons.stars_rounded,
                              label: l10n.teamSkillPointsLabel(skillPoints),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.onPrimary.withValues(alpha: 0.18),
                      foregroundColor: scheme.onPrimary,
                    ),
                    tooltip: l10n.teamRenameTeam,
                    onPressed: () async {
                      final next = await showTeamNameDialog(
                        context,
                        title: l10n.teamRenameTeam,
                        initialValue: teamName,
                        labelText: l10n.teamName,
                        icon: Icons.edit_outlined,
                        confirmButtonLabel: l10n.save,
                      );
                      if (!context.mounted || next == null || next.isEmpty) {
                        return;
                      }
                      onTeamRenamed(next);
                    },
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.scheme,
    required this.icon,
    required this.label,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onPrimary.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
