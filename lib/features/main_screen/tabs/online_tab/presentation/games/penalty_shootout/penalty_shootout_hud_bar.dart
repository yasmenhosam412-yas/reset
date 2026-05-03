import 'package:flutter/material.dart';

class PenaltyShootoutHudBar extends StatelessWidget {
  const PenaltyShootoutHudBar({
    super.key,
    required this.theme,
    required this.scheme,
    required this.myGoals,
    required this.oppGoals,
    required this.oppName,
    required this.round,
    required this.totalRounds,
    required this.secondsLeft,
    required this.iAmStriker,
    this.onlinePickInProgress = false,
    this.timerPausedForOnlineWait = false,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final int myGoals;
  final int oppGoals;
  final String oppName;
  final int round;
  final int totalRounds;
  final int secondsLeft;
  final bool iAmStriker;
  final bool onlinePickInProgress;
  final bool timerPausedForOnlineWait;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniScore('You', myGoals, iAmStriker),
              ),
              Text(
                '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w200,
                ),
              ),
              Expanded(
                child: _miniScore(oppName, oppGoals, !iAmStriker),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round $round / $totalRounds',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Icon(
                    timerPausedForOnlineWait
                        ? Icons.hourglass_top_rounded
                        : Icons.timer_rounded,
                    size: 20,
                    color: timerPausedForOnlineWait
                        ? scheme.onSurfaceVariant
                        : (secondsLeft <= 3 ? scheme.error : scheme.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timerPausedForOnlineWait ? '—' : '${secondsLeft}s',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: timerPausedForOnlineWait
                          ? scheme.onSurfaceVariant
                          : (secondsLeft <= 3 ? scheme.error : null),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onlinePickInProgress) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Round picks in progress…',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniScore(String label, int v, bool hot) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: hot
            ? scheme.primary.withValues(alpha: 0.18)
            : scheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hot
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$v',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
