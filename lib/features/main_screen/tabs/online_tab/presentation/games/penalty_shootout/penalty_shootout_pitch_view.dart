import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_rules.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';

class PenaltyShootoutPitchView extends StatelessWidget {
  const PenaltyShootoutPitchView({
    super.key,
    required this.theme,
    required this.scheme,
    required this.phase,
    required this.kickCurve,
    required this.strikerPick,
    required this.keeperPick,
    required this.iAmStriker,
    required this.scored,
    required this.dragNorm,
    required this.dragging,
    required this.bannerScale,
    required this.resultLine,
    required this.strikerPower,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final PenaltyShootoutPhase phase;
  final Animation<double> kickCurve;
  final PenaltyShootoutDir? strikerPick;
  final PenaltyShootoutDir? keeperPick;
  final bool iAmStriker;
  final bool scored;
  final double dragNorm;
  final bool dragging;
  final Animation<double> bannerScale;
  final String? resultLine;
  final double strikerPower;

  double _goalXForDir(PenaltyShootoutDir d, double w) {
    return switch (d) {
      PenaltyShootoutDir.left => w * 0.22,
      PenaltyShootoutDir.center => w * 0.5,
      PenaltyShootoutDir.right => w * 0.78,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final grassTop = h * 0.08;

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2E7D32).withValues(alpha: 0.85),
                          const Color(0xFF1B5E20).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.12,
                  right: w * 0.12,
                  bottom: h * 0.02,
                  height: h * 0.22,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.06,
                  right: w * 0.06,
                  top: grassTop,
                  height: h * 0.52,
                  child: _GoalFrame(
                    scheme: scheme,
                    dragNorm: phase == PenaltyShootoutPhase.pick ? dragNorm : null,
                    dragging: dragging,
                  ),
                ),
                if (phase == PenaltyShootoutPhase.pick && iAmStriker)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AimLinePainter(
                        norm: dragNorm,
                        active: dragging,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                if (strikerPick != null &&
                    keeperPick != null &&
                    (phase == PenaltyShootoutPhase.animating ||
                        phase == PenaltyShootoutPhase.reveal))
                  AnimatedBuilder(
                    animation: kickCurve,
                    builder: (context, child) {
                      final t = kickCurve.value;
                      final delayedT = ((t - 0.08) / 0.92).clamp(0.0, 1.0);
                      final diveX = _goalXForDir(keeperPick!, w);
                      final startX = w * 0.5;
                      final kx = lerpDouble(
                            startX,
                            diveX,
                            Curves.easeOut.transform(delayedT),
                          )!;
                      final ky = grassTop + h * 0.38;
                      return Positioned(
                        left: kx - 28,
                        top: ky,
                        child: _KeeperSprite(
                          scheme: scheme,
                          diving: t > 0.1,
                        ),
                      );
                    },
                  ),
                if (strikerPick != null &&
                    keeperPick != null &&
                    (phase == PenaltyShootoutPhase.animating ||
                        phase == PenaltyShootoutPhase.reveal))
                  AnimatedBuilder(
                    animation: kickCurve,
                    builder: (context, child) {
                      final tAnim = kickCurve.value;
                      final targetX = _goalXForDir(strikerPick!, w);
                      final targetY = grassTop + h * 0.2;
                      final startX = w * 0.5;
                      final startY = h * 0.88;
                      final drive = strikerPower.clamp(0.0, 1.0);

                      final endY = scored
                          ? targetY
                          : lerpDouble(
                              targetY,
                              grassTop + h * 0.36,
                              0.55 - drive * 0.12,
                            )!;
                      final endX = scored
                          ? targetX
                          : lerpDouble(startX, targetX, 0.62 + drive * 0.08)!;

                      final bx = lerpDouble(startX, endX, tAnim)!;
                      final by = lerpDouble(startY, endY, tAnim)!;

                      return Positioned(
                        left: bx - 14,
                        top: by - 14,
                        child: _Ball(scheme: scheme, blur: tAnim > 0.85),
                      );
                    },
                  ),
                if (phase == PenaltyShootoutPhase.pick)
                  Positioned(
                    left: w * 0.5 - 14,
                    top: h * 0.88 - 14,
                    child: _Ball(scheme: scheme, idle: true),
                  ),
                if (phase == PenaltyShootoutPhase.reveal && resultLine != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: h * 0.34,
                    child: ScaleTransition(
                      scale: bannerScale,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(16),
                        color: scored ? scheme.primary : scheme.secondary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: Text(
                            resultLine!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scored
                                  ? scheme.onPrimary
                                  : scheme.onSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GoalFrame extends StatelessWidget {
  const _GoalFrame({
    required this.scheme,
    required this.dragNorm,
    required this.dragging,
  });

  final ColorScheme scheme;
  final double? dragNorm;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _NetPainter(scheme: scheme)),
            if (dragNorm != null)
              Row(
                children: [
                  Expanded(
                    child: _ZoneHint(
                      active: dragNorm! < -PenaltyShootoutRules.aimSideThreshold,
                      dragging: dragging,
                    ),
                  ),
                  Expanded(
                    child: _ZoneHint(
                      active: dragNorm! >= -PenaltyShootoutRules.aimSideThreshold &&
                          dragNorm! <= PenaltyShootoutRules.aimSideThreshold,
                      dragging: dragging,
                    ),
                  ),
                  Expanded(
                    child: _ZoneHint(
                      active: dragNorm! > PenaltyShootoutRules.aimSideThreshold,
                      dragging: dragging,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoneHint extends StatelessWidget {
  const _ZoneHint({required this.active, required this.dragging});

  final bool active;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active && dragging
            ? Colors.amber.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _NetPainter extends CustomPainter {
  _NetPainter({required this.scheme});

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const step = 14.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, pi, pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AimLinePainter extends CustomPainter {
  _AimLinePainter({
    required this.norm,
    required this.active,
    required this.color,
  });

  final double norm;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active && norm.abs() < 0.04) return;
    final x = size.width * 0.5 + norm * size.width * 0.38;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.92),
      Offset(x, size.height * 0.28),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AimLinePainter oldDelegate) =>
      oldDelegate.norm != norm || oldDelegate.active != active;
}

class _Ball extends StatelessWidget {
  const _Ball({required this.scheme, this.idle = false, this.blur = false});

  final ColorScheme scheme;
  final bool idle;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: idle ? 1 : (blur ? 0.92 : 1.04),
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white,
              scheme.surfaceContainerHighest,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: idle ? 4 : 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(
          Icons.sports_soccer_rounded,
          size: 18,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _KeeperSprite extends StatelessWidget {
  const _KeeperSprite({required this.scheme, required this.diving});

  final ColorScheme scheme;
  final bool diving;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      offset: diving ? const Offset(0, -0.04) : Offset.zero,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          size: 34,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
