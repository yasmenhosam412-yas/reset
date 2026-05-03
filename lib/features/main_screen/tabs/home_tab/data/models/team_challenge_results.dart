class TeamChallengeClaimResult {
  const TeamChallengeClaimResult({
    required this.pointsAwarded,
    required this.balanceAfter,
  });

  final int pointsAwarded;
  final int balanceAfter;
}

class TeamTrainPlayerResult {
  const TeamTrainPlayerResult({
    required this.balanceAfter,
    required this.squadJson,
  });

  final int balanceAfter;
  final Map<String, dynamic> squadJson;
}
