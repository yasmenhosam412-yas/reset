import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';

enum OnlineStatus {
  initial,
  loading,
  loaded,
  failure,
}

enum OnlineSuccessType {
  challengeSent,
  leftMatch,
}

/// Shown after the user accepts an invite: opponent + game + ready CTA.
class AcceptedMatchPreview {
  const AcceptedMatchPreview({
    required this.challengeId,
    required this.opponentDisplayName,
    this.opponentAvatarUrl,
    required this.gameId,
  });

  final String challengeId;
  final String opponentDisplayName;
  final String? opponentAvatarUrl;
  final int gameId;
}

/// Navigates to [OnlineGameSessionPage] when both players are ready.
class OnlineGameLaunch {
  const OnlineGameLaunch({
    required this.challengeId,
    required this.gameId,
    required this.opponentUserId,
    required this.opponentDisplayName,
    required this.challengeFromUserId,
    required this.challengeToUserId,
  });

  final String challengeId;
  final int gameId;
  final String opponentUserId;
  final String opponentDisplayName;
  final String challengeFromUserId;
  final String challengeToUserId;
}

class OnlineState {
  const OnlineState({
    required this.status,
    this.currentUserId,
    this.friends = const [],
    this.challenges = const [],
    this.errorMessage,
    this.successMessage,
    this.successType,
    this.successName,
    this.successGameId,
    this.pendingMatchLobby,
    this.pendingGameLaunch,
  });

  factory OnlineState.initial() {
    return const OnlineState(status: OnlineStatus.initial);
  }

  final OnlineStatus status;
  final String? currentUserId;
  final List<UserModel> friends;
  final List<ChallengeRequestModel> challenges;
  final String? errorMessage;
  final String? successMessage;
  final OnlineSuccessType? successType;
  final String? successName;
  final int? successGameId;
  final AcceptedMatchPreview? pendingMatchLobby;
  final OnlineGameLaunch? pendingGameLaunch;

  OnlineState copyWith({
    OnlineStatus? status,
    String? currentUserId,
    List<UserModel>? friends,
    List<ChallengeRequestModel>? challenges,
    String? errorMessage,
    String? successMessage,
    OnlineSuccessType? successType,
    String? successName,
    int? successGameId,
    AcceptedMatchPreview? pendingMatchLobby,
    OnlineGameLaunch? pendingGameLaunch,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearPendingMatchLobby = false,
    bool clearPendingGameLaunch = false,
  }) {
    return OnlineState(
      status: status ?? this.status,
      currentUserId: currentUserId ?? this.currentUserId,
      friends: friends ?? this.friends,
      challenges: challenges ?? this.challenges,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      successType: clearSuccess ? null : (successType ?? this.successType),
      successName: clearSuccess ? null : (successName ?? this.successName),
      successGameId: clearSuccess ? null : (successGameId ?? this.successGameId),
      pendingMatchLobby: clearPendingMatchLobby
          ? null
          : (pendingMatchLobby ?? this.pendingMatchLobby),
      pendingGameLaunch: clearPendingGameLaunch
          ? null
          : (pendingGameLaunch ?? this.pendingGameLaunch),
    );
  }
}
