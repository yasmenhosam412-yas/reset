import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_card_catalog.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_match_outcome_fx.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_result_feed_share.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_duel_online_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Matchday fantasy card duel**: six squad cards, start **three** in order on
/// the pitch. Each zone **calls a suit** (Blitz / Maestro / Iron) — matching your
/// card’s suit adds a bonus on top of shirt number. Most zones wins, then total
/// **effective** strength breaks ties.
class FantasyDuelGame extends StatefulWidget {
  const FantasyDuelGame({
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
  final FantasyDuelOnlineConfig? online;
  final VoidCallback? onPlayAgain;

  static const List<String> zoneLabels = [
    'left_wing',
    'no_10',
    'wide_back',
  ];

  /// First side to reach this many **round** wins takes the match (offline + online).
  static const int kRoundWinsNeeded = 5;

  /// Seconds to lock your starters each round while picking.
  static const int secondsPerPickRound = 45;

  @override
  State<FantasyDuelGame> createState() => _FantasyDuelGameState();
}

enum _DuelPhase { picking, waitingOnline, reveal, roundComplete, matchComplete }

class _FantasyDuelGameState extends State<FantasyDuelGame> {
  final _rng = math.Random();

  _DuelPhase _phase = _DuelPhase.picking;
  List<FantasyCardDef> _myHand = [];
  List<FantasyCardDef> _oppHand = [];
  final List<int> _pickOrder = [];

  List<int>? _myTrio;
  List<int>? _oppTrio;
  /// Preserved for the reveal board after the server clears trios (online match end).
  List<int>? _revealSnapMy;
  List<int>? _revealSnapOpp;
  String? _outcomeLine;
  String? _duelSummaryLine;

  /// Offline: first to [kRoundWinsNeeded] **round** wins takes the duel.
  int _myMatchWins = 0;
  int _oppMatchWins = 0;
  int _roundIndex = 1;

  /// Per-lane suit demand this fixture (same for both sides — from deck seed).
  List<FantasyCardSuit> _zoneSuits = FantasyCardDef.zoneCallsForLanes(1);

  Timer? _poll;
  Timer? _pickPhaseTimer;
  int _pickSecondsLeft = 0;
  String? _pickTimerKey;
  bool _asFrom = true;
  int _deckSeed = 1;
  String? _error;

  bool get _online => widget.online != null;
  OnlineRepository get _repo => widget.online!.repository;
  String get _cid => widget.online!.challengeId;

  static const int _starters = 3;
  static const int _squadSize = 6;

  @override
  void initState() {
    super.initState();
    if (_online) {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      _asFrom = uid == widget.online!.fromUserId;
      unawaited(_bootstrapOnline());
      _poll = Timer.periodic(const Duration(milliseconds: 480), (_) {
        unawaited(_pollOnline());
      });
    } else {
      _deckSeed = _rng.nextInt(1 << 29) + 1;
      _dealOffline();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensurePickPhaseTimer();
    });
  }

  void _dealOffline({bool notify = true}) {
    _zoneSuits = FantasyCardDef.zoneCallsForLanes(_deckSeed);
    _myHand = FantasyCardDef.dealHand(_deckSeed, 1);
    _oppHand = FantasyCardDef.dealHand(_deckSeed, 2);
    if (notify) setState(() {});
  }

  int _zoneSuitBonus(int lane, FantasyCardDef c) {
    if (lane < 0 || lane >= _zoneSuits.length) return 0;
    return c.suit == _zoneSuits[lane] ? FantasyCardDef.kZoneSuitBonus : 0;
  }

  int _effectiveLanePower(int lane, FantasyCardDef c) {
    return c.power + _zoneSuitBonus(lane, c);
  }

  Future<void> _bootstrapOnline() async {
    await _repo.ensureFantasyDuelSession(challengeId: _cid);
    final r = await _repo.fetchFantasyDuelSession(challengeId: _cid);
    r.fold((_) {}, (m) {
      if (!mounted || m == null) return;
      final both = m.bothSubmitted;
      setState(() {
        _applyMatchScoresFromModel(m);
        _roundIndex = m.roundNumber;
        _deckSeed = m.deckSeed;
        _zoneSuits = FantasyCardDef.zoneCallsForLanes(m.deckSeed);
        _myHand = FantasyCardDef.dealHand(m.deckSeed, _asFrom ? 1 : 2);
        _oppHand = FantasyCardDef.dealHand(m.deckSeed, _asFrom ? 2 : 1);
        _applyRemoteTrios(m);
        if (m.matchComplete) {
          _phase = _DuelPhase.matchComplete;
          _duelSummaryLine = _onlineDuelSummaryLine(m);
          _revealSnapMy = null;
          _revealSnapOpp = null;
        } else {
          _applyRemoteTrios(m);
          if (!both) {
            _phase = _DuelPhase.picking;
            _pickOrder.clear();
            _myTrio = null;
            _oppTrio = null;
            _outcomeLine = null;
            _revealSnapMy = null;
            _revealSnapOpp = null;
            _duelSummaryLine = null;
          }
        }
      });
      if (both && mounted && !m.matchComplete) {
        _resolveMatch();
      }
      if (mounted) _ensurePickPhaseTimer();
    });
  }

  void _cancelPickPhaseTimer() {
    _pickPhaseTimer?.cancel();
    _pickPhaseTimer = null;
  }

  void _ensurePickPhaseTimer() {
    if (!mounted) return;
    if (_phase != _DuelPhase.picking) {
      _cancelPickPhaseTimer();
      _pickTimerKey = null;
      return;
    }
    final key = '${_roundIndex}_${_deckSeed}_${_online ? _cid : 'local'}';
    if (_pickPhaseTimer != null && key == _pickTimerKey) return;
    _pickTimerKey = key;
    _cancelPickPhaseTimer();
    setState(() {
      _pickSecondsLeft = FantasyDuelGame.secondsPerPickRound;
    });
    _pickPhaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _DuelPhase.picking) {
        _cancelPickPhaseTimer();
        return;
      }
      var expired = false;
      setState(() {
        _pickSecondsLeft--;
        if (_pickSecondsLeft <= 0) {
          expired = true;
        }
      });
      if (expired) {
        _cancelPickPhaseTimer();
        unawaited(_onPickTimeout());
      }
    });
  }

  Future<void> _onPickTimeout() async {
    if (!mounted || _phase != _DuelPhase.picking) return;
    _pickTimerKey = null;
    for (final c in _myHand) {
      if (_pickOrder.length >= _starters) break;
      if (!_pickOrder.contains(c.id)) {
        _pickOrder.add(c.id);
      }
    }
    setState(() {});
    await _confirmPicks();
  }

  void _applyMatchScoresFromModel(FantasyDuelSessionModel m) {
    _myMatchWins = _asFrom ? m.fromMatchWins : m.toMatchWins;
    _oppMatchWins = _asFrom ? m.toMatchWins : m.fromMatchWins;
  }

  String _onlineDuelSummaryLine(FantasyDuelSessionModel m) {
    final l10n = context.l10n;
    final mine = _asFrom ? m.fromMatchWins : m.toMatchWins;
    final opp = _asFrom ? m.toMatchWins : m.fromMatchWins;
    if (mine >= FantasyDuelGame.kRoundWinsNeeded) {
      return l10n.youWinDuelScore(mine, opp);
    }
    return l10n.opponentWinsDuelScore(widget.opponentName, opp, mine);
  }

  void _applyRemoteTrios(FantasyDuelSessionModel m) {
    if (!_online) return;
    final mine = _asFrom ? m.fromTrio : m.toTrio;
    final theirs = _asFrom ? m.toTrio : m.fromTrio;
    if (mine != null && mine.length == _starters) {
      _myTrio = mine;
      _pickOrder
        ..clear()
        ..addAll(mine);
    } else {
      _myTrio = null;
    }
    if (theirs != null && theirs.length == _starters) {
      _oppTrio = theirs;
    } else {
      _oppTrio = null;
    }
  }

  Future<void> _pollOnline() async {
    if (!_online || !mounted || _phase == _DuelPhase.matchComplete) return;
    if (_phase == _DuelPhase.reveal) return;
    final r = await _repo.fetchFantasyDuelSession(challengeId: _cid);
    r.fold((_) {}, (m) {
      if (!mounted || m == null) return;
      final resolveNow = m.bothSubmitted &&
          !m.matchComplete &&
          _phase != _DuelPhase.reveal &&
          _phase != _DuelPhase.matchComplete;
      setState(() {
        _applyMatchScoresFromModel(m);
        if (m.matchComplete) {
          _phase = _DuelPhase.matchComplete;
          _duelSummaryLine = _onlineDuelSummaryLine(m);
        }
        _applyRemoteTrios(m);
      });
      if (resolveNow && mounted) {
        _resolveMatch();
      }
      if (mounted) _ensurePickPhaseTimer();
    });
  }

  void _togglePick(FantasyCardDef c) {
    if (_phase != _DuelPhase.picking) return;
    if (_pickOrder.contains(c.id)) {
      setState(() => _pickOrder.remove(c.id));
    } else if (_pickOrder.length < _starters) {
      setState(() => _pickOrder.add(c.id));
    }
  }

  void _clearPicks() {
    if (_phase != _DuelPhase.picking) return;
    setState(() => _pickOrder.clear());
  }

  Future<void> _confirmPicks() async {
    if (_pickOrder.length != _starters) return;
    final ids = List<int>.from(_pickOrder);
    if (!_validTrio(ids)) {
      setState(() => _error = context.l10n.pickOnlyFromSquadSheet);
      return;
    }
    _cancelPickPhaseTimer();
    _pickTimerKey = null;
    setState(() => _error = null);

    if (!_online) {
      _myTrio = ids;
      _oppTrio = _aiBestLineup(_oppHand, ids);
      _resolveMatch();
      return;
    }

    final res = await _repo.submitFantasyDuelTrio(
      challengeId: _cid,
      asFrom: _asFrom,
      trio: ids,
    );
    res.fold(
      (_) {
        if (!mounted) return;
        setState(() => _error = context.l10n.couldNotSubmitPicks);
        _ensurePickPhaseTimer();
      },
      (ok) {
        if (!ok) {
          if (!mounted) return;
          setState(() => _error = context.l10n.alreadySubmittedOrSyncIssue);
          _ensurePickPhaseTimer();
          return;
        }
        setState(() {
          _myTrio = ids;
          _phase = _DuelPhase.waitingOnline;
        });
      },
    );
  }

  bool _validTrio(List<int> ids) {
    final handIds = _myHand.map((e) => e.id).toSet();
    return ids.length == _starters && ids.every(handIds.contains);
  }

  /// Exhaustive search over all 6·5·4 ordered starters — maximizes zones won
  /// using **effective** power (suit + shirt), then total.
  List<int> _aiBestLineup(List<FantasyCardDef> aiHand, List<int> playerTrioIds) {
    final pcs = playerTrioIds.map((id) => FantasyCardDef.byId(id)!).toList();
    var best = <int>[aiHand[0].id, aiHand[1].id, aiHand[2].id];
    var bestZones = -1;
    var bestSum = -1;

    void consider(List<int> orderedIds) {
      var z = 0;
      var sum = 0;
      for (var lane = 0; lane < _starters; lane++) {
        final ac = FantasyCardDef.byId(orderedIds[lane])!;
        final pc = pcs[lane];
        final ae = _effectiveLanePower(lane, ac);
        final pe = _effectiveLanePower(lane, pc);
        sum += ae;
        if (ae > pe) {
          z++;
        }
      }
      if (z > bestZones || (z == bestZones && sum > bestSum)) {
        bestZones = z;
        bestSum = sum;
        best = List<int>.from(orderedIds);
      }
    }

    final n = aiHand.length;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (j == i) continue;
        for (var k = 0; k < n; k++) {
          if (k == i || k == j) continue;
          consider([aiHand[i].id, aiHand[j].id, aiHand[k].id]);
        }
      }
    }
    return best;
  }

  /// Returns `(line, winner)` with winner −1 = you, 0 = drawn round, 1 = opponent.
  ({String line, int winner}) _roundOutcomeFromTrios(List<int> a, List<int> b) {
    var fl = 0;
    var tl = 0;
    var ms = 0;
    var os = 0;
    for (var i = 0; i < _starters; i++) {
      final mc = FantasyCardDef.byId(a[i])!;
      final oc = FantasyCardDef.byId(b[i])!;
      final fp = _effectiveLanePower(i, mc);
      final tp = _effectiveLanePower(i, oc);
      ms += fp;
      os += tp;
      if (fp > tp) {
        fl++;
      } else if (tp > fp) {
        tl++;
      }
    }
    if (fl > tl) {
      return (
        line: context.l10n.youTakeRoundZones(fl, tl),
        winner: -1,
      );
    }
    if (tl > fl) {
      return (
        line: context.l10n.opponentTakesRoundZones(widget.opponentName, tl, fl),
        winner: 1,
      );
    }
    if (ms > os) {
      return (
        line: context.l10n.zonesDrawnYouEdgeStrength(ms, os),
        winner: -1,
      );
    }
    if (os > ms) {
      return (
        line: context.l10n.zonesDrawnOpponentEdges(widget.opponentName, os, ms),
        winner: 1,
      );
    }
    return (line: context.l10n.honorsEvenDrawnRoundNoPoint, winner: 0);
  }

  void _resolveMatch() {
    if (_phase == _DuelPhase.reveal ||
        _phase == _DuelPhase.roundComplete ||
        _phase == _DuelPhase.matchComplete) {
      return;
    }
    if (_myTrio == null || _oppTrio == null) return;
    final a = _myTrio!;
    final b = _oppTrio!;
    final outcome = _roundOutcomeFromTrios(a, b);

    _revealSnapMy = List<int>.from(a);
    _revealSnapOpp = List<int>.from(b);

    setState(() {
      _outcomeLine = outcome.line;
      _duelSummaryLine = null;
      _phase = _DuelPhase.reveal;
    });
    unawaited(_afterRevealDelay(outcome));
  }

  Future<void> _afterRevealDelay(({String line, int winner}) outcome) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    if (_online) {
      var fromPt = 0;
      var toPt = 0;
      final w = outcome.winner;
      if (w < 0) {
        if (_asFrom) {
          fromPt = 1;
        } else {
          toPt = 1;
        }
      } else if (w > 0) {
        if (_asFrom) {
          toPt = 1;
        } else {
          fromPt = 1;
        }
      }
      final adv = await _repo.finishFantasyDuelRoundAndAdvance(
        challengeId: _cid,
        completedRound: _roundIndex,
        fromRoundPoints: fromPt,
        toRoundPoints: toPt,
      );
      if (!mounted) return;
      var advanceOk = true;
      adv.fold((_) => advanceOk = false, (_) {});
      if (!advanceOk) {
        setState(() {
          _error = context.l10n.couldNotSyncRoundTryAgain;
        });
        return;
      }
      final r = await _repo.fetchFantasyDuelSession(challengeId: _cid);
      r.fold((_) {}, (m) {
        if (!mounted || m == null) return;
        setState(() {
          _applyMatchScoresFromModel(m);
          _myTrio = null;
          _oppTrio = null;
          _pickOrder.clear();
          _outcomeLine = outcome.line;
          if (m.matchComplete) {
            _phase = _DuelPhase.matchComplete;
            _duelSummaryLine = _onlineDuelSummaryLine(m);
          } else {
            _revealSnapMy = null;
            _revealSnapOpp = null;
            _roundIndex = m.roundNumber;
            _deckSeed = m.deckSeed;
            _zoneSuits = FantasyCardDef.zoneCallsForLanes(m.deckSeed);
            _myHand = FantasyCardDef.dealHand(m.deckSeed, _asFrom ? 1 : 2);
            _oppHand = FantasyCardDef.dealHand(m.deckSeed, _asFrom ? 2 : 1);
            _phase = _DuelPhase.picking;
            _duelSummaryLine = null;
          }
        });
        if (mounted) _ensurePickPhaseTimer();
      });
      return;
    }
    setState(() {
      final w = outcome.winner;
      if (w < 0) {
        _myMatchWins++;
      } else if (w > 0) {
        _oppMatchWins++;
      }
      if (_myMatchWins >= FantasyDuelGame.kRoundWinsNeeded ||
          _oppMatchWins >= FantasyDuelGame.kRoundWinsNeeded) {
        _phase = _DuelPhase.matchComplete;
        _revealSnapMy = null;
        _revealSnapOpp = null;
        _duelSummaryLine = _myMatchWins >= FantasyDuelGame.kRoundWinsNeeded
            ? context.l10n.youWinDuelScore(_myMatchWins, _oppMatchWins)
            : context.l10n.opponentWinsDuelScore(
                widget.opponentName,
                _oppMatchWins,
                _myMatchWins,
              );
      } else {
        _phase = _DuelPhase.roundComplete;
      }
    });
  }

  void _startNextRound() {
    if (_phase != _DuelPhase.roundComplete) return;
    setState(() {
      _phase = _DuelPhase.picking;
      _pickOrder.clear();
      _myTrio = null;
      _oppTrio = null;
      _revealSnapMy = null;
      _revealSnapOpp = null;
      _outcomeLine = null;
      _error = null;
      _roundIndex++;
      _deckSeed = _rng.nextInt(1 << 29) + 1;
      _dealOffline(notify: false);
    });
    _ensurePickPhaseTimer();
  }

  void _restartOffline() {
    setState(() {
      _deckSeed = _rng.nextInt(1 << 29) + 1;
      _phase = _DuelPhase.picking;
      _pickOrder.clear();
      _myTrio = null;
      _oppTrio = null;
      _revealSnapMy = null;
      _revealSnapOpp = null;
      _outcomeLine = null;
      _duelSummaryLine = null;
      _error = null;
      _myMatchWins = 0;
      _oppMatchWins = 0;
      _roundIndex = 1;
      _dealOffline(notify: false);
    });
    _ensurePickPhaseTimer();
  }

  Future<void> _onDuelPlayAgainPressed() async {
    if (_online) {
      final res = await _repo.resetFantasyDuelMatch(challengeId: _cid);
      if (!mounted) return;
      res.fold(
        (_) {
          setState(() {
            _error = context.l10n.couldNotStartRematch;
          });
        },
        (_) {
          if (widget.onPlayAgain != null) {
            widget.onPlayAgain!();
          } else {
            unawaited(_bootstrapAfterFantasyResetOnline());
          }
        },
      );
      return;
    }
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
    } else {
      _restartOffline();
    }
  }

  Future<void> _bootstrapAfterFantasyResetOnline() async {
    await _bootstrapOnline();
    if (!mounted) return;
    setState(() => _error = null);
    _ensurePickPhaseTimer();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cancelPickPhaseTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = widget.scheme;
    final theme = widget.theme;

    final matchOutcome = _phase == _DuelPhase.matchComplete
        ? gameMatchOutcomeFromScores(
            myScore: _myMatchWins,
            oppScore: _oppMatchWins,
          )
        : null;

    var duelSummaryIcon = Icons.military_tech_rounded;
    var duelSummaryBg = scheme.tertiaryContainer.withValues(alpha: 0.65);
    var duelSummaryFg = scheme.onTertiaryContainer;
    if (_phase == _DuelPhase.matchComplete && matchOutcome != null) {
      switch (matchOutcome) {
        case GameMatchOutcome.win:
          duelSummaryIcon = Icons.emoji_events_rounded;
          duelSummaryBg = scheme.primaryContainer.withValues(alpha: 0.72);
          duelSummaryFg = scheme.onPrimaryContainer;
        case GameMatchOutcome.loss:
          duelSummaryIcon = Icons.auto_fix_high_rounded;
          duelSummaryBg = scheme.surfaceContainerHigh.withValues(alpha: 0.92);
          duelSummaryFg = scheme.onSurface;
        case GameMatchOutcome.draw:
          duelSummaryIcon = Icons.handshake_rounded;
          duelSummaryBg = scheme.tertiaryContainer.withValues(alpha: 0.62);
          duelSummaryFg = scheme.onTertiaryContainer;
      }
    }

    return GameMatchOutcomeLayer(
      outcome: matchOutcome,
      scheme: scheme,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _matchdayHeader(theme, scheme),
        const SizedBox(height: 12),
        _offlineDuelStrip(theme, scheme),
        const SizedBox(height: 12),
        _howToPlayCard(theme, scheme),
        const SizedBox(height: 16),
        if (_error != null)
          Material(
            color: scheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_error != null) const SizedBox(height: 12),
        if (_phase == _DuelPhase.picking ||
            _phase == _DuelPhase.waitingOnline ||
            (!_online &&
                _phase != _DuelPhase.roundComplete &&
                _phase != _DuelPhase.matchComplete)) ...[
          _sectionTitle(
            theme,
            scheme,
            l10n.yourSquad,
            l10n.fantasyYourSquadSubtitle(_squadSize, _starters),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 216,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              itemCount: _myHand.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _playerCard(_myHand[i], theme, scheme),
            ),
          ),
          const SizedBox(height: 18),
          _pitchStrip(theme, scheme),
        ] else ...[
          _sectionTitle(
            theme,
            scheme,
            l10n.lastRound,
            l10n.cardsLockedSeeResultBelow,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.startersCount(_pickOrder.length, _starters),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            if (_phase == _DuelPhase.picking || _phase == _DuelPhase.waitingOnline) ...[
              const SizedBox(height: 10),
              _starterSlotStrip(theme, scheme),
            ],
            if (_phase == _DuelPhase.picking) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearPicks,
                      icon: const Icon(Icons.clear_all_rounded, size: 20),
                      label: Text(l10n.clear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _pickOrder.length == _starters ? _confirmPicks : null,
                      icon: Icon(
                        _online ? Icons.lock_rounded : Icons.sports_soccer_rounded,
                        size: 20,
                      ),
                      label: Text(_online ? l10n.lockLineup : l10n.teamBattleKickOff),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (_phase == _DuelPhase.waitingOnline)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.lineupLocked,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.waitingForOpponentToSubmit(widget.opponentName),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_phase == _DuelPhase.reveal ||
            _phase == _DuelPhase.roundComplete ||
            _phase == _DuelPhase.matchComplete) ...[
          const SizedBox(height: 16),
          _revealBoard(theme, scheme),
          const SizedBox(height: 16),
          _resultBanner(
            theme,
            scheme,
            icon: Icons.emoji_events_rounded,
            text: _outcomeLine ?? '',
            background: scheme.primaryContainer.withValues(alpha: 0.55),
            foreground: scheme.onPrimaryContainer,
            isLarge: false,
          ),
          if (_duelSummaryLine != null) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              key: ValueKey<String>(
                '${_phase.name}${_duelSummaryLine!}${matchOutcome?.name ?? ''}',
              ),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                return Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                );
              },
              child: _resultBanner(
                theme,
                scheme,
                icon: duelSummaryIcon,
                text: _duelSummaryLine!,
                background: duelSummaryBg,
                foreground: duelSummaryFg,
                isLarge: true,
              ),
            ),
          ],
        ],
        if (_phase == _DuelPhase.roundComplete && !_online) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _startNextRound,
            child: Text(
              l10n.nextRoundScoreTarget(
                _myMatchWins,
                _oppMatchWins,
                FantasyDuelGame.kRoundWinsNeeded,
              ),
            ),
          ),
        ],
        if (_phase == _DuelPhase.matchComplete) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => unawaited(_onDuelPlayAgainPressed()),
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.playAgain),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              showShareGameResultToFeedDialog(
                context,
                title: l10n.shareToHomeFeed,
                initialBody:
                    l10n.fantasyDuelShareBody(
                      widget.opponentName,
                      _myMatchWins,
                      _oppMatchWins,
                      FantasyDuelGame.kRoundWinsNeeded,
                      _duelSummaryLine ?? '',
                    ),
              ),
            ),
            icon: const Icon(Icons.feed_rounded),
            label: Text(l10n.shareResult),
          ),
        ],
      ],
    ),
    );
  }

  String _zoneLabel(BuildContext context, int i) {
    final l10n = context.l10n;
    return switch (FantasyDuelGame.zoneLabels[i]) {
      'left_wing' => l10n.fantasyZoneLeftWing,
      'no_10' => l10n.fantasyZoneNo10,
      'wide_back' => l10n.fantasyZoneWideBack,
      _ => FantasyDuelGame.zoneLabels[i],
    };
  }

  Widget _starterSlotStrip(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    return Row(
      children: List.generate(_starters, (i) {
        final filled = i < _pickOrder.length;
        final card = filled ? FantasyCardDef.byId(_pickOrder[i]) : null;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _starters - 1 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: filled
                    ? scheme.primaryContainer.withValues(alpha: 0.7)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: filled
                      ? scheme.primary.withValues(alpha: 0.5)
                      : scheme.outline.withValues(alpha: 0.18),
                  width: filled ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.slotNumber(i + 1),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.4,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (card != null) ...[
                    Text(card.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else
                    Icon(
                      Icons.touch_app_rounded,
                      size: 28,
                      color: scheme.outline.withValues(alpha: 0.55),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _resultBanner(
    ThemeData theme,
    ColorScheme scheme, {
    required IconData icon,
    required String text,
    required Color background,
    required Color foreground,
    required bool isLarge,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: isLarge ? 32 : 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.start,
                style: (isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: foreground,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchdayHeader(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.88),
            scheme.tertiary.withValues(alpha: 0.82),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: scheme.primary.withValues(alpha: 0.35),
          ),
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.stadium_rounded, color: scheme.onPrimary, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchday.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.92),
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.onlineGameFantasyCards,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  _headerAvatar(theme, scheme, l10n.you, isSelf: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      l10n.vsUpper,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _headerAvatar(theme, scheme, widget.opponentName, isSelf: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAvatar(ThemeData theme, ColorScheme scheme, String label, {required bool isSelf}) {
    final l10n = context.l10n;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.onPrimary.withValues(alpha: 0.22),
          child: Text(
            initial,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSelf ? l10n.you : l10n.opponent,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isSelf ? l10n.squadManager : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _offlineDuelStrip(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.secondaryContainer.withValues(alpha: 0.65),
            scheme.secondaryContainer.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: scheme.secondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.roundNumber(_roundIndex),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _online
                            ? l10n.firstToRoundWinsVsFriend(
                                FantasyDuelGame.kRoundWinsNeeded,
                              )
                            : l10n.firstToRoundWins(
                                FantasyDuelGame.kRoundWinsNeeded,
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _scorePill(
                    theme,
                    scheme,
                    l10n.you,
                    _myMatchWins,
                    filled: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Expanded(
                  child: _scorePill(theme, scheme, widget.opponentName, _oppMatchWins, filled: false),
                ),
              ],
            ),
            if (_phase == _DuelPhase.picking || _phase == _DuelPhase.waitingOnline) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    _phase == _DuelPhase.waitingOnline
                        ? Icons.hourglass_top_rounded
                        : Icons.timer_rounded,
                    size: 20,
                    color: _phase == _DuelPhase.waitingOnline
                        ? scheme.onSecondaryContainer.withValues(alpha: 0.65)
                        : (_pickSecondsLeft <= 8
                            ? scheme.error
                            : scheme.secondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _phase == _DuelPhase.waitingOnline
                        ? '—'
                        : l10n.secondsShort(_pickSecondsLeft),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _phase == _DuelPhase.waitingOnline
                          ? scheme.onSecondaryContainer.withValues(alpha: 0.65)
                          : (_pickSecondsLeft <= 8
                              ? scheme.error
                              : scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scorePill(
    ThemeData theme,
    ColorScheme scheme,
    String who,
    int score, {
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled
            ? scheme.secondary.withValues(alpha: 0.22)
            : scheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: filled ? 0.35 : 0.2),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              who,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer.withValues(alpha: 0.85),
              ),
            ),
            Text(
              '$score',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSecondaryContainer,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howToPlayCard(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.menu_book_rounded, color: scheme.primary, size: 26),
          title: Text(
            l10n.howDuelWorks,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            l10n.tapToExpandRules,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          children: [
            _ruleLine(
              theme,
              scheme,
              '1',
              l10n.fantasyRule1(_squadSize),
            ),
            _ruleLine(
              theme,
              scheme,
              '2',
              l10n.fantasyRule2(
                _starters,
                _zoneLabel(context, 0),
                _zoneLabel(context, 1),
                _zoneLabel(context, 2),
              ),
            ),
            _ruleLine(
              theme,
              scheme,
              '3',
              l10n.fantasyRule3(FantasyCardDef.kZoneSuitBonus),
            ),
            _ruleLine(
              theme,
              scheme,
              '4',
              l10n.fantasyRule4,
            ),
            if (!_online)
              _ruleLine(
                theme,
                scheme,
                '#',
                l10n.fantasyRuleOffline(FantasyDuelGame.kRoundWinsNeeded),
              ),
            if (_online)
              _ruleLine(
                theme,
                scheme,
                '#',
                l10n.fantasyRuleOnline(FantasyDuelGame.kRoundWinsNeeded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ruleLine(ThemeData theme, ColorScheme scheme, String badge, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary.withValues(alpha: 0.2),
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, ColorScheme scheme, String t, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          constraints: const BoxConstraints(minHeight: 36),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pitchStrip(ThemeData theme, ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 96,
        child: CustomPaint(
          painter: _MiniPitchPainter(line: scheme.onPrimary.withValues(alpha: 0.4)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: List.generate(_starters, (i) {
                final sel = _pickOrder.length > i;
                final call = _zoneSuits[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 6 : 0, right: i < _starters - 1 ? 6 : 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withValues(alpha: sel ? 0.14 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? scheme.onPrimary.withValues(alpha: 0.45)
                              : scheme.onPrimary.withValues(alpha: 0.12),
                          width: sel ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            FantasyDuelGame.zoneLabels[i],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: sel ? scheme.onPrimary : scheme.onPrimary.withValues(alpha: 0.65),
                              fontSize: 9,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _suitBadge(call, scheme, size: 22),
                          const SizedBox(height: 2),
                          Icon(
                            sel ? Icons.check_circle_rounded : Icons.trip_origin,
                            size: 15,
                            color: sel ? scheme.onPrimary : scheme.onPrimary.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Color _suitColor(FantasyCardSuit s, ColorScheme scheme) {
    return switch (s) {
      FantasyCardSuit.blitz => const Color(0xFFE65100),
      FantasyCardSuit.maestro => scheme.tertiary,
      FantasyCardSuit.iron => scheme.secondary,
    };
  }

  Widget _suitBadge(FantasyCardSuit s, ColorScheme scheme, {double size = 22}) {
    final col = _suitColor(s, scheme);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col, width: 1.4),
      ),
      child: Text(
        s.symbol,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          color: col,
        ),
      ),
    );
  }

  Widget _playerCard(FantasyCardDef c, ThemeData theme, ColorScheme scheme) {
    final i = _pickOrder.indexOf(c.id);
    final picked = i >= 0;
    final suitAccent = _suitColor(c.suit, scheme);
    return SizedBox(
      width: 132,
      child: Material(
        elevation: picked ? 6 : 2,
        shadowColor: picked ? suitAccent.withValues(alpha: 0.45) : Colors.black26,
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface,
        child: InkWell(
          onTap: (_phase == _DuelPhase.picking) ? () => _togglePick(c) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: picked ? scheme.primary : scheme.outline.withValues(alpha: 0.2),
                width: picked ? 2.2 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: picked
                    ? [
                        scheme.primaryContainer.withValues(alpha: 0.55),
                        scheme.surfaceContainerHigh.withValues(alpha: 0.35),
                      ]
                    : [
                        scheme.surfaceContainerHigh.withValues(alpha: 0.9),
                        scheme.surface.withValues(alpha: 0.98),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.35),
                              scheme.primary.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          '${c.power}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _suitBadge(c.suit, scheme, size: 26),
                      const Spacer(),
                      Text(c.emoji, style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.role} · ${c.suit.fullName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (picked) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ZONE ${i + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _zoneSuitBonus(i, c) > 0
                                ? context.l10n.fantasyPitchMatchBonus(
                                    FantasyCardDef.kZoneSuitBonus,
                                  )
                                : context.l10n.noSuitMatch,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _revealBoard(ThemeData theme, ColorScheme scheme) {
    final a = _revealSnapMy ?? _myTrio;
    final b = _revealSnapOpp ?? _oppTrio;
    if (a == null || b == null) {
      return const SizedBox.shrink();
    }
    final pitchTint = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.08),
      scheme.surfaceContainerLow.withValues(alpha: 0.85),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pitchTint,
            scheme.tertiary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_starters, (lane) {
          final mc = FantasyCardDef.byId(a[lane])!;
          final oc = FantasyCardDef.byId(b[lane])!;
          final pe = _effectiveLanePower(lane, mc);
          final tp = _effectiveLanePower(lane, oc);
          final mw = pe > tp;
          final ow = tp > pe;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(16),
                color: scheme.surface.withValues(alpha: 0.92),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _suitBadge(_zoneSuits[lane], scheme, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _zoneLabel(context, lane),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _shirtTile(
                        mc,
                        lane,
                        theme,
                        scheme,
                        mw ? scheme.primary : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.l10n.vsUpper,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      _shirtTile(
                        oc,
                        lane,
                        theme,
                        scheme,
                        ow ? scheme.secondary : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _shirtTile(
    FantasyCardDef c,
    int lane,
    ThemeData theme,
    ColorScheme scheme,
    Color? winBorder,
  ) {
    final base = c.power;
    final suitB = _zoneSuitBonus(lane, c);
    final total = base + suitB;

    final parts = <String>[];
    if (suitB > 0) {
      parts.add(
        context.l10n.fantasySuitBonusWithName(
          FantasyCardDef.kZoneSuitBonus,
          _zoneSuits[lane].fullName,
        ),
      );
    }
    final hasExtras = parts.isNotEmpty;
    final detail = hasExtras ? '$base ${parts.join(' ')} = $total' : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: winBorder != null
            ? winBorder.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winBorder ?? scheme.outline.withValues(alpha: 0.3),
          width: winBorder != null ? 2.2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _suitBadge(c.suit, scheme, size: 18),
              const SizedBox(width: 4),
              Text(c.emoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            c.name,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.2,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ],
          Text(
            '$total',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniPitchPainter extends CustomPainter {
  _MiniPitchPainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final g = const LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, Paint()..shader = g);
    final mid = Paint()
      ..color = line
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 4), Offset(size.width / 2, size.height - 4), mid);
    final circle = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 10, circle);
  }

  @override
  bool shouldRepaint(covariant _MiniPitchPainter oldDelegate) => oldDelegate.line != line;
}
