class ChallengeRequestEntity {
  const ChallengeRequestEntity({
    this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    required this.gameId,
    this.createdAt,
    this.completedAt,
    this.winnerUserId,
    this.fromReady = false,
    this.toReady = false,
  });

  final String? id;
  final String fromId;
  final String toId;
  final String status;
  final int gameId;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? winnerUserId;
  final bool fromReady;
  final bool toReady;
}
