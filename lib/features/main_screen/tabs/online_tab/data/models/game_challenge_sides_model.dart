/// `from_user_id` / `to_user_id` from `game_challenges` for a single row.
class GameChallengeSidesModel {
  const GameChallengeSidesModel({
    required this.fromUserId,
    required this.toUserId,
  });

  final String fromUserId;
  final String toUserId;

  factory GameChallengeSidesModel.fromJson(Map<String, dynamic> json) {
    return GameChallengeSidesModel(
      fromUserId: json['from_user_id']?.toString() ?? '',
      toUserId: json['to_user_id']?.toString() ?? '',
    );
  }
}
