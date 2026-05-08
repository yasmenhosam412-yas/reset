import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';

class TeamChallengeUiDef {
  const TeamChallengeUiDef({
    required this.keyId,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String keyId;
  final String title;
  final String subtitle;
  final int points;
}

/// Daily challenges for **all** signed-in users; rewards skill points on the server.
class TeamDailyChallengesCard extends StatelessWidget {
  const TeamDailyChallengesCard({
    super.key,
    required this.claimedKeysToday,
    required this.onClaim,
    this.claimBusyKey,
  });

  final Set<String> claimedKeysToday;
  final void Function(String key) onClaim;
  final String? claimBusyKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final defs = [
      TeamChallengeUiDef(
        keyId: 'pitch_report',
        title: l10n.teamChallengePitchReportTitle,
        subtitle: l10n.teamChallengePitchReportSubtitle,
        points: 12,
      ),
      TeamChallengeUiDef(
        keyId: 'crowd_energy',
        title: l10n.teamChallengeCrowdEnergyTitle,
        subtitle: l10n.teamChallengeCrowdEnergySubtitle,
        points: 20,
      ),
      TeamChallengeUiDef(
        keyId: 'session_move',
        title: l10n.teamChallengeMatchRhythmTitle,
        subtitle: l10n.teamChallengeMatchRhythmSubtitle,
        points: 22,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.teamDailyChallengesEveryone,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.teamDailyChallengesHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              ...defs.map((c) {
                final claimed = claimedKeysToday.contains(c.keyId);
                final busy = claimBusyKey == c.keyId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: scheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${c.points}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (claimed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    l10n.claimed,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                FilledButton.tonal(
                                  onPressed: busy
                                      ? null
                                      : () => onClaim(c.keyId),
                                  child: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l10n.claim),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
