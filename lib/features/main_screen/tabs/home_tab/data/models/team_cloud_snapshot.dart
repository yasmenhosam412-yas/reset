/// Team tab cloud state: skill points, saved squad JSON, today's challenge keys.
class TeamCloudSnapshot {
  const TeamCloudSnapshot({
    required this.skillPoints,
    this.squadJson,
    this.claimedChallengeKeysToday = const {},
  });

  final int skillPoints;
  final Map<String, dynamic>? squadJson;
  final Set<String> claimedChallengeKeysToday;
}
