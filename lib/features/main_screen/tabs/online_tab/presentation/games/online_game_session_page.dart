import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_game_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_online_config.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_duel_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_duel_online_config.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rim_shot/rim_shot_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rim_shot/rim_shot_online_config.dart';

class OnlineGameSessionPage extends StatefulWidget {
  const OnlineGameSessionPage({super.key, required this.args});

  final OnlineGameRouteArgs args;

  @override
  State<OnlineGameSessionPage> createState() => _OnlineGameSessionPageState();
}

class _OnlineGameSessionPageState extends State<OnlineGameSessionPage> {
  bool _exitInFlight = false;

  Future<void> _leaveMatchAndPop() async {
    if (_exitInFlight) return;
    _exitInFlight = true;
    final r = await getIt<OnlineRepository>().abandonOnlineGameSession(
      challengeId: widget.args.challengeId,
    );
    r.fold((_) {}, (_) {});
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = onlineGameTitle(widget.args.gameId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_leaveMatchAndPop());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _leaveMatchAndPop,
          ),
          title: Text(title),
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Match vs ${widget.args.opponentDisplayName}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Challenge: ${widget.args.challengeId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _GameBody(
              gameId: widget.args.gameId,
              scheme: scheme,
              theme: theme,
              opponentName: widget.args.opponentDisplayName,
              challengeId: widget.args.challengeId,
              challengeFromUserId: widget.args.challengeFromUserId,
              challengeToUserId: widget.args.challengeToUserId,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.gameId,
    required this.scheme,
    required this.theme,
    required this.opponentName,
    required this.challengeId,
    required this.challengeFromUserId,
    required this.challengeToUserId,
  });

  final int gameId;
  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final String challengeId;
  final String challengeFromUserId;
  final String challengeToUserId;

  @override
  Widget build(BuildContext context) {
    switch (gameId) {
      case 1:
        return _PenaltyOnlineShootoutSlot(
          scheme: scheme,
          theme: theme,
          opponentName: opponentName,
          challengeId: challengeId,
          challengeFromUserId: challengeFromUserId,
          challengeToUserId: challengeToUserId,
        );
      case 2:
        return _RimShotOnlineSlot(
          scheme: scheme,
          theme: theme,
          opponentName: opponentName,
          challengeId: challengeId,
          challengeFromUserId: challengeFromUserId,
          challengeToUserId: challengeToUserId,
        );
      case 3:
        return _FantasyDuelOnlineSlot(
          scheme: scheme,
          theme: theme,
          opponentName: opponentName,
          challengeId: challengeId,
          challengeFromUserId: challengeFromUserId,
          challengeToUserId: challengeToUserId,
        );
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No screen for game ID $gameId yet.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        );
    }
  }
}

class _PenaltyOnlineShootoutSlot extends StatefulWidget {
  const _PenaltyOnlineShootoutSlot({
    required this.scheme,
    required this.theme,
    required this.opponentName,
    required this.challengeId,
    required this.challengeFromUserId,
    required this.challengeToUserId,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final String challengeId;
  final String challengeFromUserId;
  final String challengeToUserId;

  @override
  State<_PenaltyOnlineShootoutSlot> createState() =>
      _PenaltyOnlineShootoutSlotState();
}

class _PenaltyOnlineShootoutSlotState extends State<_PenaltyOnlineShootoutSlot> {
  int _bootKey = 0;

  @override
  Widget build(BuildContext context) {
    return PenaltyShootoutGame(
      key: ValueKey(_bootKey),
      scheme: widget.scheme,
      theme: widget.theme,
      opponentName: widget.opponentName,
      online: PenaltyShootoutOnlineConfig(
        challengeId: widget.challengeId,
        fromUserId: widget.challengeFromUserId,
        toUserId: widget.challengeToUserId,
        repository: getIt<OnlineRepository>(),
      ),
      onPlayAgain: () => setState(() => _bootKey++),
    );
  }
}

class _RimShotOnlineSlot extends StatefulWidget {
  const _RimShotOnlineSlot({
    required this.scheme,
    required this.theme,
    required this.opponentName,
    required this.challengeId,
    required this.challengeFromUserId,
    required this.challengeToUserId,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final String challengeId;
  final String challengeFromUserId;
  final String challengeToUserId;

  @override
  State<_RimShotOnlineSlot> createState() => _RimShotOnlineSlotState();
}

class _RimShotOnlineSlotState extends State<_RimShotOnlineSlot> {
  int _bootKey = 0;

  @override
  Widget build(BuildContext context) {
    return RimShotGame(
      key: ValueKey(_bootKey),
      scheme: widget.scheme,
      theme: widget.theme,
      opponentName: widget.opponentName,
      online: RimShotOnlineConfig(
        challengeId: widget.challengeId,
        fromUserId: widget.challengeFromUserId,
        toUserId: widget.challengeToUserId,
        repository: getIt<OnlineRepository>(),
      ),
      onPlayAgain: () => setState(() => _bootKey++),
    );
  }
}

class _FantasyDuelOnlineSlot extends StatefulWidget {
  const _FantasyDuelOnlineSlot({
    required this.scheme,
    required this.theme,
    required this.opponentName,
    required this.challengeId,
    required this.challengeFromUserId,
    required this.challengeToUserId,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String opponentName;
  final String challengeId;
  final String challengeFromUserId;
  final String challengeToUserId;

  @override
  State<_FantasyDuelOnlineSlot> createState() => _FantasyDuelOnlineSlotState();
}

class _FantasyDuelOnlineSlotState extends State<_FantasyDuelOnlineSlot> {
  int _bootKey = 0;

  @override
  Widget build(BuildContext context) {
    return FantasyDuelGame(
      key: ValueKey(_bootKey),
      scheme: widget.scheme,
      theme: widget.theme,
      opponentName: widget.opponentName,
      online: FantasyDuelOnlineConfig(
        challengeId: widget.challengeId,
        fromUserId: widget.challengeFromUserId,
        toUserId: widget.challengeToUserId,
        repository: getIt<OnlineRepository>(),
      ),
      onPlayAgain: () => setState(() => _bootKey++),
    );
  }
}
