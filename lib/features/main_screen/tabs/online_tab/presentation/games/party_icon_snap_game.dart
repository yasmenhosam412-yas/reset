import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_room_service.dart';

/// Party game: memorize the flash, then tap the matching icon fast. Lower total ms wins.
class PartyIconSnapGame extends StatefulWidget {
  const PartyIconSnapGame({super.key, this.roomId});

  final String? roomId;

  @override
  State<PartyIconSnapGame> createState() => _PartyIconSnapGameState();
}

enum _SnapPhase {
  setup,
  showCue,
  picking,
  betweenPlayers,
  finished,
}

class _IconDef {
  const _IconDef(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _PartyIconSnapGameState extends State<PartyIconSnapGame> {
  static const int _totalRounds = 8;

  /// Shorter flash each round (ms), floor ~360ms.
  static int _cueFlashMsForRound(int round) {
    final r = round.clamp(1, _totalRounds);
    return max(360, 1040 - (r - 1) * 98);
  }

  /// Wrong taps hurt more on later rounds.
  static int _wrongTapPenaltyMsForRound(int round) {
    final r = round.clamp(1, _totalRounds);
    return 280 + (r - 1) * 52;
  }

  /// More distractors in later rounds (still one correct match).
  static int _choiceCountForRound(int round) {
    final r = round.clamp(1, _totalRounds);
    if (r <= 2) return 4;
    if (r <= 4) return 5;
    if (r <= 6) return 6;
    return 7;
  }

  static const List<_IconDef> _pool = [
    _IconDef(Icons.bolt_rounded, 'Bolt'),
    _IconDef(Icons.local_cafe_rounded, 'Coffee'),
    _IconDef(Icons.music_note_rounded, 'Note'),
    _IconDef(Icons.sports_basketball_rounded, 'Ball'),
    _IconDef(Icons.pets_rounded, 'Paw'),
    _IconDef(Icons.favorite_rounded, 'Heart'),
    _IconDef(Icons.star_rounded, 'Star'),
    _IconDef(Icons.rocket_launch_rounded, 'Rocket'),
    _IconDef(Icons.wb_sunny_rounded, 'Sun'),
    _IconDef(Icons.nightlight_rounded, 'Moon'),
    _IconDef(Icons.eco_rounded, 'Leaf'),
    _IconDef(Icons.emoji_emotions_rounded, 'Smile'),
  ];

  final _rng = Random();
  int _players = 2;
  int _turn = 0;
  _SnapPhase _phase = _SnapPhase.setup;

  final List<int> _playerTotals = [];
  final List<List<int>> _playerRoundLog = [];
  List<int> _currentRunRounds = [];

  int _round = 1;
  int _wrongPenaltyThisRound = 0;
  DateTime? _pickStartedAt;

  _IconDef? _cueIcon;
  List<_IconDef> _choices = [];

  Timer? _cueTimer;
  Timer? _poll;
  Timer? _presencePoll;
  List<PartyRoomScoreRow> _leaderboard = const [];
  bool _sending = false;
  ConfettiController? _confetti;

  bool get _online => (widget.roomId?.trim().isNotEmpty ?? false);
  PartyRoomPresence? _presence;
  bool get _roomReadyNow =>
      !_online || (_presence != null && _presence!.joinedCount >= _presence!.maxPlayers);

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _resetMatch();
    if (_online) _startPresencePolling();
    _startLeaderboardPolling();
  }

  @override
  void dispose() {
    _cueTimer?.cancel();
    _poll?.cancel();
    _presencePoll?.cancel();
    _confetti?.dispose();
    super.dispose();
  }

  void _startPresencePolling() {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    _pullPresence();
    _presencePoll?.cancel();
    _presencePoll = Timer.periodic(const Duration(seconds: 2), (_) => _pullPresence());
  }

  Future<void> _pullPresence() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    try {
      final p = await PartyRoomService.fetchRoomPresence(rid);
      if (!mounted) return;
      setState(() => _presence = p);
      if (_presence != null && _presence!.joinedCount >= _presence!.maxPlayers) {
        _presencePoll?.cancel();
        _presencePoll = null;
      }
    } catch (_) {}
  }

  void _startLeaderboardPolling() {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    _pullLeaderboard();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pullLeaderboard());
  }

  Future<void> _pullLeaderboard() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    final rows = await PartyRoomService.fetchLeaderboard(rid);
    if (!mounted) return;
    setState(() => _leaderboard = rows);
  }

  void _resetMatch() {
    _cueTimer?.cancel();
    _playerTotals.clear();
    _playerRoundLog.clear();
    _currentRunRounds = [];
    final n = _online ? 1 : _players;
    _playerTotals.addAll(List.filled(n, 0));
    for (var i = 0; i < n; i++) {
      _playerRoundLog.add([]);
    }
    setState(() {
      _turn = 0;
      _phase = _SnapPhase.setup;
      _round = 1;
      _wrongPenaltyThisRound = 0;
      _pickStartedAt = null;
      _cueIcon = null;
      _choices = [];
      _currentRunRounds = [];
    });
  }

  void _startRun() {
    if (!_roomReadyNow) return;
    _cueTimer?.cancel();
    setState(() {
      _phase = _SnapPhase.showCue;
      _round = 1;
      _currentRunRounds = [];
      _wrongPenaltyThisRound = 0;
    });
    _prepareRound();
  }

  void _prepareRound() {
    _cueTimer?.cancel();
    final k = _choiceCountForRound(_round);
    final indices = List<int>.generate(_pool.length, (i) => i)..shuffle(_rng);
    final pick = indices.take(k).map((i) => _pool[i]).toList();
    _cueIcon = pick[_rng.nextInt(k)];
    _choices = List<_IconDef>.from(pick)..shuffle(_rng);
    _wrongPenaltyThisRound = 0;
    setState(() {
      _phase = _SnapPhase.showCue;
      _pickStartedAt = null;
    });
    _cueTimer = Timer(Duration(milliseconds: _cueFlashMsForRound(_round)), () {
      if (!mounted || _phase != _SnapPhase.showCue) return;
      setState(() {
        _phase = _SnapPhase.picking;
        _pickStartedAt = DateTime.now();
      });
    });
  }

  void _onPick(_IconDef tapped) {
    if (_phase != _SnapPhase.picking || _cueIcon == null || _pickStartedAt == null) return;
    if (tapped.icon != _cueIcon!.icon) {
      HapticFeedback.lightImpact();
      setState(() => _wrongPenaltyThisRound += _wrongTapPenaltyMsForRound(_round));
      return;
    }
    HapticFeedback.mediumImpact();
    final ms = DateTime.now().difference(_pickStartedAt!).inMilliseconds + _wrongPenaltyThisRound;
    _currentRunRounds.add(ms);
    _cueTimer?.cancel();

    if (_online) {
      if (_round >= _totalRounds) {
        final total = _currentRunRounds.fold<int>(0, (a, b) => a + b);
        setState(() {
          _phase = _SnapPhase.finished;
          _playerTotals[0] = total;
          _playerRoundLog[0] = List<int>.from(_currentRunRounds);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _confetti?.play());
        _submitOnline();
      } else {
        setState(() => _round++);
        _prepareRound();
      }
      return;
    }

    if (_round >= _totalRounds) {
      final total = _currentRunRounds.fold<int>(0, (a, b) => a + b);
      _playerTotals[_turn] = total;
      _playerRoundLog[_turn] = List<int>.from(_currentRunRounds);
      if (_turn >= _players - 1) {
        setState(() => _phase = _SnapPhase.finished);
        final best = _playerTotals.reduce(min);
        final winners = [for (var i = 0; i < _players; i++) if (_playerTotals[i] == best) i];
        if (winners.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _confetti?.play());
        }
      } else {
        setState(() {
          _phase = _SnapPhase.betweenPlayers;
          _turn++;
        });
      }
      return;
    }
    setState(() => _round++);
    _prepareRound();
  }

  Future<void> _submitOnline() async {
    final rid = widget.roomId?.trim() ?? '';
    if (rid.isEmpty) return;
    final total = _playerTotals.isEmpty ? 0 : _playerTotals[0];
    if (total <= 0) return;
    setState(() => _sending = true);
    try {
      await PartyRoomService.submitScore(
        roomId: rid,
        score: max(1, 500000 - total),
        meta: {
          'game': 'icon_snap',
          'rounds': _totalRounds,
          'total_ms': total,
          'round_times': List<int>.from(_playerRoundLog[0]),
        },
      );
      await _pullLeaderboard();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _nextPlayerStart() {
    setState(() {
      _round = 1;
      _currentRunRounds = [];
      _phase = _SnapPhase.showCue;
    });
    _prepareRound();
  }

  String _playerLabel(int i) => _online ? 'You' : 'Player ${i + 1}';

  BoxDecoration _shell(ColorScheme scheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          scheme.surfaceContainerHighest,
          scheme.surfaceContainerHigh.withValues(alpha: 0.92),
        ],
      ),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.45), width: 2),
      boxShadow: [
        BoxShadow(color: scheme.primary.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 8)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = _roomReadyNow;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'FLASH MATCH',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          _online
              ? 'Each round gets harder: shorter flash, more icons, bigger mistake penalty — $_totalRounds rounds. Lower total time wins.'
              : 'Pass the phone: $_totalRounds rounds each; difficulty ramps every round (flash, grid size, penalties). Lowest total wins.',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (!_online)
          Row(
            children: [
              const Text('Players'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _players,
                items: const [2, 3, 4, 5]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: _phase == _SnapPhase.setup || _phase == _SnapPhase.finished
                    ? (v) {
                        if (v == null) return;
                        setState(() => _players = v);
                        _resetMatch();
                      }
                    : null,
              ),
            ],
          ),
        if (_online && !ready) ...[
          Text(
            _presence == null
                ? 'Loading room…'
                : 'Waiting: ${_presence!.joinedCount} / ${_presence!.maxPlayers}',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _shell(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _phase == _SnapPhase.setup
                    ? 'Tap start when ready.'
                    : _phase == _SnapPhase.betweenPlayers
                        ? '${_playerLabel(_turn)} — your turn next.'
                        : _phase == _SnapPhase.finished
                            ? (_online ? 'Run complete!' : 'Match over!')
                            : '${_playerLabel(_turn)} · Round $_round / $_totalRounds',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              if (_phase == _SnapPhase.showCue && _cueIcon != null)
                Column(
                  children: [
                    Text(
                      'MEMORIZE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: scheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_cueFlashMsForRound(_round)} ms · ${_choiceCountForRound(_round)} choices',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _cueIcon!.icon,
                      size: max(52.0, 90.0 - (_round - 1) * 4.5),
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cueIcon!.label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                )
              else if (_phase == _SnapPhase.picking && _choices.isNotEmpty)
                Builder(
                  builder: (context) {
                    final n = _choices.length;
                    final crossAxis = n <= 4 ? 2 : (n <= 6 ? 3 : 4);
                    final iconSz = n <= 4 ? 40.0 : (n <= 6 ? 36.0 : 32.0);
                    return Column(
                      children: [
                        Text(
                          'TAP THE MATCH',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: scheme.primary,
                          ),
                        ),
                        if (_wrongPenaltyThisRound > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Penalty +$_wrongPenaltyThisRound ms',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
                          ),
                        ],
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxis,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.12,
                          children: [
                            for (final c in _choices)
                              Material(
                                color: scheme.primaryContainer.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _onPick(c),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(c.icon, size: iconSz, color: scheme.primary),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.label,
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                )
              else if (_phase == _SnapPhase.betweenPlayers)
                FilledButton(
                  onPressed: _nextPlayerStart,
                  child: const Text('START NEXT PLAYER'),
                )
              else if (_phase == _SnapPhase.setup)
                FilledButton(
                  onPressed: ready ? _startRun : null,
                  child: const Text('START MATCH'),
                ),
              if (_phase == _SnapPhase.finished) ...[
                const SizedBox(height: 12),
                if (!_online) ...[
                  ...() {
                    final best = _playerTotals.reduce(min);
                    final w = [for (var i = 0; i < _players; i++) if (_playerTotals[i] == best) i];
                    final msg = w.length == 1
                        ? 'Winner: ${_playerLabel(w.first)} (${_playerTotals[w.first]} ms)'
                        : 'Tie at $best ms: ${w.map(_playerLabel).join(', ')}';
                    return [
                      Text(msg, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                    ];
                  }(),
                ] else
                  Text(
                    'Total: ${_playerTotals.isNotEmpty ? _playerTotals[0] : 0} ms',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetMatch,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('PLAY AGAIN'),
                ),
              ],
            ],
          ),
        ),
        if (_phase == _SnapPhase.finished) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ConfettiWidget(
              confettiController: _confetti!,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 16,
              shouldLoop: false,
            ),
          ),
        ],
        if (_online && ready) ...[
          Text('Room board', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (_leaderboard.isEmpty)
            Text('No scores yet.', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
          else
            for (final row in _leaderboard)
              ListTile(
                dense: true,
                title: Text(row.username),
                trailing: Text(
                  '${row.meta['total_ms'] ?? '—'} ms',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
        ],
        if (!_online && _phase != _SnapPhase.setup) ...[
          const SizedBox(height: 16),
          Text('Totals', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          for (var i = 0; i < _players; i++)
            ListTile(
              dense: true,
              title: Text(_playerLabel(i)),
              trailing: Text(
                _playerTotals[i] > 0 ? '${_playerTotals[i]} ms' : '—',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ],
    );
  }
}
