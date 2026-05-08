import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_room_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local party game for 2-5 players on one device.
class PartyReactionRelayGame extends StatefulWidget {
  const PartyReactionRelayGame({super.key, this.roomId});

  final String? roomId;

  @override
  State<PartyReactionRelayGame> createState() =>
      _PartyReactionRelayGameStateV2();
}

enum _RelayPhase {
  setup,
  waitingArm,
  waitingGo,
  tapNow,
  betweenRounds,
  finished,
}

class _RelayRoundWinner {
  const _RelayRoundWinner({
    required this.round,
    required this.playerIndex,
    required this.ms,
  });

  final int round;
  final int playerIndex;
  final int ms;
}

class _PartyReactionRelayGameStateV2 extends State<PartyReactionRelayGame> {
  static const int _totalRounds = 5;

  /// Finish all 5 rounds within this limit or you lose (online + offline).
  static const int _matchTimeLimitSeconds = 120;
  final _rng = Random();

  int _players = 2; // offline only
  int _round = 1;
  int _turn = 0; // offline player turn in current round
  _RelayPhase _phase = _RelayPhase.setup;
  static const int _maxFalseStartTries = 3;
  int _falseStartTriesLeft = _maxFalseStartTries;
  String? _roundHint;

  final Map<int, int> _currentRoundTimes = {}; // player -> ms
  final Map<int, int> _wins = {}; // player -> round wins
  final List<_RelayRoundWinner> _winnerQueue = [];
  final List<int> _myOnlineRoundTimes = [];
  int? _bestMs;

  Timer? _goTimer;
  Timer? _matchTimer;
  Timer? _chaseTimer;
  Timer? _leaderboardPoll;
  DateTime? _goAt;
  ConfettiController? _confetti;
  int _matchSecondsLeft = 0;
  bool _matchTimedOut = false;

  List<PartyRoomScoreRow> _leaderboard = const [];
  String? _onlineFinalOutcomeText;
  bool get _online => (widget.roomId?.trim().isNotEmpty ?? false);
  int get _turnsInRound => _online ? 1 : _players;

  /// Rounds 1–2: full-width static GO button. Rounds 3–5: moving tap target.
  static const int _staticTapRounds = 2;
  static const double _chaseArenaW = 320;
  static const double _chaseArenaH = 260;
  static const double _chaseTargetW = 92;
  static const double _chaseTargetH = 52;
  double _chaseX = 0;
  double _chaseY = 0;
  double _chaseVelX = 3;
  double _chaseVelY = 2.5;

  bool get _isChaseRound => _round > _staticTapRounds;

  int get _completedRounds {
    if (_online) return _myOnlineRoundTimes.length;
    if (_phase == _RelayPhase.finished) return _totalRounds;
    return _winnerQueue.length;
  }

  /// Online: every joined room member has submitted a full 5-round run (or timed out).
  bool _everyJoinedPlayerFinishedRun() {
    if (!_online) return true;
    if (_leaderboard.length < 2) return false;
    for (final row in _leaderboard) {
      if (row.meta['timed_out'] == true) continue;
      final raw = row.meta['round_times'];
      if (raw is! List || raw.length < _totalRounds) return false;
    }
    return true;
  }

  Future<void> _onPlayAgainPressed() async {
    if (_online) {
      if (!_everyJoinedPlayerFinishedRun()) return;
      final rid = widget.roomId?.trim() ?? '';
      if (rid.isEmpty) return;
      try {
        await PartyRoomService.resetPartyRoomMatchIfAllFinished(roomId: rid);
      } catch (e) {
        if (!mounted) return;
        final s = e.toString();
        final friendly =
            s.contains('all_players_must_finish') || s.contains('all players')
            ? context.l10n.everyoneMustFinishRoundsBeforeNewRun(_totalRounds)
            : s;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendly)));
        return;
      }
    }
    _resetMatch();
    if (_online) await _pullLeaderboard();
  }

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _resetMatch();
    _startLeaderboardPolling();
  }

  @override
  void dispose() {
    _goTimer?.cancel();
    _matchTimer?.cancel();
    _chaseTimer?.cancel();
    _leaderboardPoll?.cancel();
    _confetti?.dispose();
    super.dispose();
  }

  void _startLeaderboardPolling() {
    if (!_online) return;
    _pullLeaderboard();
    _leaderboardPoll?.cancel();
    _leaderboardPoll = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pullLeaderboard(),
    );
  }

  Future<void> _pullLeaderboard() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    final rows = await PartyRoomService.fetchLeaderboard(rid);
    if (!mounted) return;
    if (_shouldSyncResetAfterServerClear(rows)) {
      _resetMatch();
    }
    setState(() => _leaderboard = rows);
    _tryResolveOnlineRoundOutcome();
  }

  /// Another device cleared scores (new run). Drop local finished state so we do not replay alone.
  bool _shouldSyncResetAfterServerClear(List<PartyRoomScoreRow> rows) {
    if (!_online || _phase != _RelayPhase.finished) return false;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    PartyRoomScoreRow? mine;
    for (final r in rows) {
      if (r.userId == uid) {
        mine = r;
        break;
      }
    }
    if (mine == null) return false;
    final raw = mine.meta['round_times'];
    final serverLen = raw is List ? raw.length : 0;
    if (serverLen > 0) return false;
    final localComplete =
        _myOnlineRoundTimes.length >= _totalRounds || _matchTimedOut;
    return localComplete;
  }

  String _playerLabel(int i) =>
      _online ? context.l10n.you : context.l10n.playerNumber(i + 1);

  void _resetMatch() {
    _goTimer?.cancel();
    _chaseTimer?.cancel();
    _matchTimer?.cancel();
    _currentRoundTimes.clear();
    _winnerQueue.clear();
    _myOnlineRoundTimes.clear();
    _wins
      ..clear()
      ..addEntries(List.generate(_turnsInRound, (i) => MapEntry(i, 0)));
    setState(() {
      _round = 1;
      _turn = 0;
      _phase = _RelayPhase.setup;
      _goAt = null;
      _bestMs = null;
      _onlineFinalOutcomeText = null;
      _matchSecondsLeft = 0;
      _matchTimedOut = false;
      _falseStartTriesLeft = _maxFalseStartTries;
      _roundHint = null;
    });
  }

  void _startMatchCountdown() {
    _matchTimer?.cancel();
    _matchSecondsLeft = _matchTimeLimitSeconds;
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_phase == _RelayPhase.finished) {
        _matchTimer?.cancel();
        return;
      }
      final next = _matchSecondsLeft - 1;
      if (next <= 0) {
        _matchTimer?.cancel();
        setState(() => _matchSecondsLeft = 0);
        _onMatchTimeExpired();
      } else {
        setState(() => _matchSecondsLeft = next);
      }
    });
  }

  void _stopMatchCountdown() {
    _matchTimer?.cancel();
    _matchTimer = null;
    _matchSecondsLeft = 0;
  }

  Future<void> _onMatchTimeExpired() async {
    if (!mounted || _phase == _RelayPhase.finished) return;
    _goTimer?.cancel();
    _chaseTimer?.cancel();
    _matchTimedOut = true;
    if (_online) {
      if (_myOnlineRoundTimes.length < _totalRounds) {
        setState(() {
          _phase = _RelayPhase.finished;
          _onlineFinalOutcomeText = context.l10n
              .timeRanOutBeforeFinishingRoundsLose(_totalRounds);
        });
        await _submitTimeoutLossOnline();
      }
    } else {
      setState(() {
        _phase = _RelayPhase.finished;
      });
    }
  }

  Future<void> _submitTimeoutLossOnline() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    await PartyRoomService.submitScore(
      roomId: rid,
      score: 1,
      meta: {
        'game': 'reaction_relay',
        'rounds': _totalRounds,
        'timed_out': true,
        'round_times': List<int>.from(_myOnlineRoundTimes),
      },
    );
    await _pullLeaderboard();
  }

  void _startRound() {
    final wasSetup = _phase == _RelayPhase.setup;
    _goTimer?.cancel();
    _currentRoundTimes.clear();
    setState(() {
      _turn = 0;
      _phase = _RelayPhase.waitingArm;
      _falseStartTriesLeft = _maxFalseStartTries;
      _roundHint = null;
    });
    if (wasSetup) {
      _startMatchCountdown();
    }
  }

  void _arm() {
    if (!mounted || _matchTimedOut || _phase == _RelayPhase.finished) return;
    _goTimer?.cancel();
    _chaseTimer?.cancel();
    setState(() {
      _phase = _RelayPhase.waitingGo;
      _goAt = null;
    });
    final delayMs = 1200 + _rng.nextInt(2200);
    _goTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _phase = _RelayPhase.tapNow;
        _goAt = DateTime.now();
      });
      if (_isChaseRound) {
        _startChaseMovement();
      }
    });
  }

  void _startChaseMovement() {
    _chaseTimer?.cancel();
    final maxX = _chaseArenaW - _chaseTargetW;
    final maxY = _chaseArenaH - _chaseTargetH;
    // Rounds 3 -> 5 ramp movement speed progressively for higher difficulty.
    final chaseRoundIndex = (_round - _staticTapRounds).clamp(1, 3);
    final speedMultiplier = 1.0 + (chaseRoundIndex - 1) * 0.22;
    _chaseX = _rng.nextDouble() * maxX;
    _chaseY = _rng.nextDouble() * maxY;
    _chaseVelX =
        (_rng.nextBool() ? 1 : -1) *
        (2.2 + _rng.nextDouble() * 2.8) *
        speedMultiplier;
    _chaseVelY =
        (_rng.nextBool() ? 1 : -1) *
        (2.0 + _rng.nextDouble() * 2.5) *
        speedMultiplier;
    setState(() {});
    _chaseTimer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (!mounted || _phase != _RelayPhase.tapNow || !_isChaseRound) {
        _chaseTimer?.cancel();
        return;
      }
      setState(() {
        _chaseX += _chaseVelX;
        _chaseY += _chaseVelY;
        if (_chaseX <= 0 || _chaseX >= maxX) {
          _chaseVelX = -_chaseVelX;
          _chaseX = _chaseX.clamp(0.0, maxX);
        }
        if (_chaseY <= 0 || _chaseY >= maxY) {
          _chaseVelY = -_chaseVelY;
          _chaseY = _chaseY.clamp(0.0, maxY);
        }
      });
    });
  }

  void _stopChaseMovement() {
    _chaseTimer?.cancel();
    _chaseTimer = null;
  }

  Future<void> _onFalseStartTap() async {
    if (!mounted || _phase != _RelayPhase.waitingGo) return;
    final next = _falseStartTriesLeft - 1;
    _goTimer?.cancel();
    _stopChaseMovement();
    if (next > 0) {
      setState(() {
        _falseStartTriesLeft = next;
        _phase = _RelayPhase.waitingArm;
        _roundHint = context.l10n.tooEarlyTryAgain(next, _maxFalseStartTries);
      });
      return;
    }

    // 3 early taps exhausted: this turn is failed.
    const failMs = 9999;
    if (_online) {
      _myOnlineRoundTimes.add(failMs);
      if (_round >= _totalRounds) {
        _stopMatchCountdown();
        setState(() {
          _phase = _RelayPhase.finished;
          _roundHint = context.l10n.roundFailedAfterEarlyTaps;
        });
        await _submitIfOnline();
        return;
      }
      setState(() {
        _round += 1;
        _phase = _RelayPhase.betweenRounds;
        _roundHint = context.l10n.roundFailedPenaltyMs(failMs);
      });
      await _submitOnlineProgress();
      return;
    }

    _currentRoundTimes[_turn] = failMs;
    if (_turn < _players - 1) {
      setState(() {
        _turn += 1;
        _phase = _RelayPhase.waitingArm;
        _falseStartTriesLeft = _maxFalseStartTries;
        _roundHint = context.l10n.playerUpNextPreviousTurnFailed(
          _playerLabel(_turn),
        );
      });
      return;
    }
    _completeOfflineRound();
    setState(() {
      _roundHint = context.l10n.turnFailedAfterEarlyTaps;
    });
  }

  Future<void> _tapNow() async {
    if (_matchTimedOut || _phase == _RelayPhase.finished) return;
    if (_phase != _RelayPhase.tapNow || _goAt == null) return;
    _stopChaseMovement();
    final ms = DateTime.now().difference(_goAt!).inMilliseconds;
    _bestMs = _bestMs == null ? ms : min(_bestMs!, ms);

    if (_online) {
      _myOnlineRoundTimes.add(ms);
      if (_round >= _totalRounds) {
        _stopMatchCountdown();
        setState(() => _phase = _RelayPhase.finished);
        _submitIfOnline();
        return;
      }
      setState(() {
        _round += 1;
        _phase = _RelayPhase.betweenRounds;
      });
      await _submitOnlineProgress();
      return;
    }

    _currentRoundTimes[_turn] = ms;
    if (_turn < _players - 1) {
      setState(() {
        _turn += 1;
        _phase = _RelayPhase.waitingArm;
        _falseStartTriesLeft = _maxFalseStartTries;
        _roundHint = null;
      });
      return;
    }

    _completeOfflineRound();
  }

  void _completeOfflineRound() {
    int winner = 0;
    int best = 1 << 30;
    for (final e in _currentRoundTimes.entries) {
      if (e.value < best) {
        best = e.value;
        winner = e.key;
      }
    }
    _wins[winner] = (_wins[winner] ?? 0) + 1;
    _winnerQueue.add(
      _RelayRoundWinner(round: _round, playerIndex: winner, ms: best),
    );

    if (_round >= _totalRounds) {
      _stopMatchCountdown();
      setState(() => _phase = _RelayPhase.finished);
      return;
    }
    setState(() {
      _round += 1;
      _phase = _RelayPhase.betweenRounds;
    });
  }

  Future<void> _submitIfOnline() async {
    if (_matchTimedOut) return;
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    final best = _bestMs;
    if (best == null) return;
    final score = (10000 - best).clamp(1, 10000);
    await PartyRoomService.submitScore(
      roomId: rid,
      score: score,
      meta: {
        'best_ms': best,
        'game': 'reaction_relay',
        'rounds': _totalRounds,
        'round_times': _myOnlineRoundTimes,
      },
    );
    await _pullLeaderboard();
    _resolveOnlineFinalOutcome();
  }

  Future<void> _submitOnlineProgress() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    if (_myOnlineRoundTimes.isEmpty) return;
    final best = _bestMs;
    if (best == null) return;
    final score = (10000 - best).clamp(1, 10000);
    await PartyRoomService.submitScore(
      roomId: rid,
      score: score,
      meta: {
        'best_ms': best,
        'game': 'reaction_relay',
        'rounds': _totalRounds,
        'round_times': _myOnlineRoundTimes,
      },
    );
  }

  int? _sumRoundTimesFromMeta(PartyRoomScoreRow row) {
    final raw = row.meta['round_times'];
    if (raw is! List) return null;
    if (raw.length < _totalRounds) return null;
    var sum = 0;
    for (var i = 0; i < _totalRounds; i++) {
      final v = raw[i];
      if (v is! num) return null;
      sum += v.toInt();
    }
    return sum;
  }

  void _tryResolveOnlineRoundOutcome() {
    if (!_online) return;
    _resolveOnlineFinalOutcome();
  }

  void _resolveOnlineFinalOutcome() {
    if (!_online || _phase != _RelayPhase.finished) return;
    if (_matchTimedOut) return;
    if (_myOnlineRoundTimes.length < _totalRounds) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    PartyRoomScoreRow? opponent;
    for (final row in _leaderboard) {
      if (row.userId != uid) {
        opponent = row;
        break;
      }
    }
    if (opponent == null) {
      setState(() {
        _onlineFinalOutcomeText = context.l10n.waitingOpponentFinishRounds(
          _totalRounds,
        );
      });
      return;
    }
    final opp = opponent;
    if (opp.meta['timed_out'] == true) {
      setState(() {
        _onlineFinalOutcomeText = context.l10n.youWinOpponentTimedOut(
          opp.username,
        );
        _confetti?.play();
      });
      return;
    }
    final oppTotal = _sumRoundTimesFromMeta(opp);
    if (oppTotal == null) {
      setState(() {
        _onlineFinalOutcomeText = context.l10n.waitingUserFinishRounds(
          opp.username,
          _totalRounds,
        );
      });
      return;
    }
    var myTotal = 0;
    for (final ms in _myOnlineRoundTimes) {
      myTotal += ms;
    }
    String outcome;
    if (myTotal < oppTotal) {
      outcome = context.l10n.youWinTotalVs(myTotal, opp.username, oppTotal);
      _confetti?.play();
    } else if (myTotal > oppTotal) {
      outcome = context.l10n.opponentWinsTotalVs(
        opp.username,
        oppTotal,
        myTotal,
      );
    } else {
      outcome = context.l10n.finalDrawTotals(myTotal);
    }
    setState(() {
      _onlineFinalOutcomeText = outcome;
    });
  }

  List<MapEntry<int, int>> get _offlineRanking {
    final rows = <MapEntry<int, int>>[
      for (var i = 0; i < _players; i++) MapEntry(i, _wins[i] ?? 0),
    ];
    rows.sort((a, b) => b.value.compareTo(a.value));
    return rows;
  }

  BoxDecoration _playfieldShell(ColorScheme scheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.surfaceContainerHighest,
          scheme.surfaceContainerHigh.withValues(alpha: 0.92),
        ],
      ),
      border: Border.all(
        color: scheme.primary.withValues(alpha: 0.45),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _roundPips(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalRounds, (i) {
        final n = i + 1;
        final done = n <= _completedRounds;
        final live =
            n == _round &&
            _phase != _RelayPhase.finished &&
            _phase != _RelayPhase.setup &&
            !(_phase == _RelayPhase.betweenRounds && _online);
        final accent = scheme.primary;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: live ? 14 : 11,
          height: live ? 14 : 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? accent : scheme.surface.withValues(alpha: 0.35),
            border: Border.all(
              color: live ? accent : scheme.outline.withValues(alpha: 0.4),
              width: live ? 2.5 : 1.2,
            ),
            boxShadow: live
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _hudChip(
    ThemeData theme,
    ColorScheme scheme,
    IconData icon,
    String label, {
    Color? tint,
  }) {
    final c = tint ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                color: scheme.onPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onlineGameReactionRelay.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _online
                        ? l10n.reactionRelayOnlineSubtitle(
                            _matchTimeLimitSeconds,
                          )
                        : l10n.reactionRelayOfflineSubtitle(
                            _matchTimeLimitSeconds,
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: _playfieldShell(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _roundPips(scheme),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (!_online)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _players,
                              isDense: true,
                              borderRadius: BorderRadius.circular(12),
                              items: const [2, 3, 4, 5]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(l10n.playersCount(v)),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  (_phase == _RelayPhase.setup ||
                                      _phase == _RelayPhase.finished)
                                  ? (v) {
                                      if (v == null) return;
                                      setState(() => _players = v);
                                      _resetMatch();
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _hudChip(
                    theme,
                    scheme,
                    _isChaseRound
                        ? Icons.motion_photos_on_rounded
                        : Icons.touch_app_rounded,
                    _isChaseRound ? l10n.chaseUpper : l10n.classicUpper,
                    tint: _isChaseRound ? scheme.tertiary : scheme.secondary,
                  ),
                  _hudChip(
                    theme,
                    scheme,
                    Icons.flag_rounded,
                    l10n.roundShortProgress(_round, _totalRounds),
                  ),
                  if (_matchSecondsLeft > 0 && _phase != _RelayPhase.finished)
                    _hudChip(
                      theme,
                      scheme,
                      Icons.timer_rounded,
                      _formatCountdown(_matchSecondsLeft),
                      tint: _matchSecondsLeft <= 15
                          ? scheme.error
                          : scheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                (!_matchTimedOut &&
                    (_phase == _RelayPhase.setup ||
                        _phase == _RelayPhase.betweenRounds))
                ? _startRound
                : null,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      (!_matchTimedOut &&
                          (_phase == _RelayPhase.setup ||
                              _phase == _RelayPhase.betweenRounds))
                      ? [
                          scheme.primary,
                          scheme.primaryContainer.withValues(alpha: 0.95),
                        ]
                      : [
                          scheme.surfaceContainerHighest,
                          scheme.surfaceContainerHigh,
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 30,
                      color:
                          (!_matchTimedOut &&
                              (_phase == _RelayPhase.setup ||
                                  _phase == _RelayPhase.betweenRounds))
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _round == 1 && _phase == _RelayPhase.setup
                          ? l10n.startMatch.toUpperCase()
                          : l10n.nextRound.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color:
                            (!_matchTimedOut &&
                                (_phase == _RelayPhase.setup ||
                                    _phase == _RelayPhase.betweenRounds))
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildActionCard(theme, scheme),
        if (_phase == _RelayPhase.finished) ...[
          const SizedBox(height: 14),
          if (_online && !_everyJoinedPlayerFinishedRun()) ...[
            Text(
              l10n.waitAllPlayersFinishThenReset(_totalRounds),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: (!_online || _everyJoinedPlayerFinishedRun())
                ? () async => _onPlayAgainPressed()
                : null,
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.playAgain.toUpperCase()),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (_online) ...[
          SizedBox(
            height: 48,
            child: ConfettiWidget(
              confettiController: _confetti!,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 22,
              shouldLoop: false,
            ),
          ),
          Text(
            l10n.yourRun.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
            ),
            child: _myOnlineRoundTimes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noSplitsYetStartMatch,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _myOnlineRoundTimes.length; i++)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              '${_myOnlineRoundTimes[i]}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onPrimaryContainer,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          title: Text(
                            l10n.roundNumber(i + 1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.ms,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ] else ...[
          Text(
            l10n.roundLog.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
            ),
            child: _winnerQueue.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.winsAppearAfterEachRound,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final r in _winnerQueue)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.secondaryContainer,
                            child: Text(
                              '${r.ms}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onSecondaryContainer,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          title: Text(_playerLabel(r.playerIndex)),
                          subtitle: Text(
                            l10n.roundMsLabel(r.round),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(ThemeData theme, ColorScheme scheme) {
    switch (_phase) {
      case _RelayPhase.setup:
        return _infoCard(
          theme,
          scheme,
          'Hit START MATCH when everyone is ready. You have $_matchTimeLimitSeconds seconds for all 5 rounds.',
          icon: Icons.sports_esports_rounded,
        );
      case _RelayPhase.waitingArm:
        return Container(
          decoration: _playfieldShell(scheme),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UP NOW',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: scheme.primary,
                          ),
                        ),
                        Text(
                          _playerLabel(_turn),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _online
                    ? (_isChaseRound
                          ? 'After GO, hunt the moving TAP chip inside the arena.'
                          : 'After GO, smash the big reaction button.')
                    : (_isChaseRound
                          ? 'Chase round — handoff to ${_playerLabel(_turn)}.'
                          : 'Hand the device to ${_playerLabel(_turn)}.'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              if (_roundHint != null) ...[
                const SizedBox(height: 10),
                Text(
                  _roundHint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: (_matchTimedOut || _phase == _RelayPhase.finished)
                    ? null
                    : _arm,
                child: Text(
                  'ARM • READY',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        );
      case _RelayPhase.waitingGo:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _onFalseStartTap,
            child: Container(
              decoration: _playfieldShell(scheme),
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
              child: Column(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.2,
                      color: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Pulse(
                    child: Text(
                      'GET READY',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Do not tap early. Early tap = retry. Max 3 tries for this turn.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tries left: $_falseStartTriesLeft/$_maxFalseStartTries',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _falseStartTriesLeft == 1
                          ? scheme.error
                          : scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case _RelayPhase.tapNow:
        return _buildTapPhase(theme, scheme);
      case _RelayPhase.betweenRounds:
        if (_online) {
          final last = _myOnlineRoundTimes.isEmpty
              ? null
              : _myOnlineRoundTimes.last;
          return Container(
            decoration: _playfieldShell(scheme),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: scheme.tertiary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        last == null ? 'Round saved.' : '$last ms • nice hit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Round ${_myOnlineRoundTimes.length} locked in. Queue NEXT ROUND when you want more heat.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        }
        if (_winnerQueue.isEmpty) {
          return _infoCard(
            theme,
            scheme,
            'Round complete.',
            icon: Icons.emoji_events_outlined,
          );
        }
        final lastWinner = _winnerQueue.last;
        return _infoCard(
          theme,
          scheme,
          'Round ${lastWinner.round} → ${_playerLabel(lastWinner.playerIndex)} '
          '(${lastWinner.ms} ms)',
          icon: Icons.military_tech_rounded,
        );
      case _RelayPhase.finished:
        final msg = _matchTimedOut && !_online
            ? 'Time ran out before all 5 rounds. Match over — no champion.'
            : _online
            ? (_onlineFinalOutcomeText ??
                  'Finished 5 rounds. Waiting final result against opponent...')
            : (_winnerQueue.isEmpty
                  ? 'Finished.'
                  : 'Champion: ${_playerLabel(_offlineRanking.first.key)}');
        final lower = msg.toLowerCase();
        final won = lower.contains('you win');
        final couchPodium =
            !_online && _winnerQueue.isNotEmpty && !_matchTimedOut;
        return _infoCard(
          theme,
          scheme,
          msg,
          icon: _matchTimedOut && !_online
              ? Icons.timer_off_rounded
              : (won || couchPodium)
              ? Icons.emoji_events_rounded
              : Icons.flag_rounded,
        );
    }
  }

  Widget _buildTapPhase(ThemeData theme, ColorScheme scheme) {
    if (_matchTimedOut) {
      return const SizedBox.shrink();
    }
    if (!_isChaseRound) {
      return Container(
        decoration: _playfieldShell(scheme),
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(22),
          shadowColor: scheme.primary.withValues(alpha: 0.5),
          child: InkWell(
            onTap: _tapNow,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.tertiary],
                ),
              ),
              child: SizedBox(
                height: 128,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: scheme.onPrimary, size: 42),
                    const SizedBox(height: 6),
                    Text(
                      'GO!  TAP!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One clean hit',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final gridColor = scheme.onSurface.withValues(alpha: 0.06);
    return Container(
      decoration: _playfieldShell(scheme),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed_rounded, color: scheme.tertiary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CHASE ARENA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'LIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target is slippery — track it and tap the chip.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: _chaseArenaW,
              height: _chaseArenaH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface.withValues(alpha: 0.92),
                    scheme.primaryContainer.withValues(alpha: 0.35),
                    scheme.tertiaryContainer.withValues(alpha: 0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  CustomPaint(
                    painter: _ArenaGridPainter(lineColor: gridColor),
                    size: Size(_chaseArenaW, _chaseArenaH),
                  ),
                  ..._arenaCornerBrackets(scheme),
                  Positioned(
                    left: _chaseX,
                    top: _chaseY,
                    child: Material(
                      elevation: 10,
                      shadowColor: scheme.shadow.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.75),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.onPrimary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: _tapNow,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: _chaseTargetW,
                            height: _chaseTargetH,
                            alignment: Alignment.center,
                            child: Text(
                              'TAP!',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
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
  }

  List<Widget> _arenaCornerBrackets(ColorScheme scheme) {
    const len = 18.0;
    const t = 2.0;
    final c = scheme.primary.withValues(alpha: 0.85);
    Widget corner({
      required Alignment align,
      required bool top,
      required bool left,
    }) {
      return Align(
        alignment: align,
        child: SizedBox(
          width: len,
          height: len,
          child: CustomPaint(
            painter: _BracketPainter(color: c, stroke: t, top: top, left: left),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, top: true, left: true),
      corner(align: Alignment.topRight, top: true, left: false),
      corner(align: Alignment.bottomLeft, top: false, left: true),
      corner(align: Alignment.bottomRight, top: false, left: false),
    ];
  }

  Widget _infoCard(
    ThemeData theme,
    ColorScheme scheme,
    String text, {
    IconData? icon,
  }) {
    return Container(
      decoration: _playfieldShell(scheme),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: scheme.primary, size: 30),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(
        begin: 0.68,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

class _ArenaGridPainter extends CustomPainter {
  _ArenaGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.7;
    const gap = 26.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _BracketPainter extends CustomPainter {
  _BracketPainter({
    required this.color,
    required this.stroke,
    required this.top,
    required this.left,
  });

  final Color color;
  final double stroke;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final w = size.width;
    final h = size.height;
    if (top && left) {
      canvas.drawLine(Offset.zero, Offset(w * 0.72, 0), p);
      canvas.drawLine(Offset.zero, Offset(0, h * 0.72), p);
    } else if (top && !left) {
      canvas.drawLine(Offset(w, 0), Offset(w * 0.28, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h * 0.72), p);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, h), Offset(w * 0.72, h), p);
      canvas.drawLine(Offset(0, h), Offset(0, h * 0.28), p);
    } else {
      canvas.drawLine(Offset(w, h), Offset(w * 0.28, h), p);
      canvas.drawLine(Offset(w, h), Offset(w, h * 0.28), p);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke ||
      oldDelegate.top != top ||
      oldDelegate.left != left;
}

class _RoundResult {
  const _RoundResult({
    required this.round,
    required this.winnerPlayerIndex,
    required this.winnerMs,
  });

  final int round;
  final int winnerPlayerIndex;
  final int winnerMs;
}

// Legacy implementation kept temporarily for reference.
// ignore: unused_element
class _PartyReactionRelayGameState extends State<PartyReactionRelayGame> {
  final _rng = Random();
  int _players = 2;
  static const int _rounds = 5;
  static const int _legacyMatchTimeLimitSeconds = 120;
  bool _running = false;
  bool _matchFinished = false;
  bool _armed = false;
  bool _showTapNow = false;
  int _turn = 0;
  int _currentRound = 1;
  DateTime? _startAt;
  Timer? _armTimer;
  Timer? _leaderboardTimer;
  Timer? _presenceTimer;
  final Map<int, int> _reactionMs = {};
  final Map<int, int> _wins = {};
  final List<_RoundResult> _winnerQueue = [];
  List<PartyRoomScoreRow> _leaderboard = const [];
  PartyRoomPresence? _presence;
  bool _sending = false;
  int? _bestReactionAllRoundsMs;
  bool get _online => (widget.roomId?.trim().isNotEmpty ?? false);
  int get _targetTurns => _online ? 1 : _players;
  String _playerLabel(int i) =>
      _online ? context.l10n.you : context.l10n.playerNumber(i + 1);
  bool get _isBetweenRounds =>
      !_running && !_matchFinished && _winnerQueue.isNotEmpty;
  bool get _isSetup => !_running && !_matchFinished && _winnerQueue.isEmpty;

  @override
  void dispose() {
    _armTimer?.cancel();
    _leaderboardTimer?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _resetMatch();
    _startPresencePolling();
    _startLeaderboardPolling();
  }

  void _startPresencePolling() {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    _pullPresence();
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pullPresence(),
    );
  }

  Future<void> _pullPresence() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    try {
      final p = await PartyRoomService.fetchRoomPresence(rid);
      if (!mounted) return;
      final count = p.joinedCount.clamp(2, 5);
      setState(() {
        _presence = p;
        if (!_running && !_matchFinished && _players != count) {
          _players = count;
        }
      });
    } catch (_) {
      // Keep local state if presence fetch fails temporarily.
    }
  }

  void _startLeaderboardPolling() {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    _pullLeaderboard();
    _leaderboardTimer?.cancel();
    _leaderboardTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pullLeaderboard(),
    );
  }

  Future<void> _pullLeaderboard() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    final rows = await PartyRoomService.fetchLeaderboard(rid);
    if (!mounted) return;
    setState(() => _leaderboard = rows);
  }

  void _resetMatch() {
    _armTimer?.cancel();
    _reactionMs.clear();
    _winnerQueue.clear();
    _wins
      ..clear()
      ..addEntries(List.generate(_targetTurns, (i) => MapEntry(i, 0)));
    setState(() {
      _running = false;
      _matchFinished = false;
      _armed = false;
      _showTapNow = false;
      _turn = 0;
      _currentRound = 1;
      _startAt = null;
      _bestReactionAllRoundsMs = null;
    });
  }

  void _startRound() {
    if (_matchFinished) return;
    _armTimer?.cancel();
    setState(() {
      _running = true;
      _armed = false;
      _showTapNow = false;
      _turn = 0;
      _startAt = null;
      _reactionMs.clear();
    });
  }

  void _armCurrentPlayer() {
    _armTimer?.cancel();
    setState(() {
      _armed = true;
      _showTapNow = false;
      _startAt = null;
    });
    final delayMs = 1200 + _rng.nextInt(2200);
    _armTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !_running) return;
      setState(() {
        _showTapNow = true;
        _startAt = DateTime.now();
      });
    });
  }

  void _onTapNow() {
    if (!_showTapNow || _startAt == null) return;
    final delta = DateTime.now().difference(_startAt!).inMilliseconds;
    _reactionMs[_turn] = delta;
    if (_bestReactionAllRoundsMs == null || delta < _bestReactionAllRoundsMs!) {
      _bestReactionAllRoundsMs = delta;
    }

    if (_turn >= _targetTurns - 1) {
      _finishRound();
      return;
    }

    setState(() {
      _turn += 1;
      _armed = false;
      _showTapNow = false;
      _startAt = null;
    });
  }

  void _finishRound() {
    final winner = _winnerIndex;
    if (winner != null) {
      final winnerMs = _reactionMs[winner] ?? 0;
      _wins[winner] = (_wins[winner] ?? 0) + 1;
      _winnerQueue.add(
        _RoundResult(
          round: _currentRound,
          winnerPlayerIndex: winner,
          winnerMs: winnerMs,
        ),
      );
    }

    final done = _currentRound >= _rounds;
    setState(() {
      _running = false;
      _armed = false;
      _showTapNow = false;
      _startAt = null;
      if (done) {
        _matchFinished = true;
      } else {
        _currentRound += 1;
      }
    });
    if (done) _submitIfOnline();
  }

  int? get _winnerIndex {
    if (_reactionMs.length != _targetTurns) return null;
    var bestI = 0;
    var best = 1 << 30;
    for (final e in _reactionMs.entries) {
      if (e.value < best) {
        best = e.value;
        bestI = e.key;
      }
    }
    return bestI;
  }

  int? get _matchChampionIndex {
    if (_winnerQueue.isEmpty) return null;
    var champion = 0;
    var maxWins = -1;
    for (final e in _wins.entries) {
      if (e.value > maxWins) {
        maxWins = e.value;
        champion = e.key;
      }
    }
    return champion;
  }

  List<MapEntry<int, int>> get _sortedStandings {
    final turns = _targetTurns;
    final out = <MapEntry<int, int>>[
      for (var i = 0; i < turns; i++) MapEntry(i, _wins[i] ?? 0),
    ];
    out.sort((a, b) {
      final byWins = b.value.compareTo(a.value);
      if (byWins != 0) return byWins;
      final aMs = _reactionMs[a.key] ?? (1 << 30);
      final bMs = _reactionMs[b.key] ?? (1 << 30);
      return aMs.compareTo(bMs);
    });
    return out;
  }

  Future<void> _submitIfOnline() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    if (!_matchFinished) return;
    final best = _bestReactionAllRoundsMs;
    if (best == null) return;
    setState(() => _sending = true);
    try {
      // Lower ms is better; store inverted score so leaderboards sort desc.
      final score = (10000 - best).clamp(1, 10000);
      await PartyRoomService.submitScore(
        roomId: rid,
        score: score,
        meta: {'best_ms': best, 'game': 'reaction_relay'},
      );
      await _pullLeaderboard();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final winner = _winnerIndex;
    final champion = _matchChampionIndex;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.onlineGameReactionRelay,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.reactionRelayOfflineSubtitle(_legacyMatchTimeLimitSeconds),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if ((widget.roomId?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 6),
          Text(
            l10n.reactionRelayOnlineSubtitle(_legacyMatchTimeLimitSeconds),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!_online)
                      _selectorChip(
                        context: context,
                        label: 'Players',
                        child: DropdownButton<int>(
                          value: _players,
                          isDense: true,
                          items: const [2, 3, 4, 5]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                          onChanged: _running
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  _players = v;
                                  _resetMatch();
                                },
                        ),
                      )
                    else
                      _statusPill(
                        context: context,
                        text: _presence == null
                            ? l10n.playersCount(_players)
                            : l10n.joinedOutOf(
                                _presence!.joinedCount,
                                _presence!.maxPlayers,
                              ),
                      ),
                    _statusPill(
                      context: context,
                      text: l10n.roundsLabel(_rounds),
                    ),
                    _statusPill(
                      context: context,
                      text: l10n.roundShortProgress(_currentRound, _rounds),
                    ),
                    _statusPill(
                      context: context,
                      text: _matchFinished
                          ? l10n.finished
                          : (_running
                                ? l10n.inProgress
                                : (_isBetweenRounds
                                      ? l10n.betweenRounds
                                      : l10n.ready)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetMatch,
                        child: Text(l10n.resetMatch),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _matchFinished ? null : _startRound,
                        child: Text(
                          _running ? l10n.restartRound : l10n.startRound,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_isSetup)
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.reactionRelayStartRoundHint,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        if (_running && !_armed && !_showTapNow)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _playerLabel(_turn),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _online
                        ? l10n.reactionRelayYouPlayThisRound
                        : l10n.reactionRelayPassPhoneTo(_playerLabel(_turn)),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _armCurrentPlayer,
                    child: Text(l10n.arm),
                  ),
                ],
              ),
            ),
          ),
        if (_running && _armed && !_showTapNow)
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(child: Text(l10n.waitForGo)),
            ),
          ),
        if (_running && _showTapNow)
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(96),
              backgroundColor: scheme.primary,
            ),
            onPressed: _onTapNow,
            child: Text(l10n.goTap),
          ),
        if (_isBetweenRounds) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.roundWinnerMs(
                      _winnerQueue.last.round,
                      _playerLabel(_winnerQueue.last.winnerPlayerIndex),
                      _winnerQueue.last.winnerMs,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _startRound,
                    child: Text(l10n.nextRound),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_matchFinished) ...[
          const SizedBox(height: 10),
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _online
                        ? l10n.yourRunFinished
                        : (champion == null
                              ? l10n.noChampionYet
                              : l10n.championLabel(_playerLabel(champion))),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (_bestReactionAllRoundsMs != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.bestReactionMs(_bestReactionAllRoundsMs!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if ((widget.roomId?.trim().isNotEmpty ?? false)) ...[
          FilledButton.tonal(
            onPressed: (_sending || !_matchFinished) ? null : _submitIfOnline,
            child: Text(_sending ? l10n.submitting : l10n.submitScore),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.roomLeaderboard,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (_leaderboard.isEmpty)
            Text(
              l10n.noScoresYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (var i = 0; i < _leaderboard.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('#${i + 1}'),
                title: Text(_leaderboard[i].username),
                trailing: Text('${_leaderboard[i].score}'),
              ),
          const SizedBox(height: 8),
        ],
        Text(
          l10n.winnersQueue,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        if (_winnerQueue.isEmpty)
          Text(
            l10n.noRoundsFinishedYet,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final r in _winnerQueue)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text('R${r.round}'),
              title: Text(_playerLabel(r.winnerPlayerIndex)),
              trailing: Text('${r.winnerMs} ms'),
            ),
        const SizedBox(height: 8),
        Text(
          _online
              ? l10n.finalWinnersRanking
              : (_matchFinished
                    ? l10n.finalWinnersRanking
                    : l10n.currentStandings),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        if (_online)
          if (_leaderboard.isEmpty)
            Text(
              l10n.noFinalRankingYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (var i = 0; i < _leaderboard.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('#${i + 1}')),
                title: Text(_leaderboard[i].username),
                trailing: Text('${_leaderboard[i].score}'),
              )
        else
          for (var rank = 0; rank < _sortedStandings.length; rank++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('#${rank + 1}')),
              title: Text(_playerLabel(_sortedStandings[rank].key)),
              trailing: Text(
                '${_sortedStandings[rank].value} ${l10n.wins}'
                '${_reactionMs[_sortedStandings[rank].key] == null ? '' : ' · ${_reactionMs[_sortedStandings[rank].key]} ms'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight:
                      champion == _sortedStandings[rank].key ||
                          winner == _sortedStandings[rank].key
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color:
                      champion == _sortedStandings[rank].key ||
                          winner == _sortedStandings[rank].key
                      ? scheme.primary
                      : null,
                ),
              ),
            ),
      ],
    );
  }

  Widget _selectorChip({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const SizedBox(width: 8), child],
      ),
    );
  }

  Widget _statusPill({required BuildContext context, required String text}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
