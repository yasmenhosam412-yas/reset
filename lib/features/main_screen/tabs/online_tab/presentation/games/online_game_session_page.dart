import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout_online_config.dart';

class OnlineGameSessionPage extends StatelessWidget {
  const OnlineGameSessionPage({super.key, required this.args});

  final OnlineGameRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = onlineGameTitle(args.gameId);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Match vs ${args.opponentDisplayName}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Challenge: ${args.challengeId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _GameBody(
            gameId: args.gameId,
            scheme: scheme,
            theme: theme,
            opponentName: args.opponentDisplayName,
            challengeId: args.challengeId,
            challengeFromUserId: args.challengeFromUserId,
            challengeToUserId: args.challengeToUserId,
          ),
        ],
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
        return PenaltyShootoutGame(
          scheme: scheme,
          theme: theme,
          opponentName: opponentName,
          online: PenaltyShootoutOnlineConfig(
            challengeId: challengeId,
            fromUserId: challengeFromUserId,
            toUserId: challengeToUserId,
            repository: getIt<OnlineRepository>(),
          ),
        );
      case 2:
        return _OneVOneBody(scheme: scheme, theme: theme);
      case 3:
        return _FantasyCardsBody(scheme: scheme, theme: theme);
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

class _OneVOneBody extends StatelessWidget {
  const _OneVOneBody({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: scheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sports_esports_rounded, size: 40, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              '1v1 game',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Head-to-head session placeholder.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FantasyCardsBody extends StatelessWidget {
  const _FantasyCardsBody({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 40, color: scheme.tertiary),
            const SizedBox(height: 12),
            Text(
              'Fantasy cards',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deck / draft placeholder.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
