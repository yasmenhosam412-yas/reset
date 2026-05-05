import 'package:flutter/material.dart';

/// IDs and labels for [public.game_challenges.game_id] — must match
/// [onlineGameTitle], [OnlineGameSessionPage], and Online tab previews.
abstract final class OnlineChallengeGames {
  static const int penaltyShootout = 1;
  static const int rockPaperScissors = 2;
  static const int fantasyCards = 3;

  static const List<OnlineChallengeGameDef> all = [
    OnlineChallengeGameDef(
      id: penaltyShootout,
      title: 'Penalty shootout',
      icon: Icons.sports_soccer_rounded,
    ),
    OnlineChallengeGameDef(
      id: rockPaperScissors,
      title: 'Rock paper scissors',
      icon: Icons.balance_rounded,
    ),
    OnlineChallengeGameDef(
      id: fantasyCards,
      title: 'Fantasy cards',
      icon: Icons.auto_awesome_rounded,
    ),
  ];
}

class OnlineChallengeGameDef {
  const OnlineChallengeGameDef({
    required this.id,
    required this.title,
    required this.icon,
  });

  final int id;
  final String title;
  final IconData icon;
}
