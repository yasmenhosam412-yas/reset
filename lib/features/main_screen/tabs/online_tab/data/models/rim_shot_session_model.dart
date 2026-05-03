/// Row from `rim_shot_sessions` (free-throw duel state).
class RimShotSessionModel {
  const RimShotSessionModel({
    required this.challengeId,
    required this.scoreFrom,
    required this.scoreTo,
    required this.whoseTurn,
    required this.roundSeq,
    required this.status,
    this.lastPower,
    this.lastAim,
    this.lastMade,
  });

  final String challengeId;
  final int scoreFrom;
  final int scoreTo;

  /// `'from'` = challenge creator shoots next (when [status] is playing).
  final String whoseTurn;
  final int roundSeq;
  final String status;
  final double? lastPower;
  final double? lastAim;
  final bool? lastMade;

  bool get isDone => status == 'done';

  factory RimShotSessionModel.fromJson(Map<String, dynamic> json) {
    return RimShotSessionModel(
      challengeId: json['challenge_id'] as String,
      scoreFrom: _parseInt(json['score_from'], 0),
      scoreTo: _parseInt(json['score_to'], 0),
      whoseTurn: (json['whose_turn'] as String?) ?? 'from',
      roundSeq: _parseInt(json['round_seq'], 0),
      status: (json['status'] as String?) ?? 'playing',
      lastPower: (json['last_power'] as num?)?.toDouble(),
      lastAim: (json['last_aim'] as num?)?.toDouble(),
      lastMade: json['last_made'] as bool?,
    );
  }

  static int _parseInt(Object? v, int d) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return d;
  }
}
