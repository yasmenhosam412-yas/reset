import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/widgets/tab_loading_skeletons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battle_daily_digest.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battle_digest_notifications.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battles_repository.dart';

class _BattleUi {
  const _BattleUi({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const _battleUi = [
  _BattleUi(
    id: 1,
    title: 'Cosmic dice',
    subtitle: 'One roll (1–999) per UTC day — highest wins.',
    icon: Icons.casino_rounded,
  ),
  _BattleUi(
    id: 2,
    title: 'Green-light reflex',
    subtitle: 'Wait for green, then tap — fastest reaction ranks higher.',
    icon: Icons.bolt_rounded,
  ),
  _BattleUi(
    id: 3,
    title: 'Oracle digit',
    subtitle: 'Pick a digit 0–9. A daily hash picks the winning number.',
    icon: Icons.pin_rounded,
  ),
  _BattleUi(
    id: 4,
    title: 'Five-second blitz',
    subtitle:
        'How many taps in 5 seconds? Best score today stays on the board.',
    icon: Icons.touch_app_rounded,
  ),
  _BattleUi(
    id: 5,
    title: 'Parity prophet',
    subtitle: 'The app rolls 0–99 once per day (UTC). Pick odd or even.',
    icon: Icons.balance_rounded,
  ),
];

class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  final _repo = getIt<GlobalBattlesRepository>();
  late String _periodKey;

  var _loading = true;
  final Map<int, List<GlobalBattleStanding>> _boards = {};
  final Map<int, GlobalBattleMyEntry?> _mine = {};
  String _digestPeriod = '';
  List<GlobalBattleDigestRow> _digestRows = const [];
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _periodKey = GlobalBattlesRepository.utcPeriodKey();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn) {
        unawaited(_reload());
      }
    });
    scheduleMicrotask(_reload);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      _periodKey = GlobalBattlesRepository.utcPeriodKey();
      if (_repo.isSignedIn) {
        final digest = await GlobalBattleDailyDigest.loadYesterdayDigest(_repo);
        _digestPeriod = digest.period;
        _digestRows = digest.rows;
        await GlobalBattleDigestNotifications.ensureScheduled();
      } else {
        _digestPeriod = '';
        _digestRows = const [];
      }
      for (final b in _battleUi) {
        final list = await _repo.fetchLeaderboard(
          battleId: b.id,
          periodKey: _periodKey,
        );
        final me = await _repo.fetchMyEntry(
          battleId: b.id,
          periodKey: _periodKey,
        );
        _boards[b.id] = list;
        _mine[b.id] = me;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _scoreLine(int battleId, GlobalBattleStanding s) {
    switch (battleId) {
      case 1:
        return '${s.score}';
      case 2:
        final ms = s.extras['ms'];
        return ms != null ? '$ms ms' : '${s.score}';
      case 3:
        final g = s.extras['g'];
        return g != null ? 'picked $g' : 'Entered';
      case 4:
        final t = s.extras['taps'];
        return t != null ? '$t taps' : '${s.score} taps';
      case 5:
        final p = s.extras['pick']?.toString() ?? '';
        return p.isEmpty ? 'Entered' : p;
      default:
        return '${s.score}';
    }
  }

  String? _mySummary(int battleId, GlobalBattleMyEntry? e) {
    if (e == null) return null;
    switch (battleId) {
      case 1:
        return 'Your roll: ${e.extras['r'] ?? e.score}';
      case 2:
        final ms = e.extras['ms'];
        return ms != null ? 'Your best: $ms ms' : 'Submitted';
      case 3:
        final g = e.extras['g'];
        if (g == null) return 'Submitted for today.';
        final gv = g is num ? g.toInt() : int.tryParse('$g') ?? -1;
        return 'You picked $gv. The winning digit is not shown here (fair play).';
      case 4:
        return 'Your best: ${e.extras['taps'] ?? e.score} taps';
      case 5:
        final pick = e.extras['pick']?.toString() ?? '';
        if (pick.isEmpty) return 'Submitted for today.';
        return 'You chose $pick. The hidden number is not shown here (fair play).';
      default:
        return null;
    }
  }

  Future<void> _playDice() async {
    final roll = Random().nextInt(999) + 1;
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cosmic dice'),
        content: Text('You rolled $roll. Submit for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final err = await _repo.submitCosmicDice(periodKey: _periodKey, roll: roll);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Locked in: $roll for $_periodKey (UTC).')),
      );
    }
    await _reload();
  }

  Future<void> _playReflex() async {
    final ms = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ReflexDialog(),
    );
    if (ms == null || !mounted) return;
    final err = await _repo.submitReflex(periodKey: _periodKey, reactionMs: ms);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: $ms ms')));
    }
    await _reload();
  }

  Future<void> _playOracle() async {
    if (!mounted) return;
    final pick = await showDialog<int>(
      context: context,
      builder: (ctx) {
        var local = 5;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Oracle digit'),
              content: SizedBox(
                width: 280,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(10, (i) {
                    return ChoiceChip(
                      label: Text('$i'),
                      selected: local == i,
                      onSelected: (_) => setLocal(() => local = i),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, local),
                  child: const Text('Lock pick'),
                ),
              ],
            );
          },
        );
      },
    );
    if (pick == null || !mounted) return;
    final err = await _repo.submitOracleDigit(
      periodKey: _periodKey,
      guess: pick,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pick saved. The oracle digit stays hidden here so everyone plays fair.',
          ),
        ),
      );
    }
    await _reload();
  }

  Future<void> _playBlitz() async {
    final taps = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _BlitzDialog(),
    );
    if (taps == null || !mounted) return;
    final err = await _repo.submitBlitzTaps(periodKey: _periodKey, taps: taps);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$taps taps saved.')));
    }
    await _reload();
  }

  Future<void> _playParity() async {
    final odd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parity prophet'),
        content: const Text('Was today’s hidden number odd or even?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odd'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Even'),
          ),
        ],
      ),
    );
    if (odd == null || !mounted) return;
    final err = await _repo.submitParityPick(
      periodKey: _periodKey,
      pickOdd: odd,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choice saved. The daily number stays hidden here so everyone plays fair.',
          ),
        ),
      );
    }
    await _reload();
  }

  void _playBattle(int id) {
    switch (id) {
      case 1:
        unawaited(_playDice());
      case 2:
        unawaited(_playReflex());
      case 3:
        unawaited(_playOracle());
      case 4:
        unawaited(_playBlitz());
      case 5:
        unawaited(_playParity());
    }
  }

  bool _canPlay(int id) {
    final me = _mine[id];
    if (id == 2 || id == 4) return true;
    return me == null;
  }

  String _playLabel(int id) {
    final me = _mine[id];
    if (id == 2) return me == null ? 'Play' : 'Try again';
    if (id == 4) return me == null ? 'Play' : 'Beat record';
    if (me != null) return 'Done today';
    return 'Play';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!_repo.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team battles')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in to join today’s global battles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Global battles'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => unawaited(_reload()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? TabLoadingSkeletons.teamGlobalBattles(context)
          : RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_digestRows.isNotEmpty) ...[
                          _DailyChampionsPanel(
                            periodKey: _digestPeriod,
                            rows: _digestRows,
                            scoreLine: _scoreLine,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'UTC day $_periodKey · everyone in the app shares these boards.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._battleUi.map(
                          (b) => _BattleCard(
                            def: b,
                            standings: _boards[b.id] ?? const [],
                            mySummary: _mySummary(b.id, _mine[b.id]),
                            scoreLine: (s) => _scoreLine(b.id, s),
                            playLabel: _playLabel(b.id),
                            canPlay: _canPlay(b.id),
                            onPlay: () => _playBattle(b.id),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DailyChampionsPanel extends StatelessWidget {
  const _DailyChampionsPanel({
    required this.periodKey,
    required this.rows,
    required this.scoreLine,
  });

  final String periodKey;
  final List<GlobalBattleDigestRow> rows;
  final String Function(int battleId, GlobalBattleStanding s) scoreLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: scheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yesterday\'s champions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UTC day $periodKey · top score per battle. '
                        'A notification goes out every day at 12:00 PM on this device.',
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
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i].champion?.username ?? '—',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: rows[i].champion != null
                            ? scheme.primary
                            : scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              if (rows[i].champion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    scoreLine(rows[i].battleId, rows[i].champion!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.def,
    required this.standings,
    required this.mySummary,
    required this.scoreLine,
    required this.playLabel,
    required this.canPlay,
    required this.onPlay,
  });

  final _BattleUi def;
  final List<GlobalBattleStanding> standings;
  final String? mySummary;
  final String Function(GlobalBattleStanding) scoreLine;
  final String playLabel;
  final bool canPlay;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(def.icon, color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        def.subtitle,
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
            if (mySummary != null) ...[
              const SizedBox(height: 12),
              Text(
                mySummary!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: canPlay ? onPlay : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(playLabel),
            ),
            const SizedBox(height: 14),
            Text(
              'Top players',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (standings.isEmpty)
              Text(
                'No scores yet — be the first.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              )
            else
              ...List.generate(standings.length.clamp(0, 12), (i) {
                final s = standings[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.username,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        scoreLine(s),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

enum _ReflexPhase { wait, go }

class _ReflexDialog extends StatefulWidget {
  const _ReflexDialog();

  @override
  State<_ReflexDialog> createState() => _ReflexDialogState();
}

class _ReflexDialogState extends State<_ReflexDialog> {
  _ReflexPhase _phase = _ReflexPhase.wait;
  DateTime? _greenAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delayMs = 800 + Random().nextInt(2400);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _phase = _ReflexPhase.go;
        _greenAt = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTap() {
    if (_phase == _ReflexPhase.wait) return;
    final t = _greenAt;
    if (t == null) return;
    final ms = DateTime.now().difference(t).inMilliseconds;
    Navigator.of(context).pop(ms.clamp(1, 9999));
  }

  @override
  Widget build(BuildContext context) {
    final go = _phase == _ReflexPhase.go;
    return AlertDialog(
      title: const Text('Green-light reflex'),
      content: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 260,
          height: 160,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: go ? Colors.green.shade600 : Colors.red.shade800,
            ),
            child: Center(
              child: Text(
                go ? 'TAP!' : 'Wait…',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abort'),
        ),
      ],
    );
  }
}

class _BlitzDialog extends StatefulWidget {
  const _BlitzDialog();

  @override
  State<_BlitzDialog> createState() => _BlitzDialogState();
}

class _BlitzDialogState extends State<_BlitzDialog> {
  int _count = 0;
  var _remaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        Navigator.of(context).pop(_count);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Five-second blitz'),
      content: GestureDetector(
        onTap: () => setState(() => _count++),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 220,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_count',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_remaining s left — tap anywhere',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
