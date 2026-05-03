import 'package:flutter/material.dart';

class TeamEmptySquadBody extends StatelessWidget {
  const TeamEmptySquadBody({
    super.key,
    required this.onCreateTeam,
    this.communityBelow,
    this.challengesFooter,
  });

  final VoidCallback onCreateTeam;

  /// Optional global feed strip (all users) under the create-team card.
  final Widget? communityBelow;

  /// Daily challenges (e.g. under community on the empty-squad scroll).
  final Widget? challengesFooter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        Positioned(
          right: -60,
          top: 40,
          child: Icon(
            Icons.hexagon_outlined,
            size: 200,
            color: scheme.primary.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          left: -40,
          bottom: 80,
          child: Icon(
            Icons.shield_outlined,
            size: 160,
            color: scheme.tertiary.withValues(alpha: 0.08),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Team',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Build a six-player squad, pick a shape, and dial in stats. '
                          'Once you have a team, challenge friends from this tab or Online.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primaryContainer,
                                        scheme.tertiaryContainer,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.groups_rounded,
                                    size: 44,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No squad yet',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Six players only. Formations rearrange your board — tap anyone later to tweak ATK, DEF, SPD, STM.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: onCreateTeam,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Create team'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (communityBelow != null) ...[
                          const SizedBox(height: 20),
                          communityBelow!,
                        ],
                        if (challengesFooter != null) ...[
                          const SizedBox(height: 16),
                          challengesFooter!,
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
