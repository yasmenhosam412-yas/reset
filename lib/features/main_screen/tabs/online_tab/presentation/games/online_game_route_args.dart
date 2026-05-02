class OnlineGameRouteArgs {
  const OnlineGameRouteArgs({
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
