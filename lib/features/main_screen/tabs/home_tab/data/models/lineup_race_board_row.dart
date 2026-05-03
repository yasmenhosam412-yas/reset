class LineupRaceBoardRow {
  const LineupRaceBoardRow({
    required this.userId,
    required this.score,
    required this.teamName,
    this.username,
    this.avatarUrl,
    this.submittedAt,
  });

  final String userId;
  final int score;
  final String teamName;
  final String? username;
  final String? avatarUrl;
  final DateTime? submittedAt;
}
