import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Win / loss / draw for match-end visuals (confetti, ambience).
enum GameMatchOutcome {
  win,
  loss,
  draw,
}

GameMatchOutcome gameMatchOutcomeFromScores({
  required int myScore,
  required int oppScore,
}) {
  if (myScore > oppScore) return GameMatchOutcome.win;
  if (myScore < oppScore) return GameMatchOutcome.loss;
  return GameMatchOutcome.draw;
}

/// Confetti (win / draw) + soft gradient pulse on loss. [child] stays interactive.
class GameMatchOutcomeLayer extends StatefulWidget {
  const GameMatchOutcomeLayer({
    super.key,
    required this.outcome,
    required this.scheme,
    required this.child,
  });

  final GameMatchOutcome? outcome;
  final ColorScheme scheme;
  final Widget child;

  @override
  State<GameMatchOutcomeLayer> createState() => _GameMatchOutcomeLayerState();
}

class _GameMatchOutcomeLayerState extends State<GameMatchOutcomeLayer> {
  ConfettiController? _celebration;
  ConfettiController? _drawBurst;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant GameMatchOutcomeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outcome != widget.outcome) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    _celebration?.dispose();
    _drawBurst?.dispose();
    _celebration = null;
    _drawBurst = null;

    final o = widget.outcome;
    if (o == GameMatchOutcome.win) {
      _celebration = ConfettiController(duration: const Duration(seconds: 4));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _celebration?.play();
      });
    } else if (o == GameMatchOutcome.draw) {
      _drawBurst = ConfettiController(duration: const Duration(seconds: 2));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _drawBurst?.play();
      });
    }
  }

  @override
  void dispose() {
    _celebration?.dispose();
    _drawBurst?.dispose();
    super.dispose();
  }

  List<Color> get _winColors => [
        widget.scheme.primary,
        widget.scheme.secondary,
        widget.scheme.tertiary,
        widget.scheme.primaryContainer,
        widget.scheme.secondaryContainer,
      ];

  List<Color> get _drawColors => [
        widget.scheme.tertiary.withValues(alpha: 0.9),
        widget.scheme.outline.withValues(alpha: 0.65),
        widget.scheme.surfaceContainerHigh,
      ];

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    if (o == null) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (o == GameMatchOutcome.loss)
          const Positioned.fill(
            child: IgnorePointer(child: _LossAmbienceLayer()),
          ),
        if (_celebration != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _celebration!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 18,
                maxBlastForce: 32,
                minBlastForce: 16,
                gravity: 0.18,
                colors: _winColors,
                minimumSize: const Size(6, 6),
                maximumSize: const Size(14, 10),
              ),
            ),
          ),
        if (_drawBurst != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _drawBurst!,
                blastDirectionality: BlastDirectionality.directional,
                blastDirection: pi / 2,
                emissionFrequency: 0.06,
                numberOfParticles: 10,
                maxBlastForce: 22,
                minBlastForce: 10,
                gravity: 0.14,
                colors: _drawColors,
                minimumSize: const Size(5, 5),
                maximumSize: const Size(11, 8),
              ),
            ),
          ),
      ],
    );
  }
}

class _LossAmbienceLayer extends StatefulWidget {
  const _LossAmbienceLayer();

  @override
  State<_LossAmbienceLayer> createState() => _LossAmbienceLayerState();
}

class _LossAmbienceLayerState extends State<_LossAmbienceLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 0.95 + t * 0.2,
              colors: [
                scheme.tertiary.withValues(alpha: 0.07 + t * 0.08),
                scheme.primary.withValues(alpha: 0.04 + t * 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}
