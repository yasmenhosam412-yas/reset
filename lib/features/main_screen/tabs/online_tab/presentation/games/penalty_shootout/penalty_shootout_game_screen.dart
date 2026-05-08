import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_controls.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_hud_bar.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_online_config.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_pitch_view.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_rules.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_match_outcome_fx.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_result_feed_share.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';
import 'package:new_project/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'penalty_shootout_game_screen_logic.dart';

class PenaltyShootoutGame extends StatefulWidget {
  const PenaltyShootoutGame({
    super.key,
    required this.scheme,
    required this.theme,
    required this.opponentName,
    this.online,
    this.onPlayAgain,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final PenaltyShootoutOnlineConfig? online;

  /// Remount this widget (e.g. bump a [ValueKey]) for online replay, or omit
  /// and a local-only match will reset in place.
  final VoidCallback? onPlayAgain;

  @override
  State<PenaltyShootoutGame> createState() => _PenaltyShootoutGameState();
}

class _PenaltyShootoutGameState extends State<PenaltyShootoutGame>
    with TickerProviderStateMixin {
  late final _PenaltyShootoutLogic _play;

  final _random = Random();

  late final AnimationController _kickCtrl;
  late final Animation<double> _kickCurve;
  late final AnimationController _bannerCtrl;
  late final Animation<double> _bannerScale;

  int _roundIndex = 0;
  int _myGoals = 0;
  int _oppGoals = 0;
  int _secondsLeft = PenaltyShootoutRules.secondsPerRound;
  Timer? _countdown;

  PenaltyShootoutPhase _phase = PenaltyShootoutPhase.pick;
  PenaltyShootoutDir? _strikerPick;
  PenaltyShootoutDir? _keeperPick;
  bool _lastKickScored = false;
  String? _lastResultLine;

  double _dragNorm = 0;
  bool _dragging = false;

  /// Offline only; online matches always use [PenaltyAimLanes.wide5] on the server.
  PenaltyAimLanes _aimLanes = PenaltyAimLanes.wide5;

  Timer? _onlineBgSyncTimer;
  Timer? _onlinePickPoll;
  bool _sessionPullInFlight = false;
  bool _sessionPullPending = false;
  String? _myUserId;
  bool _onlineBootstrap = true;
  int _roundBeingResolved = 0;
  String _effFromId = '';
  String _effToId = '';
  String? _lastStrikerUserId;
  bool _kickOutcomeHandled = false;
  bool _onlinePickSubmitting = false;
  bool _onlineWaitingForOpponent = false;
  bool _onlineMatchCleanupDone = false;

  String _dirLabelL10n(PenaltyShootoutDir d, AppLocalizations l10n) =>
      switch (d) {
        PenaltyShootoutDir.farLeft => l10n.penaltyDirFarLeft,
        PenaltyShootoutDir.left => l10n.penaltyDirLeft,
        PenaltyShootoutDir.center => l10n.penaltyDirCenter,
        PenaltyShootoutDir.right => l10n.penaltyDirRight,
        PenaltyShootoutDir.farRight => l10n.penaltyDirFarRight,
      };

  void _mutate(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Online sync without Realtime (avoids client parse failures on postgres payloads).
  void _startOnlineBackgroundSyncTimer() {
    _onlineBgSyncTimer?.cancel();
    if (widget.online == null) return;
    _onlineBgSyncTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || widget.online == null) return;
      unawaited(_play.backgroundOnlineSyncTick());
    });
  }

  void _onPlayAgainPressed() {
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
      return;
    }
    if (widget.online != null) return;
    _restartLocalMatch();
  }

  void _restartLocalMatch() {
    _countdown?.cancel();
    _kickCtrl.reset();
    _bannerCtrl.reset();
    _mutate(() {
      _roundIndex = 0;
      _myGoals = 0;
      _oppGoals = 0;
      _secondsLeft = PenaltyShootoutRules.secondsPerRound;
      _phase = PenaltyShootoutPhase.pick;
      _strikerPick = null;
      _keeperPick = null;
      _lastKickScored = false;
      _lastResultLine = null;
      _dragNorm = 0;
      _dragging = false;
      _kickOutcomeHandled = false;
      _onlinePickSubmitting = false;
      _onlineWaitingForOpponent = false;
      _roundBeingResolved = 0;
      _lastStrikerUserId = null;
      _onlineMatchCleanupDone = false;
    });
    _play.beginRound();
  }

  @override
  void initState() {
    super.initState();
    _play = _PenaltyShootoutLogic(this);

    _kickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: PenaltyShootoutRules.kickAnimationDurationMs,
      ),
    );
    _kickCurve = CurvedAnimation(
      parent: _kickCtrl,
      curve: Curves.easeInCubic,
    );
    _kickCtrl.addStatusListener(_play.onKickStatus);

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bannerScale = CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.elasticOut,
    );

    if (widget.online != null) {
      unawaited(_play.bootstrapOnlinePlay());
    } else {
      _onlineBootstrap = false;
      _play.beginRound();
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _onlineBgSyncTimer?.cancel();
    _onlinePickPoll?.cancel();
    if (widget.online != null &&
        _phase == PenaltyShootoutPhase.finished &&
        !_onlineMatchCleanupDone) {
      final cfg = widget.online!;
      unawaited(
        cfg.repository.finishPenaltyMatchCleanup(challengeId: cfg.challengeId),
      );
    }
    _kickCtrl.removeStatusListener(_play.onKickStatus);
    _kickCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = widget.theme;
    final s = widget.scheme;

    if (widget.online != null && _onlineBootstrap) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_phase == PenaltyShootoutPhase.finished) {
      final winner = _myGoals > _oppGoals
          ? l10n.youWon
          : _oppGoals > _myGoals
              ? l10n.opponentWins(widget.opponentName)
              : l10n.draw;
      final outcome = gameMatchOutcomeFromScores(
        myScore: _myGoals,
        oppScore: _oppGoals,
      );
      final resultIcon = switch (outcome) {
        GameMatchOutcome.win => Icons.emoji_events_rounded,
        GameMatchOutcome.loss => Icons.auto_fix_high_rounded,
        GameMatchOutcome.draw => Icons.handshake_rounded,
      };
      final resultAccent = switch (outcome) {
        GameMatchOutcome.win => s.primary,
        GameMatchOutcome.loss => s.tertiary,
        GameMatchOutcome.draw => s.secondary,
      };
      final subline = switch (outcome) {
        GameMatchOutcome.win => l10n.shootoutWinSubline,
        GameMatchOutcome.loss => l10n.shootoutLossSubline,
        GameMatchOutcome.draw => l10n.shootoutDrawSubline,
      };
      return GameMatchOutcomeLayer(
        outcome: outcome,
        scheme: s,
        child: Card(
          elevation: 2,
          shadowColor: s.shadow.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  resultAccent.withValues(alpha: 0.22),
                  s.surfaceContainerLow.withValues(alpha: 0.9),
                  s.tertiaryContainer.withValues(alpha: 0.28),
                ],
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 640),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) {
                    return Transform.scale(
                      scale: 0.72 + 0.28 * v,
                      child: Transform.rotate(
                        angle: (1 - v) * 0.12,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(resultIcon, size: 64, color: resultAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.shootoutOver,
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.youVsOpponentScore(
                    _myGoals,
                    widget.opponentName,
                    _oppGoals,
                  ),
                  style: t.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  winner,
                  style: t.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: resultAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  subline,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: s.onSurfaceVariant,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.tonal(
                  onPressed: (widget.onPlayAgain == null && widget.online != null)
                      ? null
                      : _onPlayAgainPressed,
                  child: Text(l10n.playAgain),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => unawaited(
                    showShareGameResultToFeedDialog(
                      context,
                      title: l10n.shareToHomeFeed,
                      initialBody:
                          l10n.penaltyShootoutShareBody(
                            widget.opponentName,
                            _myGoals,
                            _oppGoals,
                            winner,
                          ),
                    ),
                  ),
                  icon: const Icon(Icons.feed_rounded),
                  label: Text(l10n.shareResult),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: s.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.online == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.goalLanes,
                      style: t.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SegmentedButton<PenaltyAimLanes>(
                    segments: [
                      ButtonSegment<PenaltyAimLanes>(
                        value: PenaltyAimLanes.classic3,
                        label: Text('3'),
                        tooltip: l10n.goalLanesClassicTooltip,
                      ),
                      ButtonSegment<PenaltyAimLanes>(
                        value: PenaltyAimLanes.wide5,
                        label: Text('5'),
                        tooltip: l10n.goalLanesWideTooltip,
                      ),
                    ],
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    selected: {_aimLanes},
                    onSelectionChanged: (Set<PenaltyAimLanes> next) {
                      if (!mounted || _phase != PenaltyShootoutPhase.pick) {
                        return;
                      }
                      if (next.isEmpty) return;
                      setState(() => _aimLanes = next.first);
                    },
                  ),
                ],
              ),
            ),
          ],
          PenaltyShootoutHudBar(
            theme: t,
            scheme: s,
            myGoals: _myGoals,
            oppGoals: _oppGoals,
            oppName: widget.opponentName,
            round: _roundIndex + 1,
            totalRounds: PenaltyShootoutRules.totalRounds,
            secondsLeft: _secondsLeft,
            iAmStriker: _play.iAmStriker,
            onlinePickInProgress: widget.online != null &&
                _phase == PenaltyShootoutPhase.pick &&
                (_onlinePickSubmitting || _onlineWaitingForOpponent),
            timerPausedForOnlineWait: widget.online != null &&
                _phase == PenaltyShootoutPhase.pick &&
                _onlineWaitingForOpponent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                PenaltyShootoutPitchView(
                  theme: t,
                  scheme: s,
                  phase: _phase,
                  kickCurve: _kickCurve,
                  strikerPick: _strikerPick,
                  keeperPick: _keeperPick,
                  iAmStriker: _play.iAmStriker,
                  scored: _lastKickScored,
                  dragNorm: _dragNorm,
                  dragging: _dragging,
                  bannerScale: _bannerScale,
                  resultLine: _lastResultLine,
                  aimLanes: _play.effectiveAimLanes,
                ),
                if (_phase == PenaltyShootoutPhase.reveal &&
                    _lastResultLine != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    elevation: 1,
                    borderRadius: BorderRadius.circular(14),
                    color: _lastKickScored
                        ? s.primaryContainer
                        : s.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Text(
                        _lastResultLine!,
                        textAlign: TextAlign.center,
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _lastKickScored
                              ? s.onPrimaryContainer
                              : s.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_phase == PenaltyShootoutPhase.pick) ...[
                  const SizedBox(height: 10),
                  if (widget.online != null &&
                      (_onlinePickSubmitting || _onlineWaitingForOpponent)) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor:
                            s.surfaceContainerHighest.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _onlinePickSubmitting
                          ? l10n.savingPickToServer
                          : l10n.pickSavedWaitingFor(widget.opponentName),
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!(widget.online != null &&
                      (_onlinePickSubmitting || _onlineWaitingForOpponent))) ...[
                    PenaltyShootoutDragAimStrip(
                      theme: t,
                      scheme: s,
                      aimLanes: _play.effectiveAimLanes,
                      dragNorm: _dragNorm,
                      dragging: _dragging,
                      isStriker: _play.iAmStriker,
                      onUpdate: _play.onDragUpdate,
                      onEnd: _play.onDragEnd,
                    ),
                  ],
                ],
                if (_phase == PenaltyShootoutPhase.reveal &&
                    _strikerPick != null &&
                    _keeperPick != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.shotDiveSummary(
                      _dirLabelL10n(_strikerPick!, l10n),
                      _dirLabelL10n(_keeperPick!, l10n),
                    ),
                    style: t.textTheme.labelSmall?.copyWith(
                      color: s.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
