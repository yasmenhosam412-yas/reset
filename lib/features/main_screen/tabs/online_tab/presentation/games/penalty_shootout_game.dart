import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout_online_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _PenaltyDir { left, center, right }

enum _Phase { pick, animating, reveal, finished }

class PenaltyShootoutGame extends StatefulWidget {
  const PenaltyShootoutGame({
    super.key,
    required this.scheme,
    required this.theme,
    required this.opponentName,
    this.online,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final PenaltyShootoutOnlineConfig? online;

  @override
  State<PenaltyShootoutGame> createState() => _PenaltyShootoutGameState();
}

class _PenaltyShootoutGameState extends State<PenaltyShootoutGame>
    with TickerProviderStateMixin {
  static const int _secondsPerRound = 14;
  static const int _totalRounds = 10;
  static const double _powerBlastThreshold = 0.72;

  final _random = Random();

  late final AnimationController _kickCtrl;
  late final Animation<double> _kickCurve;
  late final AnimationController _bannerCtrl;
  late final Animation<double> _bannerScale;

  int _roundIndex = 0;
  int _myGoals = 0;
  int _oppGoals = 0;
  int _secondsLeft = _secondsPerRound;
  Timer? _countdown;

  _Phase _phase = _Phase.pick;
  _PenaltyDir? _strikerPick;
  _PenaltyDir? _keeperPick;
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

  bool get _iAmStriker =>
      widget.online == null ? _roundIndex % 2 == 0 : _onlineStrikerForRound();

  static bool _uidEq(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.toLowerCase().trim() == b.toLowerCase().trim();
  }

  bool _onlineStrikerForRound() {
    final sid = _strikerUserIdForIndex(_roundIndex);
    return _uidEq(_myUserId, sid);
  }

  /// Even rounds: challenger shoots first; odd: invitee (matches DB ids).
  String _strikerUserIdForIndex(int round) {
    final cfg = widget.online!;
    final from = _effFromId.trim().isNotEmpty ? _effFromId : cfg.fromUserId;
    final to = _effToId.trim().isNotEmpty ? _effToId : cfg.toUserId;
    return round % 2 == 0 ? from : to;
  }

  static int _dirToInt(_PenaltyDir d) => switch (d) {
        _PenaltyDir.left => -1,
        _PenaltyDir.center => 0,
        _PenaltyDir.right => 1,
      };

  static _PenaltyDir _intToDir(int i) {
    if (i < 0) return _PenaltyDir.left;
    if (i > 0) return _PenaltyDir.right;
    return _PenaltyDir.center;
  }

  bool _computeScored(_PenaltyDir shot, _PenaltyDir dive, double power) {
    if (shot != dive) return true;
    return power >= _powerBlastThreshold;
  }

  void _applyKickDurationForPower(double power) {
    final ms =
        (920 * (1.05 - 0.42 * power.clamp(0.0, 1.0))).round().clamp(420, 1040);
    _kickCtrl.duration = Duration(milliseconds: ms);
  }

  @override
  void initState() {
    super.initState();
    _kickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _kickCurve = CurvedAnimation(
      parent: _kickCtrl,
      curve: Curves.easeInCubic,
    );
    _kickCtrl.addStatusListener(_onKickStatus);

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bannerScale = CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.elasticOut,
    );

    if (widget.online != null) {
      unawaited(_bootstrapOnlinePlay());
    } else {
      _onlineBootstrap = false;
      _beginRound();
    }
  }

  Future<void> _finishOnlineMatchInDatabase() async {
    final cfg = widget.online;
    if (cfg == null || _onlineMatchCleanupDone) return;
    _onlineMatchCleanupDone = true;
    final r = await cfg.repository.finishPenaltyMatchCleanup(
      challengeId: cfg.challengeId,
    );
    if (!mounted) return;
    r.fold(
      (f) {
        _onlineMatchCleanupDone = false;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not close out match: ${f.message}')),
        );
      },
      (_) {},
    );
  }

  Future<void> _bootstrapOnlinePlay() async {
    final cfg = widget.online!;
    _myUserId = Supabase.instance.client.auth.currentUser?.id;
    _effFromId = cfg.fromUserId;
    _effToId = cfg.toUserId;

    final sidesRes =
        await cfg.repository.fetchGameChallengeSides(challengeId: cfg.challengeId);
    sidesRes.fold((_) {}, (sides) {
      if (sides == null) return;
      final f = sides.fromUserId.trim();
      final t = sides.toUserId.trim();
      if (f.isNotEmpty) _effFromId = f;
      if (t.isNotEmpty) _effToId = t;
    });

    await cfg.repository.ensurePenaltyShootoutSession(challengeId: cfg.challengeId);
    if (!mounted) return;
    await _pullSessionAndApply();
    if (!mounted) return;
    _subscribePenaltyRealtime();
    setState(() => _onlineBootstrap = false);
    _beginRound();
  }

  Future<void> _pullSessionAndApply() async {
    final cfg = widget.online;
    if (cfg == null) return;
    if (_sessionPullInFlight) return;
    _sessionPullInFlight = true;
    try {
      final res =
          await cfg.repository.fetchPenaltyShootoutSession(challengeId: cfg.challengeId);
      PenaltyShootoutSessionModel? session;
      res.fold((_) => session = null, (s) => session = s);
      final s = session;
      if (!mounted || s == null) return;
      if (_sessionVisuallyEquals(s)) return;
      setState(() => _applySession(s));
    } finally {
      _sessionPullInFlight = false;
    }
  }

  void _applySession(PenaltyShootoutSessionModel s) {
    _roundIndex = s.roundIndex;
    final cfg = widget.online!;
    final uid = _myUserId;
    final from = _effFromId.trim().isNotEmpty ? _effFromId : cfg.fromUserId;
    if (_uidEq(uid, from)) {
      _myGoals = s.fromGoals;
      _oppGoals = s.toGoals;
    } else {
      _myGoals = s.toGoals;
      _oppGoals = s.fromGoals;
    }
  }

  bool _sessionVisuallyEquals(PenaltyShootoutSessionModel s) {
    if (s.roundIndex != _roundIndex) return false;
    final cfg = widget.online!;
    final uid = _myUserId;
    final from = _effFromId.trim().isNotEmpty ? _effFromId : cfg.fromUserId;
    final my = _uidEq(uid, from) ? s.fromGoals : s.toGoals;
    final opp = _uidEq(uid, from) ? s.toGoals : s.fromGoals;
    return my == _myGoals && opp == _oppGoals;
  }

  void _subscribePenaltyRealtime() {
    final cfg = widget.online!;
    final id = cfg.challengeId;
    _penaltyChannel?.unsubscribe();
    _penaltyChannel = Supabase.instance.client
        .channel('penalty_match_$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: HomeTable.penaltyRoundPicks,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: PenaltyPickCols.challengeId,
            value: id,
          ),
          callback: (_) => unawaited(_fetchAndResolveOnlinePicks()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: HomeTable.penaltyShootoutSessions,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: PenaltySessionCols.challengeId,
            value: id,
          ),
          callback: (_) => unawaited(_onSessionRemoteUpdate()),
        )
        .subscribe();
  }

  Future<void> _onSessionRemoteUpdate() async {
    if (widget.online == null || !mounted) return;
    if (_phase == _Phase.animating || _phase == _Phase.reveal) return;
    _sessionPullDebounce?.cancel();
    _sessionPullDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      unawaited(_pullSessionAndApply());
    });
  }

  void _onKickStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(_completeKickOutcome());
    }
  }

  Future<void> _completeKickOutcome() async {
    if (!mounted || _kickOutcomeHandled) return;
    if (_phase != _Phase.animating) return;
    _kickOutcomeHandled = true;
    await _onKickAnimationComplete();
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
    _kickCtrl.removeStatusListener(_onKickStatus);
    _kickCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  void _beginRound() {
    _kickCtrl.reset();
    _bannerCtrl.reset();
    _countdown?.cancel();
    _onlinePickPoll?.cancel();
    if (_roundIndex >= _totalRounds) {
      setState(() => _phase = _Phase.finished);
      unawaited(_finishOnlineMatchInDatabase());
      return;
    }

    setState(() {
      _phase = _Phase.pick;
      if (widget.online == null) {
        _strikerPick = _iAmStriker ? null : _randomDir();
        _keeperPick = null;
        if (!_iAmStriker) {
          _strikerPower = 0.38 + _random.nextDouble() * 0.55;
        }
      } else {
        _strikerPick = null;
        _keeperPick = null;
      }
      _lastResultLine = null;
      _lastKickScored = false;
      _secondsLeft = _secondsPerRound;
      _dragNorm = 0;
      _dragging = false;
      _powerNorm = 0.62;
      _onlinePickSubmitting = false;
      _onlineWaitingForOpponent = false;
    });

    _startPickPhaseCountdown();
  }

  void _startPickPhaseCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_phase != _Phase.pick) {
        _countdown?.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _countdown?.cancel();
          unawaited(_applyTimeout());
        }
      });
    });
  }

  _PenaltyDir _randomDir() =>
      _PenaltyDir.values[_random.nextInt(3)];

  _PenaltyDir _normToDir(double n) {
    if (n < -0.35) return _PenaltyDir.left;
    if (n > 0.35) return _PenaltyDir.right;
    return _PenaltyDir.center;
  }

  Future<void> _applyTimeout() async {
    if (_phase != _Phase.pick) return;
    _countdown?.cancel();
    final n = (_random.nextDouble() * 2) - 1;
    await _commitFromDragNorm(n);
  }

  void _onDragUpdate(DragUpdateDetails d, double trackWidth) {
    if (_phase != _Phase.pick) return;
    if (widget.online != null &&
        (_onlinePickSubmitting || _onlineWaitingForOpponent)) {
      return;
    }
    final delta = d.delta.dx / (trackWidth * 0.45);
    setState(() {
      _dragging = true;
      _dragNorm = (_dragNorm + delta).clamp(-1.0, 1.0);
    });
  }

  void _onDragEnd() {
    if (_phase != _Phase.pick) return;
    if (widget.online != null &&
        (_onlinePickSubmitting || _onlineWaitingForOpponent)) {
      return;
    }
    _countdown?.cancel();
    unawaited(_commitFromDragNorm(_dragNorm));
  }

  Future<void> _commitFromDragNorm(double n) async {
    if (_phase != _Phase.pick) return;
    final dir = _normToDir(n);

    if (widget.online != null) {
      await _commitOnlinePick(dir);
      return;
    }

    setState(() {
      _dragging = false;
      if (_iAmStriker) {
        _strikerPick = dir;
        _keeperPick = _randomDir();
        _strikerPower = _powerNorm.clamp(0.0, 1.0);
      } else {
        _keeperPick = dir;
        _strikerPick ??= _randomDir();
        _strikerPower = 0.38 + _random.nextDouble() * 0.55;
      }
    });

    final shot = _strikerPick!;
    final dive = _keeperPick!;
    _lastKickScored = _computeScored(shot, dive, _strikerPower);

    if (_iAmStriker) {
      if (_lastKickScored) _myGoals++;
    } else {
      if (_lastKickScored) _oppGoals++;
    }

    _applyKickDurationForPower(_strikerPower);
    setState(() => _phase = _Phase.animating);
    HapticFeedback.selectionClick();
    _kickOutcomeHandled = false;
    _kickCtrl.forward(from: 0);
    _scheduleKickOutcomeFallback();
  }

  Future<void> _commitOnlinePick(_PenaltyDir dir) async {
    final cfg = widget.online!;
    if (_myUserId == null || _myUserId!.isEmpty) return;

    setState(() {
      _dragging = false;
      _onlinePickSubmitting = true;
      _onlineWaitingForOpponent = false;
    });

    final strikerUid = _strikerUserIdForIndex(_roundIndex);
    final isShot = _uidEq(_myUserId, strikerUid);
    final kind = isShot ? PenaltyPickKind.shot : PenaltyPickKind.dive;
    final direction = _dirToInt(dir);
    final power = isShot ? _powerNorm.clamp(0.0, 1.0) : null;

    final up = await cfg.repository.upsertPenaltyRoundPick(
      challengeId: cfg.challengeId,
      roundIndex: _roundIndex,
      pickKind: kind,
      direction: direction,
      power: power,
    );
    if (!mounted) return;
    up.fold(
      (f) {
        if (!mounted) return;
        setState(() {
          _onlinePickSubmitting = false;
          _onlineWaitingForOpponent = false;
        });
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not submit pick: ${f.message}')),
        );
      },
      (_) {
        if (!mounted) return;
        _countdown?.cancel();
        setState(() {
          _onlinePickSubmitting = false;
          _onlineWaitingForOpponent = true;
        });
        unawaited(_fetchAndResolveOnlinePicks());
        _startOnlinePickPoll();
      },
    );
  }

  /// Realtime often does not notify the other device until RLS allows seeing
  /// both rows; poll until the round resolves or times out.
  void _startOnlinePickPoll() {
    if (widget.online == null || _phase != _Phase.pick) return;
    _onlinePickPoll?.cancel();
    var ticks = 0;
    _onlinePickPoll = Timer.periodic(const Duration(milliseconds: 400), (_) {
      ticks++;
      if (!mounted || _phase != _Phase.pick || widget.online == null) {
        _onlinePickPoll?.cancel();
        return;
      }
      if (ticks > 80) {
        _onlinePickPoll?.cancel();
        return;
      }
      unawaited(_fetchAndResolveOnlinePicks());
    });
  }

  Future<void> _fetchAndResolveOnlinePicks() async {
    final cfg = widget.online;
    if (cfg == null || !mounted) return;
    if (_phase != _Phase.pick) return;

    final roundAtStart = _roundIndex;

    final res = await cfg.repository.fetchPenaltyRoundPicks(
      challengeId: cfg.challengeId,
      roundIndex: roundAtStart,
    );
    if (!mounted || _roundIndex != roundAtStart) return;
    if (_phase != _Phase.pick) return;

    List<PenaltyRoundPickModel>? picks;
    res.fold((_) => picks = null, (list) => picks = list);
    final list = picks;
    if (!mounted || list == null || list.length < 2) return;

    PenaltyRoundPickModel? shotPick;
    PenaltyRoundPickModel? divePick;
    for (final p in list) {
      final k = p.pickKind.toLowerCase().trim();
      if (k == PenaltyPickKind.shot) shotPick = p;
      if (k == PenaltyPickKind.dive) divePick = p;
    }
    if (shotPick == null || divePick == null) return;
    if (_uidEq(shotPick.userId, divePick.userId)) return;

    if (!mounted || _roundIndex != roundAtStart || _phase != _Phase.pick) {
      return;
    }

    final shot = _intToDir(shotPick.direction);
    final dive = _intToDir(divePick.direction);
    final power = shotPick.power ?? 0.62;

    _onlinePickPoll?.cancel();
    _countdown?.cancel();

    _roundBeingResolved = _roundIndex;
    _lastStrikerUserId = shotPick.userId;
    _strikerPower = power;
    _lastKickScored = _computeScored(shot, dive, power);

    setState(() {
      _strikerPick = shot;
      _keeperPick = dive;
      _phase = _Phase.animating;
      _onlineWaitingForOpponent = false;
      _onlinePickSubmitting = false;
    });

    _applyKickDurationForPower(power);
    HapticFeedback.selectionClick();
    _kickOutcomeHandled = false;
    _kickCtrl.forward(from: 0);
    _scheduleKickOutcomeFallback();
  }

  void _scheduleKickOutcomeFallback() {
    final ms = _kickCtrl.duration?.inMilliseconds ?? 920;
    unawaited(
      Future<void>.delayed(Duration(milliseconds: ms + 120), () async {
        if (!mounted) return;
        await _completeKickOutcome();
      }),
    );
  }

  Future<void> _onKickAnimationComplete() async {
    if (!mounted) return;
    final strikerWasMe = widget.online == null
        ? _iAmStriker
        : _uidEq(_lastStrikerUserId, _myUserId);
    final who = strikerWasMe ? 'You' : widget.opponentName;
    final scored = _lastKickScored;

    if (widget.online != null) {
      final cfg = widget.online!;
      final sid = _lastStrikerUserId ?? _strikerUserIdForIndex(_roundBeingResolved);
      final from = _effFromId.trim().isNotEmpty ? _effFromId : cfg.fromUserId;
      final to = _effToId.trim().isNotEmpty ? _effToId : cfg.toUserId;
      try {
        await cfg.repository.advancePenaltyRound(
          challengeId: cfg.challengeId,
          expectedRoundIndex: _roundBeingResolved,
          fromGoalsDelta: scored && _uidEq(sid, from) ? 1 : 0,
          toGoalsDelta: scored && _uidEq(sid, to) ? 1 : 0,
        );
        if (!mounted) return;
        await _pullSessionAndApply();
      } catch (_) {
        if (mounted) await _pullSessionAndApply();
      }
    }

    if (!mounted) return;
    setState(() {
      _phase = _Phase.reveal;
      _lastResultLine = scored
          ? '$who — GOAL!'
          : '$who — saved!';
    });

    if (scored) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _bannerCtrl.forward(from: 0);

    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      var goNextRound = false;
      if (widget.online == null) {
        setState(() {
          _roundIndex++;
          if (_roundIndex >= _totalRounds) {
            _phase = _Phase.finished;
          } else {
            goNextRound = true;
          }
        });
        if (goNextRound) {
          _beginRound();
        }
      } else {
        var finishedNow = false;
        setState(() {
          if (_roundIndex >= _totalRounds) {
            _phase = _Phase.finished;
            finishedNow = true;
          } else {
            goNextRound = true;
          }
        });
        if (finishedNow) {
          unawaited(_finishOnlineMatchInDatabase());
        }
        if (goNextRound) {
          _beginRound();
        }
      }
    });
  }

  String _dirLabel(_PenaltyDir d) => switch (d) {
        _PenaltyDir.left => 'Left',
        _PenaltyDir.center => 'Center',
        _PenaltyDir.right => 'Right',
      };

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

    if (_phase == _Phase.finished) {
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
          _HudBar(
            theme: t,
            scheme: s,
            myGoals: _myGoals,
            oppGoals: _oppGoals,
            oppName: widget.opponentName,
            round: _roundIndex + 1,
            totalRounds: _totalRounds,
            secondsLeft: _secondsLeft,
            iAmStriker: _iAmStriker,
            onlinePickInProgress: widget.online != null &&
                _phase == _Phase.pick &&
                (_onlinePickSubmitting || _onlineWaitingForOpponent),
            timerPausedForOnlineWait: widget.online != null &&
                _phase == _Phase.pick &&
                _onlineWaitingForOpponent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _PitchAndGoal(
                  theme: t,
                  scheme: s,
                  phase: _phase,
                  kickCurve: _kickCurve,
                  strikerPick: _strikerPick,
                  keeperPick: _keeperPick,
                  iAmStriker: _iAmStriker,
                  scored: _lastKickScored,
                  dragNorm: _dragNorm,
                  dragging: _dragging,
                  bannerScale: _bannerScale,
                  resultLine: _lastResultLine,
                  strikerPower: _strikerPower,
                ),
                if (_phase == _Phase.reveal &&
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
                if (_phase == _Phase.pick) ...[
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
                    if (_iAmStriker) ...[
                      _PowerSlider(
                        theme: t,
                        scheme: s,
                        power: _powerNorm,
                        onChanged: (v) => setState(() => _powerNorm = v),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _DragAimStrip(
                      theme: t,
                      scheme: s,
                      dragNorm: _dragNorm,
                      dragging: _dragging,
                      isStriker: _iAmStriker,
                      onUpdate: _onDragUpdate,
                      onEnd: _onDragEnd,
                    ),
                  ],
                ],
                if (_phase == _Phase.reveal &&
                    _strikerPick != null &&
                    _keeperPick != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Shot ${_dirLabel(_strikerPick!)} · Dive ${_dirLabel(_keeperPick!)}',
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

// --- HUD ---

class _HudBar extends StatelessWidget {
  const _HudBar({
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

// --- Pitch + goal + animations ---

class _PitchAndGoal extends StatelessWidget {
  const _PitchAndGoal({
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
  final _Phase phase;
  final Animation<double> kickCurve;
  final _PenaltyDir? strikerPick;
  final _PenaltyDir? keeperPick;
  final bool iAmStriker;
  final bool scored;
  final double dragNorm;
  final bool dragging;
  final Animation<double> bannerScale;
  final String? resultLine;
  final double strikerPower;

  double _goalXForDir(_PenaltyDir d, double w) {
    return switch (d) {
      _PenaltyDir.left => w * 0.22,
      _PenaltyDir.center => w * 0.5,
      _PenaltyDir.right => w * 0.78,
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
                // Grass
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
                // Penalty arc hint
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
                // Goal frame + net
                Positioned(
                  left: w * 0.06,
                  right: w * 0.06,
                  top: grassTop,
                  height: h * 0.52,
                  child: _GoalFrame(
                    scheme: scheme,
                    dragNorm: phase == _Phase.pick ? dragNorm : null,
                    dragging: dragging,
                  ),
                ),
                // Aim preview line (striker only, pick phase)
                if (phase == _Phase.pick && iAmStriker)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AimLinePainter(
                        norm: dragNorm,
                        active: dragging,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                // Keeper
                if (strikerPick != null &&
                    keeperPick != null &&
                    (phase == _Phase.animating || phase == _Phase.reveal))
                  AnimatedBuilder(
                    animation: kickCurve,
                    builder: (context, child) {
                      final t = kickCurve.value;
                      final delayedT = ((t - 0.08) / 0.92).clamp(0.0, 1.0);
                      final diveX = _goalXForDir(keeperPick!, w);
                      final startX = w * 0.5;
                      final kx = lerpDouble(startX, diveX, Curves.easeOut.transform(delayedT))!;
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
                // Ball
                if (strikerPick != null &&
                    keeperPick != null &&
                    (phase == _Phase.animating || phase == _Phase.reveal))
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
                // Idle ball at spot (pick phase)
                if (phase == _Phase.pick)
                  Positioned(
                    left: w * 0.5 - 14,
                    top: h * 0.88 - 14,
                    child: _Ball(scheme: scheme, idle: true),
                  ),
                // Result banner
                if (phase == _Phase.reveal && resultLine != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: h * 0.34,
                    child: ScaleTransition(
                      scale: bannerScale,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(16),
                        color: scored
                            ? scheme.primary
                            : scheme.secondary,
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
                      active: dragNorm! < -0.35,
                      dragging: dragging,
                    ),
                  ),
                  Expanded(
                    child: _ZoneHint(
                      active: dragNorm! >= -0.35 && dragNorm! <= 0.35,
                      dragging: dragging,
                    ),
                  ),
                  Expanded(
                    child: _ZoneHint(
                      active: dragNorm! > 0.35,
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
    final bg = Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
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

class _PowerSlider extends StatelessWidget {
  const _PowerSlider({
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
          'above 72%.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// --- Drag strip ---

class _DragAimStrip extends StatelessWidget {
  const _DragAimStrip({
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
