part of 'penalty_shootout_game_screen.dart';

/// Imperative shootout flow (rounds, kicks, online sync). Mutates [_s] fields.
class _PenaltyShootoutLogic {
  _PenaltyShootoutLogic(this._s);

  final _PenaltyShootoutGameState _s;

  bool get iAmStriker =>
      _s.widget.online == null ? _s._roundIndex % 2 == 0 : _onlineStrikerForRound();

  bool _onlineStrikerForRound() {
    final sid = _strikerUserIdForIndex(_s._roundIndex);
    return PenaltyShootoutRules.uidEq(_s._myUserId, sid);
  }

  String _strikerUserIdForIndex(int round) {
    final cfg = _s.widget.online!;
    final from = _s._effFromId.trim().isNotEmpty ? _s._effFromId : cfg.fromUserId;
    final to = _s._effToId.trim().isNotEmpty ? _s._effToId : cfg.toUserId;
    return round % 2 == 0 ? from : to;
  }

  void onKickStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(_completeKickOutcome());
    }
  }

  void _applyKickDurationForPower(double power) {
    _s._kickCtrl.duration = Duration(
      milliseconds: PenaltyShootoutRules.kickDurationMs(power),
    );
  }

  Future<void> _finishOnlineMatchInDatabase() async {
    final cfg = _s.widget.online;
    if (cfg == null || _s._onlineMatchCleanupDone) return;
    _s._onlineMatchCleanupDone = true;
    final r = await cfg.repository.finishPenaltyMatchCleanup(
      challengeId: cfg.challengeId,
    );
    if (!_s.mounted) return;
    r.fold(
      (f) {
        _s._onlineMatchCleanupDone = false;
        ScaffoldMessenger.maybeOf(_s.context)?.showSnackBar(
          SnackBar(content: Text('Could not close out match: ${f.message}')),
        );
      },
      (_) {},
    );
  }

  Future<void> bootstrapOnlinePlay() async {
    final cfg = _s.widget.online!;
    _s._myUserId = Supabase.instance.client.auth.currentUser?.id;
    _s._effFromId = cfg.fromUserId;
    _s._effToId = cfg.toUserId;

    final sidesRes =
        await cfg.repository.fetchGameChallengeSides(challengeId: cfg.challengeId);
    sidesRes.fold((_) {}, (sides) {
      if (sides == null) return;
      final f = sides.fromUserId.trim();
      final t = sides.toUserId.trim();
      if (f.isNotEmpty) _s._effFromId = f;
      if (t.isNotEmpty) _s._effToId = t;
    });

    await cfg.repository.ensurePenaltyShootoutSession(challengeId: cfg.challengeId);
    if (!_s.mounted) return;
    await _pullSessionAndApply();
    if (!_s.mounted) return;
    _subscribePenaltyRealtime();
    _s._mutate(() => _s._onlineBootstrap = false);
    beginRound();
  }

  Future<void> _pullSessionAndApply() async {
    final cfg = _s.widget.online;
    if (cfg == null) return;
    if (_s._sessionPullInFlight) return;
    _s._sessionPullInFlight = true;
    try {
      final res =
          await cfg.repository.fetchPenaltyShootoutSession(challengeId: cfg.challengeId);
      PenaltyShootoutSessionModel? session;
      res.fold((_) => session = null, (v) => session = v);
      final sess = session;
      if (!_s.mounted || sess == null) return;
      if (_sessionVisuallyEquals(sess)) return;
      _s._mutate(() => _applySession(sess));
    } finally {
      _s._sessionPullInFlight = false;
    }
  }

  void _applySession(PenaltyShootoutSessionModel v) {
    _s._roundIndex = v.roundIndex;
    final cfg = _s.widget.online!;
    final uid = _s._myUserId;
    final from = _s._effFromId.trim().isNotEmpty ? _s._effFromId : cfg.fromUserId;
    if (PenaltyShootoutRules.uidEq(uid, from)) {
      _s._myGoals = v.fromGoals;
      _s._oppGoals = v.toGoals;
    } else {
      _s._myGoals = v.toGoals;
      _s._oppGoals = v.fromGoals;
    }
  }

  bool _sessionVisuallyEquals(PenaltyShootoutSessionModel v) {
    if (v.roundIndex != _s._roundIndex) return false;
    final cfg = _s.widget.online!;
    final uid = _s._myUserId;
    final from = _s._effFromId.trim().isNotEmpty ? _s._effFromId : cfg.fromUserId;
    final my = PenaltyShootoutRules.uidEq(uid, from) ? v.fromGoals : v.toGoals;
    final opp = PenaltyShootoutRules.uidEq(uid, from) ? v.toGoals : v.fromGoals;
    return my == _s._myGoals && opp == _s._oppGoals;
  }

  void _subscribePenaltyRealtime() {
    final cfg = _s.widget.online!;
    final id = cfg.challengeId;
    _s._penaltyChannel?.unsubscribe();
    _s._penaltyChannel = Supabase.instance.client
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
    if (_s.widget.online == null || !_s.mounted) return;
    if (_s._phase == PenaltyShootoutPhase.animating ||
        _s._phase == PenaltyShootoutPhase.reveal) {
      return;
    }
    _s._sessionPullDebounce?.cancel();
    _s._sessionPullDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!_s.mounted) return;
      unawaited(_pullSessionAndApply());
    });
  }

  Future<void> _completeKickOutcome() async {
    if (!_s.mounted || _s._kickOutcomeHandled) return;
    if (_s._phase != PenaltyShootoutPhase.animating) return;
    _s._kickOutcomeHandled = true;
    await _onKickAnimationComplete();
  }

  void beginRound() {
    _s._kickCtrl.reset();
    _s._bannerCtrl.reset();
    _s._countdown?.cancel();
    _s._onlinePickPoll?.cancel();
    if (_s._roundIndex >= PenaltyShootoutRules.totalRounds) {
      _s._mutate(() => _s._phase = PenaltyShootoutPhase.finished);
      unawaited(_finishOnlineMatchInDatabase());
      return;
    }

    _s._mutate(() {
      _s._phase = PenaltyShootoutPhase.pick;
      if (_s.widget.online == null) {
        _s._strikerPick = iAmStriker ? null : _randomDir();
        _s._keeperPick = null;
        if (!iAmStriker) {
          _s._strikerPower = 0.38 + _s._random.nextDouble() * 0.55;
        }
      } else {
        _s._strikerPick = null;
        _s._keeperPick = null;
      }
      _s._lastResultLine = null;
      _s._lastKickScored = false;
      _s._secondsLeft = PenaltyShootoutRules.secondsPerRound;
      _s._dragNorm = 0;
      _s._dragging = false;
      _s._powerNorm = 0.62;
      _s._onlinePickSubmitting = false;
      _s._onlineWaitingForOpponent = false;
    });

    _startPickPhaseCountdown();
  }

  void _startPickPhaseCountdown() {
    _s._countdown?.cancel();
    _s._countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_s.mounted) return;
      if (_s._phase != PenaltyShootoutPhase.pick) {
        _s._countdown?.cancel();
        return;
      }
      _s._mutate(() {
        _s._secondsLeft--;
        if (_s._secondsLeft <= 0) {
          _s._countdown?.cancel();
          unawaited(_applyTimeout());
        }
      });
    });
  }

  PenaltyShootoutDir _randomDir() =>
      PenaltyShootoutDir.values[_s._random.nextInt(3)];

  PenaltyShootoutDir _keeperPickVsStrikerShot(PenaltyShootoutDir shot) {
    if (_s._random.nextDouble() < PenaltyShootoutRules.aiKeeperReadShotChance) {
      return shot;
    }
    return _randomDir();
  }

  Future<void> _applyTimeout() async {
    if (_s._phase != PenaltyShootoutPhase.pick) return;
    _s._countdown?.cancel();
    final n = (_s._random.nextDouble() * 2) - 1;
    await _commitFromDragNorm(n);
  }

  void onDragUpdate(DragUpdateDetails d, double trackWidth) {
    if (_s._phase != PenaltyShootoutPhase.pick) return;
    if (_s.widget.online != null &&
        (_s._onlinePickSubmitting || _s._onlineWaitingForOpponent)) {
      return;
    }
    final delta = d.delta.dx / (trackWidth * 0.45);
    _s._mutate(() {
      _s._dragging = true;
      _s._dragNorm = (_s._dragNorm + delta).clamp(-1.0, 1.0);
    });
  }

  void onDragEnd() {
    if (_s._phase != PenaltyShootoutPhase.pick) return;
    if (_s.widget.online != null &&
        (_s._onlinePickSubmitting || _s._onlineWaitingForOpponent)) {
      return;
    }
    _s._countdown?.cancel();
    unawaited(_commitFromDragNorm(_s._dragNorm));
  }

  Future<void> _commitFromDragNorm(double n) async {
    if (_s._phase != PenaltyShootoutPhase.pick) return;
    final dir = PenaltyShootoutRules.normToDir(n);

    if (_s.widget.online != null) {
      await _commitOnlinePick(dir);
      return;
    }

    _s._mutate(() {
      _s._dragging = false;
      if (iAmStriker) {
        _s._strikerPick = dir;
        _s._keeperPick = _keeperPickVsStrikerShot(dir);
        _s._strikerPower = _s._powerNorm.clamp(0.0, 1.0);
      } else {
        _s._keeperPick = dir;
        _s._strikerPick ??= _randomDir();
        _s._strikerPower = 0.38 + _s._random.nextDouble() * 0.55;
      }
    });

    final shot = _s._strikerPick!;
    final dive = _s._keeperPick!;
    _s._lastKickScored =
        PenaltyShootoutRules.computeScored(shot, dive, _s._strikerPower);

    if (iAmStriker) {
      if (_s._lastKickScored) _s._myGoals++;
    } else {
      if (_s._lastKickScored) _s._oppGoals++;
    }

    _applyKickDurationForPower(_s._strikerPower);
    _s._mutate(() => _s._phase = PenaltyShootoutPhase.animating);
    HapticFeedback.selectionClick();
    _s._kickOutcomeHandled = false;
    _s._kickCtrl.forward(from: 0);
    _scheduleKickOutcomeFallback();
  }

  Future<void> _commitOnlinePick(PenaltyShootoutDir dir) async {
    final cfg = _s.widget.online!;
    if (_s._myUserId == null || _s._myUserId!.isEmpty) return;

    _s._mutate(() {
      _s._dragging = false;
      _s._onlinePickSubmitting = true;
      _s._onlineWaitingForOpponent = false;
    });

    final strikerUid = _strikerUserIdForIndex(_s._roundIndex);
    final isShot = PenaltyShootoutRules.uidEq(_s._myUserId, strikerUid);
    final kind = isShot ? PenaltyPickKind.shot : PenaltyPickKind.dive;
    final direction = PenaltyShootoutRules.dirToInt(dir);
    final power = isShot ? _s._powerNorm.clamp(0.0, 1.0) : null;

    final up = await cfg.repository.upsertPenaltyRoundPick(
      challengeId: cfg.challengeId,
      roundIndex: _s._roundIndex,
      pickKind: kind,
      direction: direction,
      power: power,
    );
    if (!_s.mounted) return;
    up.fold(
      (f) {
        if (!_s.mounted) return;
        _s._mutate(() {
          _s._onlinePickSubmitting = false;
          _s._onlineWaitingForOpponent = false;
        });
        ScaffoldMessenger.maybeOf(_s.context)?.showSnackBar(
          SnackBar(content: Text('Could not submit pick: ${f.message}')),
        );
      },
      (_) {
        if (!_s.mounted) return;
        _s._countdown?.cancel();
        _s._mutate(() {
          _s._onlinePickSubmitting = false;
          _s._onlineWaitingForOpponent = true;
        });
        unawaited(_fetchAndResolveOnlinePicks());
        _startOnlinePickPoll();
      },
    );
  }

  void _startOnlinePickPoll() {
    if (_s.widget.online == null || _s._phase != PenaltyShootoutPhase.pick) return;
    _s._onlinePickPoll?.cancel();
    var ticks = 0;
    _s._onlinePickPoll = Timer.periodic(const Duration(milliseconds: 400), (_) {
      ticks++;
      if (!_s.mounted ||
          _s._phase != PenaltyShootoutPhase.pick ||
          _s.widget.online == null) {
        _s._onlinePickPoll?.cancel();
        return;
      }
      if (ticks > 80) {
        _s._onlinePickPoll?.cancel();
        return;
      }
      unawaited(_fetchAndResolveOnlinePicks());
    });
  }

  Future<void> _fetchAndResolveOnlinePicks() async {
    final cfg = _s.widget.online;
    if (cfg == null || !_s.mounted) return;
    if (_s._phase != PenaltyShootoutPhase.pick) return;

    final roundAtStart = _s._roundIndex;

    final res = await cfg.repository.fetchPenaltyRoundPicks(
      challengeId: cfg.challengeId,
      roundIndex: roundAtStart,
    );
    if (!_s.mounted || _s._roundIndex != roundAtStart) return;
    if (_s._phase != PenaltyShootoutPhase.pick) return;

    List<PenaltyRoundPickModel>? picks;
    res.fold((_) => picks = null, (list) => picks = list);
    final list = picks;
    if (!_s.mounted || list == null || list.length < 2) return;

    PenaltyRoundPickModel? shotPick;
    PenaltyRoundPickModel? divePick;
    for (final p in list) {
      final k = p.pickKind.toLowerCase().trim();
      if (k == PenaltyPickKind.shot) shotPick = p;
      if (k == PenaltyPickKind.dive) divePick = p;
    }
    if (shotPick == null || divePick == null) return;
    if (PenaltyShootoutRules.uidEq(shotPick.userId, divePick.userId)) return;

    if (!_s.mounted ||
        _s._roundIndex != roundAtStart ||
        _s._phase != PenaltyShootoutPhase.pick) {
      return;
    }

    final shot = PenaltyShootoutRules.intToDir(shotPick.direction);
    final dive = PenaltyShootoutRules.intToDir(divePick.direction);
    final power = shotPick.power ?? 0.62;

    _s._onlinePickPoll?.cancel();
    _s._countdown?.cancel();

    _s._roundBeingResolved = _s._roundIndex;
    _s._lastStrikerUserId = shotPick.userId;
    _s._strikerPower = power;
    _s._lastKickScored = PenaltyShootoutRules.computeScored(shot, dive, power);

    _s._mutate(() {
      _s._strikerPick = shot;
      _s._keeperPick = dive;
      _s._phase = PenaltyShootoutPhase.animating;
      _s._onlineWaitingForOpponent = false;
      _s._onlinePickSubmitting = false;
    });

    _applyKickDurationForPower(power);
    HapticFeedback.selectionClick();
    _s._kickOutcomeHandled = false;
    _s._kickCtrl.forward(from: 0);
    _scheduleKickOutcomeFallback();
  }

  void _scheduleKickOutcomeFallback() {
    final ms = _s._kickCtrl.duration?.inMilliseconds ?? 920;
    unawaited(
      Future<void>.delayed(Duration(milliseconds: ms + 120), () async {
        if (!_s.mounted) return;
        await _completeKickOutcome();
      }),
    );
  }

  Future<void> _onKickAnimationComplete() async {
    if (!_s.mounted) return;
    final strikerWasMe = _s.widget.online == null
        ? iAmStriker
        : PenaltyShootoutRules.uidEq(_s._lastStrikerUserId, _s._myUserId);
    final who = strikerWasMe ? 'You' : _s.widget.opponentName;
    final scored = _s._lastKickScored;

    if (_s.widget.online != null) {
      final cfg = _s.widget.online!;
      final sid =
          _s._lastStrikerUserId ?? _strikerUserIdForIndex(_s._roundBeingResolved);
      final from = _s._effFromId.trim().isNotEmpty ? _s._effFromId : cfg.fromUserId;
      final to = _s._effToId.trim().isNotEmpty ? _s._effToId : cfg.toUserId;
      try {
        await cfg.repository.advancePenaltyRound(
          challengeId: cfg.challengeId,
          expectedRoundIndex: _s._roundBeingResolved,
          fromGoalsDelta:
              scored && PenaltyShootoutRules.uidEq(sid, from) ? 1 : 0,
          toGoalsDelta: scored && PenaltyShootoutRules.uidEq(sid, to) ? 1 : 0,
        );
        if (!_s.mounted) return;
        await _pullSessionAndApply();
      } catch (_) {
        if (_s.mounted) await _pullSessionAndApply();
      }
    }

    if (!_s.mounted) return;
    _s._mutate(() {
      _s._phase = PenaltyShootoutPhase.reveal;
      _s._lastResultLine = scored
          ? '$who — GOAL!'
          : '$who — saved!';
    });

    if (scored) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _s._bannerCtrl.forward(from: 0);

    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!_s.mounted) return;
      var goNextRound = false;
      if (_s.widget.online == null) {
        _s._mutate(() {
          _s._roundIndex++;
          if (_s._roundIndex >= PenaltyShootoutRules.totalRounds) {
            _s._phase = PenaltyShootoutPhase.finished;
          } else {
            goNextRound = true;
          }
        });
        if (goNextRound) {
          beginRound();
        }
      } else {
        var finishedNow = false;
        _s._mutate(() {
          // After the last scheduled round (0..totalRounds-1), the server row may already
          // be deleted by the opponent's cleanup, so _roundIndex might never reach
          // totalRounds locally. Still treat the match as over.
          final matchOver = _s._roundIndex >= PenaltyShootoutRules.totalRounds ||
              _s._roundBeingResolved >= PenaltyShootoutRules.totalRounds - 1;
          if (matchOver) {
            _s._phase = PenaltyShootoutPhase.finished;
            finishedNow = true;
          } else {
            goNextRound = true;
          }
        });
        if (finishedNow) {
          unawaited(_finishOnlineMatchInDatabase());
        }
        if (goNextRound) {
          beginRound();
        }
      }
    });
  }
}
