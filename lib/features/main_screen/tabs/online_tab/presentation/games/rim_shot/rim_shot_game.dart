import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rim_shot_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/game_result_feed_share.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rim_shot/rim_shot_online_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RimShotGame extends StatefulWidget {
  const RimShotGame({
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
  final RimShotOnlineConfig? online;
  final VoidCallback? onPlayAgain;

  /// First to this many buckets wins.
  static const int winningScore = 6;

  /// Seconds to take each shot when it is your turn.
  static const int secondsPerTurn = 12;

  /// Hold-to-charge window (ms); shorter bar cycle = tighter release timing.
  static const int chargeMs = 520;

  /// Power band on the charge bar that counts as “in the pocket”.
  static const double sweetPowerLow = 0.52;
  static const double sweetPowerHigh = 0.70;

  /// How far left/right from center still counts as “on target”.
  static const double sweetAimAbs = 0.165;

  static bool computeMade(double power, double aim) {
    return power >= sweetPowerLow &&
        power <= sweetPowerHigh &&
        aim.abs() <= sweetAimAbs;
  }

  static int _rimObstacleSeed(String? challengeId, int shotOrdinal) {
    var h = shotOrdinal * 0x9E3779B9;
    if (challengeId != null) {
      for (final c in challengeId.codeUnits) {
        h = (h * 31 + c) & 0x7fffffff;
      }
    }
    return h;
  }

  /// Left wing — biased slightly toward the lane so straight shots get contested more.
  static double rimObstacle1Norm(String? challengeId, int shotOrdinal) {
    final u = (_rimObstacleSeed(challengeId, shotOrdinal) % 10001) / 10001.0;
    return -(0.11 + u * 0.33);
  }

  /// Right wing.
  static double rimObstacle2Norm(String? challengeId, int shotOrdinal) {
    final u =
        (_rimObstacleSeed(challengeId, shotOrdinal + 911) % 10001) / 10001.0;
    return 0.11 + u * 0.33;
  }

  /// Defender pad block radius in aim space (smaller than drawn pads).
  static const double _obstacleBlockRadius = 0.088;

  /// True if [aim] lines up with a defender pad (slightly wider hit than draw).
  static bool rimObstacleBlocks(
    String? challengeId,
    int shotOrdinal,
    double aim,
  ) {
    final a = rimObstacle1Norm(challengeId, shotOrdinal);
    final b = rimObstacle2Norm(challengeId, shotOrdinal);
    final r = _obstacleBlockRadius;
    return (aim - a).abs() < r || (aim - b).abs() < r;
  }

  /// Under-rim contest lateral center (same normalized space as [aim] / wing pads).
  static double contestDefenderAimNorm(String? challengeId, int shotOrdinal) {
    final u =
        (_rimObstacleSeed(challengeId, shotOrdinal + 777) % 10001) / 10001.0;
    return (u * 2 - 1) * 0.44;
  }

  /// Half-width of the contest strip in aim space.
  static double contestDefenderHalfWidthNorm(String? challengeId, int shotOrdinal) {
    final u =
        (_rimObstacleSeed(challengeId, shotOrdinal + 1444) % 10001) / 10001.0;
    return 0.095 + u * 0.09;
  }

  /// Help defender: can swat otherwise-clean makes when your aim lands in their strip
  /// (deterministic from session + shot + release so online replays match).
  static bool rimContestBlocks(
    String? challengeId,
    int shotOrdinal,
    double power,
    double aim,
  ) {
    if (!computeMade(power, aim)) return false;
    if (rimObstacleBlocks(challengeId, shotOrdinal, aim)) return false;
    final c = contestDefenderAimNorm(challengeId, shotOrdinal);
    final half = contestDefenderHalfWidthNorm(challengeId, shotOrdinal);
    if ((aim - c).abs() > half) return false;
    final h = _rimObstacleSeed(challengeId, shotOrdinal + 4999);
    final pBits = (power * 4096).round() & 4095;
    final aBits = (aim * 4096).round() & 4095;
    final gate = (h ^ (pBits << 4) ^ aBits) & 1023;
    return gate < 340;
  }

  /// Sweet power + aim, wing pads clear, and no under-rim contest swat.
  static bool shotScores(
    String? challengeId,
    int shotOrdinal,
    double power,
    double aim,
  ) {
    return computeMade(power, aim) &&
        !rimObstacleBlocks(challengeId, shotOrdinal, aim) &&
        !rimContestBlocks(challengeId, shotOrdinal, power, aim);
  }

  @override
  State<RimShotGame> createState() => _RimShotGameState();
}

class _RimShotGameState extends State<RimShotGame>
    with TickerProviderStateMixin {
  late final AnimationController _flightCtrl;
  late final Animation<double> _flight;

  final _rng = math.Random();

  int _scoreFrom = 0;
  int _scoreTo = 0;
  String _whoseTurn = 'from';
  String _status = 'playing';
  int _displayedSeq = 0;

  /// Latest [round_seq] we committed from this device; used to avoid replaying our own shot from poll.
  int _lastLocalCommitSeq = -1;

  /// Offline-only: increments each shot so obstacle layout stays deterministic per attempt.
  int _offlineShotSeq = 0;

  /// [RimShotGame.rimObstacle*Norm] index for the ball flight / replay paint.
  int _flightObstacleOrdinal = 1;

  double _aim = 0;
  double _chargePower = 0;
  DateTime? _chargeStarted;
  Timer? _chargeTicker;
  Timer? _poll;
  Timer? _aiTimer;
  Timer? _shotClockTimer;
  int _shotSecondsLeft = 0;
  String? _shotTimerKey;

  bool _charging = false;
  bool _flying = false;
  bool _busyCommit = false;
  bool _flightEndHandled = false;

  /// When true, flight end runs [tryApplyRimShotTurn]. False for remote replay only.
  bool _pendingOnlineCommit = false;
  String? _banner;
  String? _myRole;

  double _flyPower = 0.5;
  double _flyAim = 0;
  bool _flyMade = false;

  OnlineRepository get _repo => widget.online!.repository;
  String get _cid => widget.online!.challengeId;
  bool get _online => widget.online != null;

  @override
  void initState() {
    super.initState();
    _flightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _flight = CurvedAnimation(parent: _flightCtrl, curve: Curves.easeInOut);
    _flightCtrl.addStatusListener(_onFlightStatus);

    if (_online) {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      _myRole = uid == widget.online!.fromUserId
          ? 'from'
          : (uid == widget.online!.toUserId ? 'to' : null);
      unawaited(_bootstrapOnline());
      _poll = Timer.periodic(const Duration(milliseconds: 420), (_) {
        unawaited(_pollRemote());
      });
    } else {
      _whoseTurn = 'from';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureShotTurnTimer();
    });
  }

  Future<void> _bootstrapOnline() async {
    await _repo.ensureRimShotSession(challengeId: _cid);
    final r = await _repo.fetchRimShotSession(challengeId: _cid);
    await r.fold((_) async {}, (m) async {
      if (!mounted || m == null) return;
      setState(() {
        _applySession(m, syncSeq: true);
      });
      if (mounted) _ensureShotTurnTimer();
    });
  }

  void _applySession(RimShotSessionModel m, {required bool syncSeq}) {
    _scoreFrom = m.scoreFrom;
    _scoreTo = m.scoreTo;
    _whoseTurn = m.whoseTurn;
    _status = m.status;
    if (syncSeq) {
      _displayedSeq = m.roundSeq;
    }
  }

  Future<void> _pollRemote() async {
    if (!_online || !mounted || _flying || _busyCommit || _charging) return;
    final r = await _repo.fetchRimShotSession(challengeId: _cid);
    await r.fold((_) async {}, (m) async {
      if (!mounted || m == null) return;
      if (m.roundSeq > _displayedSeq &&
          m.lastPower != null &&
          m.lastAim != null &&
          m.lastMade != null &&
          m.roundSeq != _lastLocalCommitSeq) {
        setState(() {
          _applySession(m, syncSeq: false);
        });
        _flyPower = m.lastPower!;
        _flyAim = m.lastAim!;
        _flyMade = m.lastMade!;
        _flightObstacleOrdinal = m.roundSeq;
        _banner = null;
        await _runFlightAnimation(onlineCommit: false);
        if (!mounted) return;
        setState(() {
          _displayedSeq = m.roundSeq;
          _flying = false;
        });
        if (mounted) _ensureShotTurnTimer();
        return;
      }
      setState(() => _applySession(m, syncSeq: false));
      if (mounted) _ensureShotTurnTimer();
    });
  }

  void _onFlightStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_flightEndHandled) {
      _flightEndHandled = true;
      unawaited(_afterFlight());
    }
  }

  /// Writes this shot using **server** scores and [round_seq] so a lagging poll
  /// cannot send a stale [nextRoundSeq] / scores (common cause of sync errors).
  Future<void> _commitOnlineTurn(String shooter) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
      }

      final freshR = await _repo.fetchRimShotSession(challengeId: _cid);
      if (!mounted) return;

      RimShotSessionModel? fetched;
      var fetchFailed = false;
      freshR.fold(
        (_) {
          fetchFailed = true;
        },
        (v) {
          fetched = v;
        },
      );

      if (fetchFailed) {
        if (attempt >= 1 && mounted) {
          setState(() {
            _flying = false;
            _banner = 'Sync failed — try again';
          });
        }
        continue;
      }

      final server = fetched;
      if (server == null) {
        if (mounted) {
          setState(() {
            _flying = false;
            _banner = 'Match no longer available';
          });
        }
        return;
      }

      if (server.whoseTurn != shooter) {
        if (mounted) {
          setState(() {
            _applySession(server, syncSeq: false);
            _displayedSeq = server.roundSeq;
            _flying = false;
            _banner = 'Turn changed — wait';
          });
        }
        return;
      }

      final nextFrom =
          server.scoreFrom + (shooter == 'from' && _flyMade ? 1 : 0);
      final nextTo = server.scoreTo + (shooter == 'to' && _flyMade ? 1 : 0);
      final done = nextFrom >= RimShotGame.winningScore ||
          nextTo >= RimShotGame.winningScore;
      final nextTurn = done ? shooter : (shooter == 'from' ? 'to' : 'from');
      final nextSeq = server.roundSeq + 1;

      _busyCommit = true;
      final res = await _repo.tryApplyRimShotTurn(
        challengeId: _cid,
        expectedTurn: shooter,
        power: _flyPower,
        aim: _flyAim,
        made: _flyMade,
        nextScoreFrom: nextFrom,
        nextScoreTo: nextTo,
        nextTurn: nextTurn,
        status: done ? 'done' : 'playing',
        nextRoundSeq: nextSeq,
      );
      _busyCommit = false;
      if (!mounted) return;

      RimShotSessionModel? row;
      var applyFailed = false;
      res.fold(
        (_) {
          applyFailed = true;
        },
        (v) {
          row = v;
        },
      );

      if (applyFailed) {
        if (attempt >= 1 && mounted) {
          setState(() {
            _flying = false;
            _banner = 'Sync failed — try again';
          });
        }
        continue;
      }

      if (row == null) {
        if (mounted) {
          setState(() {
            _flying = false;
            _banner = 'Turn changed — wait';
          });
          unawaited(_pollRemote());
        }
        return;
      }

      if (mounted) {
        setState(() {
          _applySession(row!, syncSeq: false);
          _displayedSeq = row!.roundSeq;
          _lastLocalCommitSeq = row!.roundSeq;
          _flying = false;
          _banner = _flyMade ? 'Buckets!' : 'Miss!';
        });
      }
      return;
    }
  }

  Future<void> _afterFlight() async {
    try {
      if (!_online) {
        if (_status == 'done') {
          if (mounted) setState(() => _flying = false);
          return;
        }
        if (mounted) {
          setState(() {
            _whoseTurn = _whoseTurn == 'from' ? 'to' : 'from';
            _flying = false;
            _banner = _flyMade ? 'Buckets!' : 'Miss!';
          });
        }
        _maybeScheduleAi();
        return;
      }

      if (!_pendingOnlineCommit) {
        if (mounted) setState(() => _flying = false);
        return;
      }

      if (_myRole == null) {
        if (mounted) setState(() => _flying = false);
        return;
      }

      final shooter = _myRole!;
      await _commitOnlineTurn(shooter);
    } finally {
      if (mounted) {
        _flightCtrl.reset();
        _ensureShotTurnTimer();
      }
    }
  }

  void _cancelShotTurnTimer() {
    _shotClockTimer?.cancel();
    _shotClockTimer = null;
  }

  void _ensureShotTurnTimer() {
    if (!mounted) return;
    if (!_isMyTurn || _flying || _status != 'playing') {
      _cancelShotTurnTimer();
      _shotTimerKey = null;
      return;
    }
    final key = '${_displayedSeq}_$_whoseTurn';
    if (_shotClockTimer != null && key == _shotTimerKey) return;
    _shotTimerKey = key;
    _cancelShotTurnTimer();
    setState(() {
      _shotSecondsLeft = RimShotGame.secondsPerTurn;
    });
    _shotClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isMyTurn || _flying || _status != 'playing') {
        _cancelShotTurnTimer();
        return;
      }
      var expired = false;
      setState(() {
        _shotSecondsLeft--;
        if (_shotSecondsLeft <= 0) {
          expired = true;
        }
      });
      if (expired) {
        _cancelShotTurnTimer();
        unawaited(_onShotClockExpired());
      }
    });
  }

  Future<void> _onShotClockExpired() async {
    if (!_isMyTurn || _flying || _status != 'playing') return;
    _chargeTicker?.cancel();
    _charging = false;
    _chargeStarted = null;
    _chargePower = 0;
    final mid =
        (RimShotGame.sweetPowerLow + RimShotGame.sweetPowerHigh) / 2;
    final power = (mid + (_rng.nextDouble() * 2 - 1) * 0.08).clamp(0.0, 1.0);
    final aim = ((_rng.nextDouble() * 2 - 1) * 0.35).clamp(-1.0, 1.0);
    _commitPlayerShot(power, aim);
  }

  void _commitPlayerShot(double locked, double aim) {
    if (!_isMyTurn || _flying || _status != 'playing') return;
    final cid = widget.online?.challengeId;
    final ord = _online ? (_displayedSeq + 1) : ++_offlineShotSeq;
    _flightObstacleOrdinal = ord;
    final made = RimShotGame.shotScores(cid, ord, locked, aim);
    setState(() {
      _flyPower = locked;
      _flyAim = aim;
      _flyMade = made;
      if (!_online) {
        if (_whoseTurn == 'from' && made) {
          _scoreFrom++;
        }
        if (_whoseTurn == 'to' && made) {
          _scoreTo++;
        }
        if (_scoreFrom >= RimShotGame.winningScore ||
            _scoreTo >= RimShotGame.winningScore) {
          _status = 'done';
        }
      }
    });
    unawaited(_runFlightAnimation(onlineCommit: _online));
  }

  void _maybeScheduleAi() {
    _aiTimer?.cancel();
    if (_online || _status == 'done') return;
    if (_whoseTurn != 'to') return;
    final delay = Duration(milliseconds: 700 + _rng.nextInt(900));
    _aiTimer = Timer(delay, () {
      if (!mounted || _online || _status == 'done') return;
      // Stay near center aim + mid power so offline stays competitive with easier human tuning.
      final aim = (_rng.nextDouble() * 2 - 1) * 0.14;
      final mid =
          (RimShotGame.sweetPowerLow + RimShotGame.sweetPowerHigh) / 2;
      final power = mid + (_rng.nextDouble() * 2 - 1) * 0.07;
      final ord = ++_offlineShotSeq;
      _flightObstacleOrdinal = ord;
      final made = RimShotGame.shotScores(null, ord, power, aim);
      setState(() {
        _flyPower = power;
        _flyAim = aim;
        _flyMade = made;
        if (made) {
          _scoreTo++;
        }
        if (_scoreTo >= RimShotGame.winningScore ||
            _scoreFrom >= RimShotGame.winningScore) {
          _status = 'done';
        }
      });
      unawaited(_runFlightAnimation(onlineCommit: false));
    });
  }

  Future<void> _runFlightAnimation({required bool onlineCommit}) async {
    _pendingOnlineCommit = onlineCommit;
    _flightEndHandled = false;
    _flightCtrl.value = 0;
    setState(() {
      _flying = true;
      _banner = null;
    });
    _ensureShotTurnTimer();
    await _flightCtrl.forward(from: 0);
  }

  bool get _isMyTurn {
    if (_online) {
      if (_myRole == null) return false;
      return _whoseTurn == _myRole && _status == 'playing';
    }
    return _whoseTurn == 'from' && _status == 'playing';
  }

  void _startCharge() {
    if (!_isMyTurn || _flying || _charging || _status != 'playing') return;
    HapticFeedback.selectionClick();
    _charging = true;
    _chargeStarted = DateTime.now();
    _chargeTicker?.cancel();
    _chargeTicker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_charging || _chargeStarted == null) return;
      final ms = DateTime.now().difference(_chargeStarted!).inMilliseconds;
      final p = (ms / RimShotGame.chargeMs).clamp(0.0, 1.0);
      setState(() => _chargePower = p);
    });
    setState(() {});
  }

  void _releaseCharge() {
    if (!_charging) return;
    final started = _chargeStarted;
    _chargeTicker?.cancel();
    _charging = false;
    _chargeStarted = null;
    // Use release instant (not last 16ms tick) so power matches the green band.
    var locked = _chargePower;
    if (started != null) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      locked = (ms / RimShotGame.chargeMs).clamp(0.0, 1.0);
    }
    _chargePower = 0;
    if (locked < 0.095) {
      setState(() {});
      return;
    }
    _commitPlayerShot(locked, _aim);
  }

  void _restartLocal() {
    setState(() {
      _scoreFrom = 0;
      _scoreTo = 0;
      _whoseTurn = 'from';
      _status = 'playing';
      _displayedSeq = 0;
      _offlineShotSeq = 0;
      _flightObstacleOrdinal = 1;
      _banner = null;
      _aim = 0;
      _flying = false;
      _charging = false;
    });
    _flightCtrl.reset();
    _ensureShotTurnTimer();
  }

  @override
  void dispose() {
    _chargeTicker?.cancel();
    _poll?.cancel();
    _aiTimer?.cancel();
    _cancelShotTurnTimer();
    _flightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final theme = widget.theme;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    const myLabel = 'You';
    final oppLabel = widget.opponentName;

    final iLeadFrom =
        !_online || uid == null || uid == widget.online?.fromUserId;
    final leftScore = iLeadFrom ? _scoreFrom : _scoreTo;
    final rightScore = iLeadFrom ? _scoreTo : _scoreFrom;
    final leftLabel = iLeadFrom ? myLabel : oppLabel;
    final rightLabel = iLeadFrom ? oppLabel : myLabel;
    final statusLine = _statusLine(uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status == 'done') ...[
          _winnerOutcomeHero(context, theme, scheme, uid),
          const SizedBox(height: 20),
        ],
        _rimSectionHeader(
          theme,
          scheme,
          title: 'Score',
          subtitle: 'First to ${RimShotGame.winningScore} · turn alternates',
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _scoreCol(theme, scheme, leftLabel, leftScore, scheme.primary),
              const Spacer(),
              Text(
                'VS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _rimShotClockChip(theme, scheme),
              const SizedBox(width: 10),
              _scoreCol(
                theme,
                scheme,
                rightLabel,
                rightScore,
                scheme.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _rimSectionHeader(
          theme,
          scheme,
          title: 'Court',
          subtitle:
              'Free-throw lane, glass, net · arc follows release strength · contest under the rim',
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 10 / 11,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AnimatedBuilder(
              animation: _flight,
              builder: (context, _) {
                final cid = widget.online?.challengeId;
                final previewOrd = _online
                    ? (_displayedSeq + 1)
                    : (_offlineShotSeq + 1);
                final ord = _flying ? _flightObstacleOrdinal : previewOrd;
                final fp = _flying
                    ? _flyPower
                    : (_charging ? _chargePower : 0.58);
                return CustomPaint(
                  painter: _RimCourtPainter(
                    scheme: scheme,
                    challengeId: cid,
                    obstacleOrdinal: ord,
                    t: _flying ? _flight.value : 0,
                    aim: _flying ? _flyAim : _aim,
                    made: _flying ? _flyMade : false,
                    charging: _charging,
                    chargeP: _charging ? _chargePower : 0,
                    flightPower: fp,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _rimSectionHeader(
          theme,
          scheme,
          title: 'Aim',
          subtitle:
              'Short vs long misses follow power; wings + help defender — avoid the amber strip',
        ),
        const SizedBox(height: 6),
        Slider(
          value: _aim.clamp(-1.0, 1.0),
          min: -1,
          max: 1,
          divisions: 40,
          label: _aim.toStringAsFixed(2),
          onChanged: (_flying || !_isMyTurn || _status != 'playing')
              ? null
              : (v) => setState(() => _aim = v),
        ),
        if (_status != 'done') ...[
          const SizedBox(height: 16),
          _rimSectionHeader(
            theme,
            scheme,
            title: 'Status',
            subtitle: 'Turn prompt or last shot result',
          ),
          const SizedBox(height: 4),
          Text(
            statusLine,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 8),
        _rimSectionHeader(
          theme,
          scheme,
          title: 'Power',
          subtitle: 'Hold the pad, release when the fill hits the green band',
        ),
        const SizedBox(height: 6),
        Listener(
          onPointerDown: (_) => _startCharge(),
          onPointerUp: (_) => _releaseCharge(),
          onPointerCancel: (_) => _releaseCharge(),
          child: Material(
            color: _isMyTurn && !_flying && _status == 'playing'
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  _isMyTurn && !_flying && _status == 'playing'
                      ? (_charging ? 'RELEASE!' : 'HOLD TO CHARGE')
                      : '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onPlayAgainPressed() async {
    if (_online) {
      final res = await _repo.resetRimShotMatch(challengeId: _cid);
      if (!mounted) return;
      res.fold(
        (_) {
          setState(() {
            _banner = 'Could not start a rematch. Check connection, then try again.';
          });
        },
        (_) {
          _lastLocalCommitSeq = -1;
          if (widget.onPlayAgain != null) {
            widget.onPlayAgain!();
          } else {
            unawaited(_bootstrapAfterResetOnline());
          }
        },
      );
      return;
    }
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
    } else {
      _restartLocal();
    }
  }

  Future<void> _bootstrapAfterResetOnline() async {
    await _bootstrapOnline();
    if (!mounted) return;
    setState(() {
      _banner = null;
      _flying = false;
      _charging = false;
    });
    _flightCtrl.reset();
    _ensureShotTurnTimer();
  }

  Widget _winnerOutcomeHero(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    String? uid,
  ) {
    final iLeadFrom =
        !_online || uid == null || uid == widget.online?.fromUserId;
    final leftScore = iLeadFrom ? _scoreFrom : _scoreTo;
    final rightScore = iLeadFrom ? _scoreTo : _scoreFrom;
    const myLabel = 'You';
    final oppLabel = widget.opponentName;
    final leftLabel = iLeadFrom ? myLabel : oppLabel;
    final rightLabel = iLeadFrom ? oppLabel : myLabel;

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
    if (draw) {
      icon = Icons.handshake_rounded;
      accent = scheme.tertiary;
      headline = 'Draw game';
    } else if (youWon == true) {
      icon = Icons.emoji_events_rounded;
      accent = scheme.primary;
      headline = 'You win';
    } else if (youWon == false) {
      icon = Icons.sports_basketball_rounded;
      accent = scheme.error;
      headline = '${widget.opponentName} wins';
    } else {
      icon = Icons.flag_rounded;
      accent = scheme.secondary;
      headline = fromWins ? 'From side wins' : 'To side wins';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 36, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match over',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        headline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  leftLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$leftScore : $rightScore',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  rightLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => unawaited(_onPlayAgainPressed()),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play again'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                showShareGameResultToFeedDialog(
                  context,
                  title: 'Share to home feed',
                  initialBody:
                      'Rim shot vs ${widget.opponentName}\n'
                      'Final: $leftScore — $rightScore ($leftLabel / $rightLabel)\n'
                      '$headline',
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

  String _statusLine(String? uid) {
    if (_status == 'done') {
      return '';
    }
    return _banner ??
        (_isMyTurn
            ? 'Hold CHARGE, release to shoot'
            : (_online
                  ? '${widget.opponentName} is shooting…'
                  : 'AI is shooting…'));
  }

  Widget _rimSectionHeader(
    ThemeData theme,
    ColorScheme scheme, {
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: scheme.primary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _rimShotClockChip(ThemeData theme, ColorScheme scheme) {
    final active = _isMyTurn && !_flying && _status == 'playing';
    final urgent = active && _shotSecondsLeft <= 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.timer_rounded : Icons.hourglass_empty_rounded,
          size: 20,
          color: active
              ? (urgent ? scheme.error : scheme.primary)
              : scheme.onSurfaceVariant,
        ),
        const SizedBox(height: 2),
        Text(
          active ? '${_shotSecondsLeft}s' : '—',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: active
                ? (urgent ? scheme.error : scheme.onSurface)
                : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _scoreCol(
    ThemeData theme,
    ColorScheme scheme,
    String label,
    int score,
    Color c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$score',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: c,
          ),
        ),
      ],
    );
  }
}

class _RimCourtPainter extends CustomPainter {
  _RimCourtPainter({
    required this.scheme,
    required this.challengeId,
    required this.obstacleOrdinal,
    required this.t,
    required this.aim,
    required this.made,
    required this.charging,
    required this.chargeP,
    required this.flightPower,
  });

  final ColorScheme scheme;
  final String? challengeId;
  final int obstacleOrdinal;
  final double t;
  final double aim;
  final bool made;
  final bool charging;
  final double chargeP;
  /// Normalized release strength (0–1) for arc height and miss geometry.
  final double flightPower;

  static const double _floorY = 0.52;

  @override
  void paint(Canvas canvas, Size size) {
    final hoopX = size.width * 0.5 + aim * size.width * 0.06;
    final hoopY = size.height * 0.2;
    final floorTop = size.height * _floorY;
    final p = flightPower.clamp(0.0, 1.0);

    _drawArena(canvas, size, floorTop);
    _drawCourtFloor(canvas, size, floorTop);
    _drawLanePaint(canvas, size, floorTop, hoopX, hoopY);
    _drawStanchion(canvas, hoopX, hoopY);
    _drawBackboard(canvas, hoopX, hoopY);
    _drawRimAndNet(canvas, hoopX, hoopY);

    final o1 = RimShotGame.rimObstacle1Norm(challengeId, obstacleOrdinal);
    final o2 = RimShotGame.rimObstacle2Norm(challengeId, obstacleOrdinal);
    final padPaint = Paint()..color = Colors.redAccent.withValues(alpha: 0.55);
    final padBorder = Paint()
      ..color = Colors.red.shade900.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final ox in [o1, o2]) {
      final cx = size.width * 0.5 + ox * size.width * 0.26;
      final pad = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, hoopY + 8), width: 14, height: 46),
        const Radius.circular(5),
      );
      canvas.drawRRect(pad, padPaint);
      canvas.drawRRect(pad, padBorder);
    }

    final contestAim = RimShotGame.contestDefenderAimNorm(
      challengeId,
      obstacleOrdinal,
    );
    final contestHalf = RimShotGame.contestDefenderHalfWidthNorm(
      challengeId,
      obstacleOrdinal,
    );
    final defCx = size.width * 0.5 + contestAim * size.width * 0.26;
    final defFeetY = hoopY + 56;
    final inContestStrip =
        charging && (aim - contestAim).abs() <= contestHalf;
    final zoneW = contestHalf * 2 * size.width * 0.26 + 28;
    if (inContestStrip) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(defCx, defFeetY + 10),
          width: zoneW,
          height: 22,
        ),
        Paint()..color = Colors.amber.withValues(alpha: 0.22),
      );
    }
    final jersey = Paint()..color = scheme.primary.withValues(alpha: 0.92);
    final skin = Paint()..color = const Color(0xFF8D6E63);
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(defCx, defFeetY - 40), 10, skin);
    canvas.drawCircle(Offset(defCx, defFeetY - 40), 10, outline);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(defCx, defFeetY - 20),
        width: 20,
        height: 32,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, jersey);
    canvas.drawRRect(body, outline);
    final shoulder = Offset(defCx, defFeetY - 30);
    final armPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, Offset(defCx - 20, defFeetY - 52), armPaint);
    canvas.drawLine(shoulder, Offset(defCx + 20, defFeetY - 52), armPaint);

    final start = Offset(
      size.width * 0.5 + aim * size.width * 0.26,
      size.height * 0.86,
    );
    final end = _shotEnd(hoopX, hoopY, aim, p, made);
    final arcLift = size.height *
        (0.17 + 0.14 * math.sin(p * math.pi) + 0.06 * (1.0 - (p - 0.61).abs() * 2.2).clamp(0.0, 1.0));
    final ctrl = Offset(
      (start.dx + end.dx) * 0.5 + aim * 20,
      math.min(start.dy, end.dy) - arcLift,
    );
    final ballPos = _quad(t, start, ctrl, end);

    if (charging) {
      final bar = Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.72,
        (size.width * 0.76) * chargeP,
        8,
      );
      final barW = size.width * 0.76;
      final barLeft = size.width * 0.12;
      final sweetW =
          barW * (RimShotGame.sweetPowerHigh - RimShotGame.sweetPowerLow);
      final sweetLeft = barLeft + barW * RimShotGame.sweetPowerLow;
      final sweet = Rect.fromLTWH(sweetLeft, size.height * 0.72, sweetW, 8);
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.72,
          size.width * 0.76,
          8,
        ),
        Paint()..color = Colors.black38,
      );
      canvas.drawRect(
        sweet,
        Paint()..color = Colors.green.withValues(alpha: 0.35),
      );
      canvas.drawRect(bar, Paint()..color = scheme.primary);
    }

    _drawBall(canvas, size, ballPos);
  }

  Offset _shotEnd(double hoopX, double hoopY, double aimN, double power, bool swish) {
    if (swish) return Offset(hoopX, hoopY + 14);
    final low = RimShotGame.sweetPowerLow;
    final high = RimShotGame.sweetPowerHigh;
    if (power < low - 0.015) {
      return Offset(hoopX + aimN * 10, hoopY + 36);
    }
    if (power > high + 0.015) {
      return Offset(hoopX - aimN * 8, hoopY - 6);
    }
    final side = aimN >= 0 ? 1.0 : -1.0;
    return Offset(hoopX + side * 40 + aimN * 8, hoopY + 46);
  }

  void _drawArena(Canvas canvas, Size size, double floorTop) {
    final rect = Offset.zero & size;
    final g = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF263238),
        const Color(0xFF37474F),
        const Color(0xFF4E342E),
        const Color(0xFF3E2723),
      ],
      stops: const [0.0, 0.35, 0.62, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = g);
    final stands = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.06 + i * 0.07);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stands);
    }
  }

  void _drawCourtFloor(Canvas canvas, Size size, double floorTop) {
    final court = Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop);
    final wood = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF8D6E63),
        const Color(0xFF6D4C41),
        const Color(0xFF5D4037),
        const Color(0xFF4E342E),
      ],
    ).createShader(court);
    canvas.drawRect(court, Paint()..shader = wood);
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, floorTop), Offset(x, size.height), line);
    }
    canvas.drawLine(
      Offset(0, floorTop),
      Offset(size.width, floorTop),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2.4,
    );
  }

  void _drawLanePaint(
    Canvas canvas,
    Size size,
    double floorTop,
    double hoopX,
    double hoopY,
  ) {
    final key = Path()
      ..moveTo(size.width * 0.5 - 74, floorTop + 6)
      ..lineTo(size.width * 0.5 + 74, floorTop + 6)
      ..lineTo(hoopX + 36, hoopY + 64)
      ..lineTo(hoopX - 36, hoopY + 64)
      ..close();
    canvas.drawPath(
      key,
      Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.22),
    );
    canvas.drawPath(
      key,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.38),
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, floorTop + size.width * 0.22),
        width: size.width * 0.44,
        height: size.width * 0.44,
      ),
      math.pi * 0.72,
      math.pi * 0.56,
      false,
      paint,
    );
  }

  void _drawStanchion(Canvas canvas, double hoopX, double hoopY) {
    final pole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(hoopX - 8, hoopY + 46),
        width: 12,
        height: 124,
      ),
      const Radius.circular(3),
    );
    final sh = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF37474F),
        const Color(0xFF546E7A),
        const Color(0xFF263238),
      ],
    ).createShader(pole.outerRect);
    canvas.drawRRect(pole, Paint()..shader = sh);
    canvas.drawRRect(
      pole,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  void _drawBackboard(Canvas canvas, double hoopX, double hoopY) {
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(hoopX, hoopY - 8), width: 80, height: 56),
      const Radius.circular(6),
    );
    final glass = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFB0BEC5).withValues(alpha: 0.45),
        const Color(0xFFECEFF1).withValues(alpha: 0.88),
        const Color(0xFF90A4AE).withValues(alpha: 0.5),
      ],
    ).createShader(board.outerRect);
    canvas.drawRRect(board, Paint()..shader = glass);
    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.88),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(hoopX, hoopY - 7), width: 48, height: 36),
      const Radius.circular(4),
    );
    canvas.drawRRect(inner, Paint()..color = Colors.orange.withValues(alpha: 0.1));
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.deepOrange.withValues(alpha: 0.55),
    );
  }

  void _drawRimAndNet(Canvas canvas, double hoopX, double hoopY) {
    final rimC = Offset(hoopX, hoopY + 10);
    canvas.drawCircle(rimC, 24, Paint()..color = Colors.black.withValues(alpha: 0.14));
    canvas.drawCircle(rimC, 22.5, Paint()..color = const Color(0xFFE65100));
    canvas.drawCircle(
      rimC,
      21,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFFFD54F),
    );
    final net = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 11; i++) {
      final ang = math.pi * 0.12 + (math.pi * 0.76) * (i / 10);
      final x0 = rimC.dx + math.cos(ang) * 18.5;
      final y0 = rimC.dy + math.sin(ang) * 18.5 + 1.5;
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x0 * 0.94 + rimC.dx * 0.06, y0 + 28),
        net,
      );
    }
  }

  void _drawBall(Canvas canvas, Size size, Offset ballPos) {
    final floorY = size.height * 0.88;
    if (t > 0.02) {
      final hFrac = (ballPos.dy / size.height).clamp(0.15, 1.0);
      final a = (0.32 * (1.1 - hFrac) + 0.08).clamp(0.06, 0.34);
      final w = 22 * (0.5 + 0.5 * hFrac);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ballPos.dx, floorY + 3), width: w, height: 6),
        Paint()..color = Colors.black.withValues(alpha: a),
      );
    }
    const r = 11.2;
    final shader = RadialGradient(
      center: const Alignment(-0.35, -0.42),
      colors: const [
        Color(0xFFFFF8E1),
        Color(0xFFFFB74D),
        Color(0xFFE65100),
        Color(0xFFBF360C),
      ],
      stops: const [0.0, 0.28, 0.62, 1.0],
    ).createShader(Rect.fromCircle(center: ballPos, radius: r * 1.35));
    canvas.drawCircle(ballPos, r, Paint()..shader = shader);
    canvas.drawCircle(
      Offset(ballPos.dx - 3.8, ballPos.dy - 3.6),
      3.4,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      ballPos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.24)
        ..strokeWidth = 1.15,
    );
  }

  Offset _quad(double t, Offset a, Offset b, Offset c) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _RimCourtPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.aim != aim ||
        oldDelegate.made != made ||
        oldDelegate.charging != charging ||
        oldDelegate.chargeP != chargeP ||
        oldDelegate.flightPower != flightPower ||
        oldDelegate.obstacleOrdinal != obstacleOrdinal ||
        oldDelegate.challengeId != challengeId;
  }
}
