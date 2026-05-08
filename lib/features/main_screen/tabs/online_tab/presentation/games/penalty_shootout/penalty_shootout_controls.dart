import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';

class PenaltyShootoutDragAimStrip extends StatelessWidget {
  const PenaltyShootoutDragAimStrip({
    super.key,
    required this.theme,
    required this.scheme,
    required this.aimLanes,
    required this.dragNorm,
    required this.dragging,
    required this.isStriker,
    required this.onUpdate,
    required this.onEnd,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final PenaltyAimLanes aimLanes;
  final double dragNorm;
  final bool dragging;
  final bool isStriker;
  final void Function(DragUpdateDetails d, double width) onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final puckX = w * 0.5 + dragNorm * (w * 0.38) - 22;

        final labels = aimLanes == PenaltyAimLanes.wide5
            ? [
                l10n.penaltyLaneFarLeftShort,
                l10n.penaltyLaneLeftShort,
                l10n.penaltyLaneCenterShort,
                l10n.penaltyLaneRightShort,
                l10n.penaltyLaneFarRightShort,
              ]
            : [
                l10n.penaltyLaneLeft,
                l10n.penaltyLaneCenter,
                l10n.penaltyLaneRight,
              ];

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isStriker
                    ? l10n.penaltyDragReleaseShoot
                    : l10n.penaltyDragReleaseDive,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => onUpdate(d, w),
                onHorizontalDragEnd: (_) => onEnd(),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                        scheme.surface.withValues(alpha: 0.5),
                      ],
                    ),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          for (final lab in labels)
                            Expanded(
                              child: Center(
                                child: Text(
                                  lab,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.outline,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: lab.length <= 2 ? 0.6 : 1.1,
                                    fontSize: lab.length <= 2 ? 11 : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Positioned(
                        left: puckX.clamp(6.0, w - 50),
                        top: 10,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primaryContainer,
                            border: Border.all(
                              color: dragging
                                  ? scheme.primary
                                  : scheme.outline.withValues(alpha: 0.3),
                              width: dragging ? 3 : 2,
                            ),
                            boxShadow: [
                              if (dragging)
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                ),
                            ],
                          ),
                          child: Icon(
                            isStriker
                                ? Icons.sports_soccer_rounded
                                : Icons.pan_tool_alt_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
