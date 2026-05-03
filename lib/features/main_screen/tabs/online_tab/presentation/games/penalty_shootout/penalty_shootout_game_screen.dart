import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_controls.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_hud_bar.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_online_config.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_pitch_view.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_rules.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_result_feed_share.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';
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

  double _powerNorm = 0.62;
  double _strikerPower = 0.62;

  RealtimeChannel? _penaltyChannel;
  Timer? _onlinePickPoll;
  Timer? _sessionPullDebounce;
  bool _sessionPullInFlight = false;
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

  void _mutate(VoidCallback fn) {
    if (mounted) setState(fn);
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
      _powerNorm = 0.62;
      _strikerPower = 0.62;
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
      duration: const Duration(milliseconds: 920),
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
    _onlinePickPoll?.cancel();
    _sessionPullDebounce?.cancel();
    final ch = _penaltyChannel;
    _penaltyChannel = null;
    if (ch != null) {
      unawaited(Supabase.instance.client.removeChannel(ch));
    }
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
          ? 'You win!'
          : _oppGoals > _myGoals
              ? '${widget.opponentName} wins'
              : 'Draw';
      return Card(
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
                s.primaryContainer.withValues(alpha: 0.55),
                s.tertiaryContainer.withValues(alpha: 0.35),
              ],
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.emoji_events_rounded, size: 56, color: s.primary),
              const SizedBox(height: 16),
              Text(
                'Shootout over',
                style: t.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You $_myGoals  —  ${widget.opponentName} $_oppGoals',
                style: t.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                winner,
                style: t.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: s.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.tonal(
                onPressed: (widget.onPlayAgain == null && widget.online != null)
                    ? null
                    : _onPlayAgainPressed,
                child: const Text('Play again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(
                  showShareGameResultToFeedDialog(
                    context,
                    title: 'Share to home feed',
                    initialBody:
                        'Penalty shootout vs ${widget.opponentName}\n'
                        'Final: $_myGoals — $_oppGoals\n'
                        '$winner',
                  ),
                ),
                icon: const Icon(Icons.feed_rounded),
                label: const Text('Share result'),
              ),
            ],
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
                  strikerPower: _strikerPower,
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
                          ? 'Saving your pick to the server…'
                          : 'Pick saved — waiting for ${widget.opponentName}…',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!(widget.online != null &&
                      (_onlinePickSubmitting || _onlineWaitingForOpponent))) ...[
                    if (_play.iAmStriker) ...[
                      PenaltyShootoutPowerSlider(
                        theme: t,
                        scheme: s,
                        power: _powerNorm,
                        onChanged: (v) => setState(() => _powerNorm = v),
                      ),
                      const SizedBox(height: 8),
                    ],
                    PenaltyShootoutDragAimStrip(
                      theme: t,
                      scheme: s,
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
                    'Shot ${PenaltyShootoutRules.dirLabel(_strikerPick!)} · Dive ${PenaltyShootoutRules.dirLabel(_keeperPick!)}',
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
