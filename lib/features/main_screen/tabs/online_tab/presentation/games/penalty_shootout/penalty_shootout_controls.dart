import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_rules.dart';

class PenaltyShootoutPowerSlider extends StatelessWidget {
  const PenaltyShootoutPowerSlider({
    super.key,
    required this.theme,
    required this.scheme,
    required this.power,
    required this.onChanged,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final double power;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              'Shot power',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${(power * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          value: power.clamp(0.0, 1.0),
          onChanged: onChanged,
        ),
        Text(
          'Higher power: faster shot and can beat the keeper on the same side '
          'above ${PenaltyShootoutRules.powerBlastPercentRounded}%.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class PenaltyShootoutDragAimStrip extends StatelessWidget {
  const PenaltyShootoutDragAimStrip({
    super.key,
    required this.theme,
    required this.scheme,
    required this.dragNorm,
    required this.dragging,
    required this.isStriker,
    required this.onUpdate,
    required this.onEnd,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final double dragNorm;
  final bool dragging;
  final bool isStriker;
  final void Function(DragUpdateDetails d, double width) onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final puckX = w * 0.5 + dragNorm * (w * 0.38) - 22;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isStriker
                  ? 'Drag sideways, release to shoot'
                  : 'Drag sideways, release to dive',
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
                        Expanded(
                          child: Center(
                            child: Text(
                              'LEFT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.outline,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'CENTER',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.outline,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'RIGHT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.outline,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
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
        );
      },
    );
  }
}
