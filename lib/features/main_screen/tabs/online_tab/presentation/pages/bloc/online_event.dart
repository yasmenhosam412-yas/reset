import 'package:new_project/features/authentication/data/models/user_model.dart';

abstract class OnlineEvent {}

final class OnlineLoadRequested extends OnlineEvent {}

/// Postgres realtime fired for `game_challenges`; refresh list without full load UX.
final class OnlineChallengesRealtimeUpdated extends OnlineEvent {}

final class OnlineSendChallengeRequested extends OnlineEvent {
  OnlineSendChallengeRequested({
    required this.friend,
    required this.gameId,
  });

  final UserModel friend;
  final int gameId;
}

final class OnlineChallengeDecisionRequested extends OnlineEvent {
  OnlineChallengeDecisionRequested({
    required this.challengeId,
    required this.accept,
    this.opponentDisplayName,
    this.opponentAvatarUrl,
    this.gameId,
  });

  final String challengeId;
  final bool accept;
  final String? opponentDisplayName;
  final String? opponentAvatarUrl;
  final int? gameId;
}

final class OnlinePendingMatchLobbyDismissed extends OnlineEvent {}

final class OnlineChallengeReadyRequested extends OnlineEvent {
  OnlineChallengeReadyRequested({required this.challengeId});

  final String challengeId;
}

final class OnlineGameLaunchConsumed extends OnlineEvent {}
final class ResetOnlineTab extends OnlineEvent {}
