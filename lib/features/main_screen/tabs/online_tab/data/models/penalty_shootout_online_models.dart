/// Row from `penalty_shootout_sessions`.
class PenaltyShootoutSessionModel {
  const PenaltyShootoutSessionModel({
    required this.challengeId,
    required this.roundIndex,
    required this.fromGoals,
    required this.toGoals,
  });

  final String challengeId;
  final int roundIndex;
  final int fromGoals;
  final int toGoals;

  factory PenaltyShootoutSessionModel.fromJson(Map<String, dynamic> json) {
    return PenaltyShootoutSessionModel(
      challengeId: json['challenge_id']?.toString() ?? '',
      roundIndex: (json['round_index'] as num?)?.toInt() ?? 0,
      fromGoals: (json['from_goals'] as num?)?.toInt() ?? 0,
      toGoals: (json['to_goals'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Row from `penalty_round_picks`.
class PenaltyRoundPickModel {
  const PenaltyRoundPickModel({
    required this.userId,
    required this.pickKind,
    required this.direction,
    this.power,
  });

  final String userId;
  final String pickKind;
  final int direction;
  final double? power;

  factory PenaltyRoundPickModel.fromJson(Map<String, dynamic> json) {
    return PenaltyRoundPickModel(
      userId: json['user_id']?.toString() ?? '',
      pickKind: json['pick_kind']?.toString() ?? '',
      direction: _parseSmallInt(json['direction']),
      power: _parseOptionalDouble(json['power']),
    );
  }

  static int _parseSmallInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  static double? _parseOptionalDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }
}
