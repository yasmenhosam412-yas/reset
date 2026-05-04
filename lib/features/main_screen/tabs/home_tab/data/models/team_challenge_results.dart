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

/// Single-stat change from squad spar (server-picked slot + stat).
class TeamSquadSparStatDelta {
  const TeamSquadSparStatDelta({
    required this.slotIndex,
    required this.statKey,
    required this.before,
    required this.after,
  });

  final int slotIndex;
  final String statKey;
  final int before;
  final int after;
}

/// Result of [claim_team_squad_spar] (Power race total vs a friend, once per pair per UTC day).
class TeamSquadSparResult {
  const TeamSquadSparResult({
    required this.outcome,
    required this.myScore,
    required this.opponentScore,
    required this.pointsAwarded,
    required this.balanceAfter,
    this.squadJson,
    this.statBonus,
    this.statPenalty,
  });

  /// `win`, `lose`, or `tie`.
  final String outcome;
  final int myScore;
  final int opponentScore;
  final int pointsAwarded;
  final int balanceAfter;

  /// Updated profile `team_squad` after spar stat swing (when present).
  final Map<String, dynamic>? squadJson;

  /// Win: +1 random stat below 99.
  final TeamSquadSparStatDelta? statBonus;

  /// Loss: −1 random stat above 40.
  final TeamSquadSparStatDelta? statPenalty;
}

/// Result of [claim_team_academy_scrim] — daily solo scrim vs a bot side; points only, no stat changes.
class TeamAcademyScrimResult {
  const TeamAcademyScrimResult({
    required this.outcome,
    required this.myScore,
    required this.opponentScore,
    required this.opponentName,
    required this.pointsAwarded,
    required this.balanceAfter,
  });

  /// `win`, `lose`, or `tie`.
  final String outcome;
  final int myScore;
  final int opponentScore;
  final String opponentName;
  final int pointsAwarded;
  final int balanceAfter;
}
