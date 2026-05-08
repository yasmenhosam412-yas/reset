import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rps_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_match_outcome_fx.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_result_feed_share.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rps_duel/rps_duel_online_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Rock–paper–scissors: simultaneous throws, first to [roundWinsToFinish] rounds.
/// Online uses `rps_sessions` (game ID 2).
class RpsDuelGame extends StatefulWidget {
  const RpsDuelGame({
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
  final RpsDuelOnlineConfig? online;
  final VoidCallback? onPlayAgain;

  static const int roundWinsToFinish = 5;

  static const List<String> picks = ['rock', 'paper', 'scissors'];

  static int roundOutcome(String a, String b) {
    if (a == b) return -1;
    if ((a == 'rock' && b == 'scissors') ||
        (a == 'paper' && b == 'rock') ||
        (a == 'scissors' && b == 'paper')) {
      return 0;
    }
    return 1;
  }

  /// Server clears both throws after a round; infer the opponent's pick from the outcome.
  static String? inferOpponentPick({
    required String myPick,
    required bool iAmFrom,
    required int roundWinner,
  }) {
    if (!picks.contains(myPick)) return null;
    for (final opp in picks) {
      final first = iAmFrom ? myPick : opp;
      final second = iAmFrom ? opp : myPick;
      final o = roundOutcome(first, second);
      if (o == -1) {
        if (roundWinner == -1) return opp;
        continue;
      }
      final fromWinsRound = o == 0;
      if (roundWinner == 0 && fromWinsRound) return opp;
      if (roundWinner == 1 && !fromWinsRound) return opp;
    }
    return null;
  }

  @override
  State<RpsDuelGame> createState() => _RpsDuelGameState();
}

class _RpsDuelGameState extends State<RpsDuelGame> with TickerProviderStateMixin {
  final _rng = math.Random();

  /// Last completed throws (for the “paper covers rock” clash vignette).
  String? _duelFromPick;
  String? _duelToPick;
  late final AnimationController _duelCtrl;
  Timer? _duelRevealClear;

  int _scoreFrom = 0;
  int _scoreTo = 0;
  String _status = 'playing';
  int _roundSeq = 0;
  /// `-1` until the first server row is applied (avoids a bogus "round won" on first poll).
  int _lastResolvedRoundSeq = -1;
  String? _banner;
  bool _busy = false;
  String? _pressingPick;

  late final AnimationController _pickIntroCtrl;

  Timer? _poll;
  Timer? _aiTimer;

  OnlineRepository get _repo => widget.online!.repository;
  String get _cid => widget.online!.challengeId;
  bool get _online => widget.online != null;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  bool get _asFrom {
    if (!_online) return true;
    final u = _uid;
    if (u == null) return true;
    return u == widget.online!.fromUserId;
  }

  bool get _canPickThisRound {
    if (_status == 'done' || _busy) return false;
    if (!_online) return true;
    final u = _uid;
    if (u == null) return false;
    if (u != widget.online!.fromUserId && u != widget.online!.toUserId) {
      return false;
    }
    if (_asFrom) {
      return _fromPick == null;
    }
    return _toPick == null;
  }

  String? _fromPick;
  String? _toPick;

  /// Your side's pick still held on the server this round (for "locked" UI).
  String? get _myCommittedPick {
    if (!_online) {
      return _fromPick;
    }
    final u = _uid;
    if (u == null) return null;
    if (u == widget.online!.fromUserId) return _fromPick;
    if (u == widget.online!.toUserId) return _toPick;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _duelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _pickIntroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pickIntroCtrl.forward();
    });
    if (_online) {
      unawaited(_bootstrapOnline());
      _poll = Timer.periodic(const Duration(milliseconds: 520), (_) {
        unawaited(_pollRemote());
      });
    }
  }

  Future<void> _bootstrapOnline() async {
    await _repo.ensureRpsSession(challengeId: _cid);
    final r = await _repo.fetchRpsSession(challengeId: _cid);
    await r.fold((_) async {}, (m) async {
      if (!mounted || m == null) return;
      setState(() {
        _applySession(m);
        _lastResolvedRoundSeq = m.roundSeq;
      });
    });
  }

  void _applySession(RpsSessionModel m) {
    _scoreFrom = m.scoreFrom;
    _scoreTo = m.scoreTo;
    _status = m.status;
    _roundSeq = m.roundSeq;
    _fromPick = m.fromPick;
    _toPick = m.toPick;
  }

  /// After a completed round both picks are cleared; use score deltas vs [prevFrom]/[prevTo].
  int? _roundWinnerFromScoreDelta(
    int prevFrom,
    int prevTo,
    int nextFrom,
    int nextTo,
  ) {
    if (nextFrom > prevFrom && nextTo == prevTo) return 0;
    if (nextTo > prevTo && nextFrom == prevFrom) return 1;
    return -1;
  }

  Future<void> _pollRemote() async {
    if (!_online || !mounted || _busy) return;
    final r = await _repo.fetchRpsSession(challengeId: _cid);
    await r.fold((_) async {}, (m) async {
      if (!mounted || m == null) return;
      final prevFrom = _scoreFrom;
      final prevTo = _scoreTo;
      final prevResolved = _lastResolvedRoundSeq;
      setState(() {
        _applySession(m);
        if (prevResolved < 0) {
          _lastResolvedRoundSeq = m.roundSeq;
          return;
        }
        if (m.roundSeq > prevResolved &&
            m.fromPick == null &&
            m.toPick == null &&
            (m.status == 'playing' || m.status == 'done')) {
          _lastResolvedRoundSeq = m.roundSeq;
          final rw = _roundWinnerFromScoreDelta(
            prevFrom,
            prevTo,
            m.scoreFrom,
            m.scoreTo,
          );
          final mySide = _asFrom ? _fromPick : _toPick;
          if (rw != null && mySide != null) {
            final opp = RpsDuelGame.inferOpponentPick(
              myPick: mySide,
              iAmFrom: _asFrom,
              roundWinner: rw,
            );
            if (opp != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _startDuelReveal(_asFrom ? mySide : opp, _asFrom ? opp : mySide);
              });
            }
          }
          if (m.status != 'done') {
            _banner = _roundMessage(rw, online: true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _kickPickRowIntro();
            });
          } else {
            _banner = null;
          }
          _hapticRoundResult(rw, online: true);
        }
      });
    });
  }

  void _hapticRoundResult(int? rw, {required bool online}) {
    if (rw == null) return;
    if (rw == -1) {
      HapticFeedback.selectionClick();
      return;
    }
    if (!online) {
      if (rw == 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      return;
    }
    final u = _uid;
    if (u == null) {
      HapticFeedback.selectionClick();
      return;
    }
    final iAmFrom = u == widget.online!.fromUserId;
    final youWon = (rw == 0) == iAmFrom;
    if (youWon) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _onPick(String pick) async {
    if (!_canPickThisRound) return;
    if (!RpsDuelGame.picks.contains(pick)) return;

    HapticFeedback.lightImpact();

    if (!_online) {
      setState(() {
        _banner = null;
        _fromPick = pick;
      });
      _aiTimer?.cancel();
      _aiTimer = Timer(
        Duration(milliseconds: 380 + _rng.nextInt(520)),
        () => _aiOfflineRespond(),
      );
      return;
    }

    setState(() => _busy = true);
    final res = await _repo.submitRpsPick(
      challengeId: _cid,
      asFrom: _asFrom,
      pick: pick,
    );
    if (!mounted) return;
    res.fold(
      (failure) {
        setState(() {
          _busy = false;
          _banner = failure.message;
        });
        HapticFeedback.heavyImpact();
      },
      (resp) {
        if (!resp.ok) {
          setState(() {
            _busy = false;
            _banner = _errorToUser(resp.error);
          });
          HapticFeedback.heavyImpact();
          return;
        }
        setState(() {
          if (resp.session != null) {
            _applySession(resp.session!);
          }
          if (resp.resolvedRound && resp.session != null) {
            _lastResolvedRoundSeq = resp.session!.roundSeq;
            final rw = resp.roundWinner;
            if (rw != null) {
              final opp = RpsDuelGame.inferOpponentPick(
                myPick: pick,
                iAmFrom: _asFrom,
                roundWinner: rw,
              );
              if (opp != null) {
                _startDuelReveal(_asFrom ? pick : opp, _asFrom ? opp : pick);
              }
            }
            if (resp.session!.status != 'done') {
              _banner = _roundMessage(resp.roundWinner, online: true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _kickPickRowIntro();
              });
            } else {
              _banner = null;
            }
            _hapticRoundResult(resp.roundWinner, online: true);
          } else {
            // Ribbon + helper text already explain the wait; avoid duplicating a second banner.
            _banner = null;
            HapticFeedback.selectionClick();
          }
          _busy = false;
        });
      },
    );
  }

  void _aiOfflineRespond() {
    if (!mounted || _online || _status == 'done') return;
    if (_fromPick == null) return;
    final ai = RpsDuelGame.picks[_rng.nextInt(3)];
    setState(() => _toPick = ai);
    _resolveOfflineRound();
  }

  void _kickPickRowIntro() {
    if (!mounted) return;
    _pickIntroCtrl
      ..reset()
      ..forward();
  }

  void _resolveOfflineRound() {
    if (!mounted || _online) return;
    final a = _fromPick;
    final b = _toPick;
    if (a == null || b == null) return;

    final rw = RpsDuelGame.roundOutcome(a, b);
    var nextFrom = _scoreFrom;
    var nextTo = _scoreTo;
    if (rw == 0) {
      nextFrom++;
    } else if (rw == 1) {
      nextTo++;
    }
    final done =
        nextFrom >= RpsDuelGame.roundWinsToFinish ||
        nextTo >= RpsDuelGame.roundWinsToFinish;

    setState(() {
      _scoreFrom = nextFrom;
      _scoreTo = nextTo;
      _roundSeq++;
      _fromPick = null;
      _toPick = null;
      _status = done ? 'done' : 'playing';
      _banner = _roundMessage(rw, online: false);
      _duelFromPick = a;
      _duelToPick = b;
    });
    _duelCtrl
      ..reset()
      ..forward();
    _duelRevealClear?.cancel();
    _duelRevealClear = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _duelFromPick = null;
        _duelToPick = null;
      });
    });
    _hapticRoundResult(rw, online: false);
    if (done) {
      HapticFeedback.heavyImpact();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _kickPickRowIntro();
      });
    }
  }

  String? _errorToUser(String? code) {
    final l10n = context.l10n;
    switch (code) {
      case 'invalid_pick':
        return l10n.rpsInvalidThrow;
      case 'not_participant':
        return l10n.rpsNotInThisMatch;
      case 'match_over':
        return l10n.rpsMatchAlreadyFinished;
      case 'already_submitted':
        return l10n.rpsAlreadyLockedForRound;
      default:
        return code ?? l10n.somethingWentWrong;
    }
  }

  String _roundMessage(int? roundWinner, {required bool online}) {
    final l10n = context.l10n;
    if (roundWinner == null) return l10n.roundComplete;
    if (roundWinner == -1) return l10n.drawReplayRound;
    if (!online) {
      if (roundWinner == 0) return l10n.youTakeRound;
      return l10n.aiTakesRound;
    }
    final u = _uid;
    if (u == null) {
      return roundWinner == 0
          ? l10n.challengerWinsRound
          : l10n.hostWinsRound;
    }
    final iAmFrom = u == widget.online!.fromUserId;
    final youWon = (roundWinner == 0) == iAmFrom;
    if (youWon) return l10n.youTakeRound;
    return l10n.opponentTakesRound(widget.opponentName);
  }

  Future<void> _onPlayAgainPressed() async {
    if (_online) {
      final res = await _repo.resetRpsMatch(challengeId: _cid);
      if (!mounted) return;
      res.fold(
        (_) {
          setState(() {
            _banner = context.l10n.couldNotResetBout;
          });
        },
        (_) {
          if (widget.onPlayAgain != null) {
            widget.onPlayAgain!();
          } else {
            unawaited(_bootstrapOnline());
            if (mounted) {
              setState(() {
                _banner = null;
                _busy = false;
              });
            }
          }
        },
      );
      return;
    }
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
    } else {
      setState(() {
        _scoreFrom = 0;
        _scoreTo = 0;
        _status = 'playing';
        _roundSeq = 0;
        _fromPick = null;
        _toPick = null;
        _banner = null;
      });
    }
  }

  void _startDuelReveal(String fromPick, String toPick) {
    _duelRevealClear?.cancel();
    setState(() {
      _duelFromPick = fromPick;
      _duelToPick = toPick;
    });
    _duelCtrl
      ..reset()
      ..forward();
    _duelRevealClear = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _duelFromPick = null;
        _duelToPick = null;
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _aiTimer?.cancel();
    _duelRevealClear?.cancel();
    _duelCtrl.dispose();
    _pickIntroCtrl.dispose();
    super.dispose();
  }

  Widget _slideFadePick(int staggerIndex, Widget child) {
    final start = staggerIndex * 0.1;
    final end = (0.45 + staggerIndex * 0.18).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _pickIntroCtrl,
      builder: (context, _) {
        final t = CurvedAnimation(
          parent: _pickIntroCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  IconData _iconForPick(String pick) {
    switch (pick) {
      case 'rock':
        return Icons.landscape_rounded;
      case 'paper':
        return Icons.description_rounded;
      case 'scissors':
        return Icons.content_cut_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _bannerIcon(String text) {
    final t = text.toLowerCase();
    if (t.contains('draw')) return Icons.shuffle_rounded;
    if (t.contains('take the round') && t.startsWith('you')) {
      return Icons.bolt_rounded;
    }
    if (t.contains('take the round')) return Icons.south_rounded;
    if (t.contains('waiting') || t.contains('locked')) {
      return Icons.hourglass_top_rounded;
    }
    if (t.contains('could not') || t.contains('invalid') || t.contains('not in')) {
      return Icons.error_outline_rounded;
    }
    return Icons.chat_bubble_outline_rounded;
  }

  bool _bannerLooksLikeError(String text) {
    final t = text.toLowerCase();
    return t.contains('could not') ||
        t.contains('invalid') ||
        t.contains('not in') ||
        t.contains('not available') ||
        t.contains('already finished') ||
        t.contains('something went wrong');
  }

  GameMatchOutcome? get _outcomeWhenBoutDone {
    if (_status != 'done') return null;
    if (_scoreFrom == _scoreTo) return GameMatchOutcome.draw;
    if (!_online) {
      return _scoreFrom > _scoreTo
          ? GameMatchOutcome.win
          : GameMatchOutcome.loss;
    }
    final uid = _uid;
    if (uid == null) return null;
    final iAmFrom = uid == widget.online!.fromUserId;
    final fromWins = _scoreFrom > _scoreTo;
    final youWon = fromWins == iAmFrom;
    return youWon ? GameMatchOutcome.win : GameMatchOutcome.loss;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final theme = widget.theme;
    final uid = _uid;
    final l10n = context.l10n;
    // Columns always match server: left = challenger (`from`), right = host (`to`).
    // Labels swap so "You" sits under your score (fixes both sides showing the same number).
    final fromIsViewer =
        !_online || uid == null || uid == widget.online!.fromUserId;
    final leftScore = _scoreFrom;
    final rightScore = _scoreTo;
    final myLabel = l10n.you;
    final oppLabel = widget.opponentName;
    final leftLabel = fromIsViewer ? myLabel : oppLabel;
    final rightLabel = fromIsViewer ? oppLabel : myLabel;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GameMatchOutcomeLayer(
          outcome: _outcomeWhenBoutDone,
          scheme: scheme,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.09),
                  scheme.surface.withValues(alpha: 0.35),
                  scheme.tertiary.withValues(alpha: 0.07),
                ],
                stops: const [0.0, 0.5, 1],
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        _RpsDecorHeader(theme: theme, scheme: scheme, opponentName: oppLabel, online: _online),
        const SizedBox(height: 12),
        if (_status == 'done') ...[
          TweenAnimationBuilder<double>(
            key: ValueKey<String>('win$leftScore$rightScore'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 580),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              final scale = lerpDouble(0.88, 1, Curves.easeOutBack.transform(t)) ?? 1;
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
            child: _winnerHero(
              context,
              theme,
              scheme,
              uid,
              leftScore,
              rightScore,
              leftLabel,
              rightLabel,
            ),
          ),
          const SizedBox(height: 24),
        ],
        _scoreArena(
          theme: theme,
          scheme: scheme,
          leftLabel: leftLabel,
          rightLabel: rightLabel,
          leftScore: leftScore,
          rightScore: rightScore,
          leftAccent: scheme.primary,
          rightAccent: scheme.tertiary,
          roundLabel: _status == 'done' ? null : l10n.rpsSetNumber(_roundSeq + 1),
          roundAnimKey: _roundSeq,
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            );
          },
          child: _banner == null
              ? const SizedBox.shrink(key: ValueKey<String>('empty'))
              : _statusBanner(
                  key: ValueKey<String>(_banner!),
                  theme: theme,
                  scheme: scheme,
                  text: _banner!,
                  icon: _bannerIcon(_banner!),
                  isError: _bannerLooksLikeError(_banner!),
                ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey<bool>(_canPickThisRound),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (context, t, child) {
                return Transform.scale(scale: 0.86 + 0.14 * t, child: child);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.85),
                  child: Icon(
                    Icons.touch_app_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseYourThrow,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _status == 'done'
                        ? l10n.boutFinished
                        : _canPickThisRound
                            ? l10n.tapCardRevealVs(oppLabel)
                            : l10n.waitingForRound,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (!_canPickThisRound && _status != 'done')
              const _PulsingWaitChip(),
          ],
        ),
        const SizedBox(height: 8),
        if (!_canPickThisRound && _status != 'done')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _online
                  ? (_busy
                        ? l10n.sendingYourPick
                        : l10n.opponentStillChoosing)
                  : (_fromPick != null && _toPick == null
                        ? l10n.aiThinking
                        : ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        _lockedThrowRibbon(theme, scheme),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _slideFadePick(
                0,
                _pickCard(
                  theme,
                  scheme,
                  'rock',
                  Icons.landscape_rounded,
                  l10n.rpsRock,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _slideFadePick(
                1,
                _pickCard(
                  theme,
                  scheme,
                  'paper',
                  Icons.description_rounded,
                  l10n.rpsPaper,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _slideFadePick(
                2,
                _pickCard(
                  theme,
                  scheme,
                  'scissors',
                  Icons.content_cut_rounded,
                  l10n.rpsScissors,
                ),
              ),
            ),
          ],
        ),
          ],
        ),
          ),
        ),
        if (_duelFromPick != null && _duelToPick != null)
          _RpsRoundClashOverlay(
            scheme: scheme,
            theme: theme,
            fromPick: _duelFromPick!,
            toPick: _duelToPick!,
            animation: _duelCtrl,
          ),
      ],
    );
  }

  Widget _lockedThrowRibbon(ThemeData theme, ColorScheme scheme) {
    final p = _myCommittedPick;
    if (p == null || _status != 'playing') return const SizedBox.shrink();
    final pickLabel = switch (p) {
      'rock' => context.l10n.rpsRock,
      'paper' => context.l10n.rpsPaper,
      'scissors' => context.l10n.rpsScissors,
      _ => p,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        key: ValueKey<String>('lock$p'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Material(
          color: scheme.tertiaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 22, color: scheme.onTertiaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.throwLockedIn,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                      Text(
                        _online
                            ? context.l10n.hiddenUntilBothThrow
                            : context.l10n.aiPickingNext,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer.withValues(alpha: 0.85),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForPick(p), size: 26, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        pickLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBanner({
    required Key key,
    required ThemeData theme,
    required ColorScheme scheme,
    required String text,
    required IconData icon,
    required bool isError,
  }) {
    final bg = isError
        ? scheme.errorContainer.withValues(alpha: 0.92)
        : scheme.primaryContainer.withValues(alpha: 0.55);
    final fg = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final iconBg = isError
        ? scheme.error.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.14);

    return Material(
      key: key,
      color: bg,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: isError ? scheme.error : scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreArena({
    required ThemeData theme,
    required ColorScheme scheme,
    required String leftLabel,
    required String rightLabel,
    required int leftScore,
    required int rightScore,
    required Color leftAccent,
    required Color rightAccent,
    required String? roundLabel,
    required int roundAnimKey,
  }) {
    final cap = RpsDuelGame.roundWinsToFinish;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(roundAnimKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, pulse, child) {
        return Transform.translate(
          offset: Offset(0, 6 * (1 - pulse)),
          child: Opacity(opacity: 0.55 + 0.45 * pulse, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.72),
              scheme.primary.withValues(alpha: 0.06),
              scheme.surfaceContainerLow.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: leftAccent.withValues(alpha: 0.07),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.scoreboard,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (roundLabel != null)
                    TweenAnimationBuilder<double>(
                      key: ValueKey<String>(roundLabel),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) {
                        return Transform.scale(scale: 0.9 + 0.1 * t, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.2),
                              scheme.tertiary.withValues(alpha: 0.14),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          roundLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.firstToRoundWinsTakesBout(cap),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (leftScore / cap).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: scheme.surface.withValues(alpha: 0.55),
                        color: leftAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (rightScore / cap).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: scheme.surface.withValues(alpha: 0.55),
                        color: rightAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _scorePillar(
                      theme: theme,
                      scheme: scheme,
                      label: leftLabel,
                      score: leftScore,
                      accent: leftAccent,
                      alignEnd: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(roundAnimKey),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, t, child) {
                        final s = 1 + 0.18 * math.sin(t * math.pi);
                        return Transform.scale(scale: s, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              scheme.surface.withValues(alpha: 0.98),
                              scheme.primaryContainer.withValues(alpha: 0.35),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          context.l10n.vsUpper,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _scorePillar(
                      theme: theme,
                      scheme: scheme,
                      label: rightLabel,
                      score: rightScore,
                      accent: rightAccent,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _winDots(score: leftScore, fill: leftAccent, scheme: scheme),
                  ),
                  const SizedBox(width: 56),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _winDots(
                        score: rightScore,
                        fill: rightAccent,
                        scheme: scheme,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scorePillar({
    required ThemeData theme,
    required ColorScheme scheme,
    required String label,
    required int score,
    required Color accent,
    required bool alignEnd,
  }) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          style: (theme.textTheme.displayMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 52,
            height: 1.05,
            letterSpacing: -1.5,
            color: accent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return ScaleTransition(
                scale: Tween<double>(begin: 1.35, end: 1).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Text(
              '$score',
              key: ValueKey<int>(score),
            ),
          ),
        ),
      ],
    );
  }

  Widget _winDots({
    required int score,
    required Color fill,
    required ColorScheme scheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(RpsDuelGame.roundWinsToFinish, (i) {
        final on = i < score;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: on ? 12 : 10,
            height: on ? 12 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? fill : scheme.surface.withValues(alpha: 0.5),
              border: Border.all(
                color: on ? fill : scheme.outline.withValues(alpha: 0.5),
                width: on ? 0 : 1.5,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: fill.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Color _pickAccent(String pick, ColorScheme scheme) {
    switch (pick) {
      case 'rock':
        return scheme.outline;
      case 'paper':
        return scheme.primary;
      case 'scissors':
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }

  Widget _pickCard(
    ThemeData theme,
    ColorScheme scheme,
    String pick,
    IconData icon,
    String label,
  ) {
    final enabled = _canPickThisRound && _status != 'done';
    final short = label.length > 6;
    final pressed = _pressingPick == pick;
    final accent = _pickAccent(pick, scheme);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: enabled ? 1 : 0.42,
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerDown: enabled
              ? (_) => setState(() => _pressingPick = pick)
              : null,
          onPointerUp: (_) {
            if (_pressingPick != null) setState(() => _pressingPick = null);
          },
          onPointerCancel: (_) {
            if (_pressingPick != null) setState(() => _pressingPick = null);
          },
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            elevation: enabled ? (pressed ? 6 : 3) : 0,
            shadowColor: accent.withValues(alpha: 0.35),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              splashColor: accent.withValues(alpha: 0.22),
              highlightColor: accent.withValues(alpha: 0.08),
              onTap: enabled ? () => unawaited(_onPick(pick)) : null,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: enabled
                        ? (pressed
                              ? accent.withValues(alpha: 0.75)
                              : accent.withValues(alpha: 0.38))
                        : scheme.outline.withValues(alpha: 0.22),
                    width: pressed ? 2.4 : 1.6,
                  ),
                  color: enabled
                      ? null
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.22),
                            scheme.surfaceContainerLow.withValues(alpha: 0.88),
                            accent.withValues(alpha: 0.12),
                          ],
                        )
                      : null,
                ),
                child: Semantics(
                  button: true,
                  enabled: enabled,
                  label: context.l10n.throwLabelWithHint(
                    label,
                    _pickSubtitle(pick),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: short ? 16 : 20,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: ValueKey<String>('pickIcon$pick$_roundSeq'),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeOutBack,
                          builder: (context, pulse, _) {
                            return Transform.rotate(
                              angle: (1 - pulse) * 0.14 * (pick == 'rock' ? -1 : 1),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.35 + 0.1 * pulse),
                                      accent.withValues(alpha: 0.06),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  size: 32,
                                  color: enabled ? accent : scheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickSubtitle(pick),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _pickSubtitle(String pick) {
    switch (pick) {
      case 'rock':
        return context.l10n.crushesScissors;
      case 'paper':
        return context.l10n.coversRock;
      case 'scissors':
        return context.l10n.cutsPaper;
      default:
        return '';
    }
  }

  Widget _winnerHero(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    String? uid,
    int leftScore,
    int rightScore,
    String leftLabel,
    String rightLabel,
  ) {
    final draw = _scoreFrom == _scoreTo;
    final fromWins = _scoreFrom > _scoreTo;
    bool? youWon;
    if (!draw) {
      if (!_online) {
        youWon = fromWins;
      } else if (uid != null) {
        final iAmFrom = uid == widget.online!.fromUserId;
        youWon = fromWins == iAmFrom;
      }
    }

    final IconData icon;
    final Color accent;
    final String headline;
    final String? subline;
    if (draw) {
      icon = Icons.handshake_rounded;
      accent = scheme.tertiary;
      headline = context.l10n.deadHeat;
      subline = context.l10n.honorSharedRematch;
    } else if (youWon == true) {
      icon = Icons.emoji_events_rounded;
      accent = scheme.primary;
      headline = context.l10n.youWon;
      subline = context.l10n.whatABoutSoakItIn;
    } else if (youWon == false) {
      icon = Icons.auto_fix_high_rounded;
      accent = scheme.tertiary;
      headline = context.l10n.opponentWins(widget.opponentName);
      subline = context.l10n.closeFightRematch;
    } else {
      icon = Icons.flag_rounded;
      accent = scheme.secondary;
      headline = fromWins
          ? context.l10n.challengerSideWins
          : context.l10n.hostSideWins;
      subline = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            scheme.surfaceContainerHighest.withValues(alpha: 0.75),
            scheme.surfaceContainerLow.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 40, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.boutOver,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      if (subline != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    leftLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$leftScore : $rightScore',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    rightLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => unawaited(_onPlayAgainPressed()),
              icon: const Icon(Icons.replay_rounded),
              label: Text(context.l10n.playAgain),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => unawaited(
                showShareGameResultToFeedDialog(
                  context,
                  title: context.l10n.shareToHomeFeed,
                  initialBody:
                      context.l10n.rpsShareBody(
                        widget.opponentName,
                        leftScore,
                        rightScore,
                        leftLabel,
                        rightLabel,
                        headline,
                      ),
                ),
              ),
              icon: const Icon(Icons.feed_rounded),
              label: Text(context.l10n.shareResult),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingWaitChip extends StatefulWidget {
  const _PulsingWaitChip();

  @override
  State<_PulsingWaitChip> createState() => _PulsingWaitChipState();
}

class _PulsingWaitChipState extends State<_PulsingWaitChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fade = Tween<double>(begin: 0.62, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    return FadeTransition(
      opacity: fade,
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.wait,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RpsDecorHeader extends StatefulWidget {
  const _RpsDecorHeader({
    required this.theme,
    required this.scheme,
    required this.opponentName,
    required this.online,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final String opponentName;
  final bool online;

  @override
  State<_RpsDecorHeader> createState() => _RpsDecorHeaderState();
}

class _RpsDecorHeaderState extends State<_RpsDecorHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final scheme = widget.scheme;
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => child!,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final t = _ctrl.value;
                    return Transform.rotate(
                      angle: math.sin(t * math.pi * 2) * 0.04,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment(-0.8 + t * 0.4, -1),
                            end: Alignment(0.6 - t * 0.2, 1.1),
                            colors: [
                              scheme.primary.withValues(alpha: 0.28),
                              scheme.tertiary.withValues(alpha: 0.2),
                              scheme.secondary.withValues(alpha: 0.14),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.balance_rounded,
                          size: 30,
                          color: scheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rpsHeaderTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.online
                            ? l10n.rpsHeaderOnlineSubtitle(widget.opponentName)
                            : l10n.rpsHeaderOfflineSubtitle(widget.opponentName),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _rpsMiniChip(
                            theme,
                            scheme,
                            Icons.landscape_rounded,
                            l10n.rpsRock,
                            scheme.outline,
                          ),
                          _rpsMiniChip(
                            theme,
                            scheme,
                            Icons.description_rounded,
                            l10n.rpsPaper,
                            scheme.primary,
                          ),
                          _rpsMiniChip(
                            theme,
                            scheme,
                            Icons.content_cut_rounded,
                            l10n.rpsScissors,
                            scheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rpsMiniChip(
    ThemeData theme,
    ColorScheme scheme,
    IconData icon,
    String label,
    Color accent,
  ) {
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brief full-screen clash: paper slides over rock when paper wins the throw.
class _RpsRoundClashOverlay extends StatelessWidget {
  const _RpsRoundClashOverlay({
    required this.scheme,
    required this.theme,
    required this.fromPick,
    required this.toPick,
    required this.animation,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String fromPick;
  final String toPick;
  final Animation<double> animation;

  static IconData _iconFor(String pick) {
    switch (pick) {
      case 'rock':
        return Icons.landscape_rounded;
      case 'paper':
        return Icons.description_rounded;
      case 'scissors':
        return Icons.content_cut_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _outcomeLine(BuildContext context, String from, String to, int rw) {
    final l10n = context.l10n;
    if (rw == -1) return l10n.drawReplayRound;
    final paperRock =
        (from == 'paper' && to == 'rock') || (from == 'rock' && to == 'paper');
    if (paperRock) {
      if (rw == 0) return l10n.rpsPaperCoversRockChallengerWins;
      return l10n.rpsPaperCoversRockHostWins;
    }
    if (rw == 0) return l10n.rpsChallengerWinsThrow;
    return l10n.rpsHostWinsThrow;
  }

  @override
  Widget build(BuildContext context) {
    final rw = RpsDuelGame.roundOutcome(fromPick, toPick);
    final paperRock =
        (fromPick == 'paper' && toPick == 'rock') ||
        (fromPick == 'rock' && toPick == 'paper');
    final rockPick = fromPick == 'rock' ? fromPick : toPick;
    final paperPick = fromPick == 'paper' ? fromPick : toPick;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final o = Curves.easeOut.transform(animation.value.clamp(0.0, 1.0));
          return Material(
            color: scheme.shadow.withValues(alpha: 0.38 * o),
            child: child,
          );
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                color: scheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.throwLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 168,
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            final t = Curves.easeOutCubic.transform(animation.value);
                            if (paperRock) {
                              return Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Transform.scale(
                                    scale: lerpDouble(0.88, 1.0, t) ?? 1,
                                    child: Icon(
                                      _iconFor(rockPick),
                                      size: 92,
                                      color: scheme.outline.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, lerpDouble(-76, 6, t) ?? 0),
                                    child: Opacity(
                                      opacity: lerpDouble(0.35, 1, t) ?? 1,
                                      child: Material(
                                        elevation: 6,
                                        borderRadius: BorderRadius.circular(20),
                                        color: scheme.surface,
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Icon(
                                            _iconFor(paperPick),
                                            size: 72,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      _iconFor(fromPick),
                                      size: 64,
                                      color: scheme.tertiary,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.l10n.challenger,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.bolt_rounded, color: scheme.primary.withValues(alpha: 0.5)),
                                Column(
                                  children: [
                                    Icon(
                                      _iconFor(toPick),
                                      size: 64,
                                      color: scheme.secondary,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.l10n.host,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _outcomeLine(context, fromPick, toPick, rw),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
