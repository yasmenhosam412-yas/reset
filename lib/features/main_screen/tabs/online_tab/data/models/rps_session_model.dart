/// Row from `rps_sessions` (game ID 2: rock–paper–scissors, first to 5).
class RpsSessionModel {
  const RpsSessionModel({
    required this.challengeId,
    required this.scoreFrom,
    required this.scoreTo,
    required this.fromPick,
    required this.toPick,
    required this.roundSeq,
    required this.status,
  });

  final String challengeId;
  final int scoreFrom;
  final int scoreTo;
  final String? fromPick;
  final String? toPick;
  final int roundSeq;
  final String status;

  factory RpsSessionModel.fromJson(Map<String, dynamic> json) {
    return RpsSessionModel(
      challengeId: json['challenge_id'] as String,
      scoreFrom: (json['score_from'] as num?)?.toInt() ?? 0,
      scoreTo: (json['score_to'] as num?)?.toInt() ?? 0,
      fromPick: json['from_pick'] as String?,
      toPick: json['to_pick'] as String?,
      roundSeq: (json['round_seq'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'playing',
    );
  }
}

/// Result of `submit_rps_pick` RPC.
class RpsPickSubmitResponse {
  const RpsPickSubmitResponse({
    required this.ok,
    this.error,
    required this.resolvedRound,
    this.roundWinner,
    this.session,
  });

  final bool ok;
  final String? error;
  final bool resolvedRound;
  /// `-1` draw, `0` from wins round, `1` to wins round; null if round not resolved.
  final int? roundWinner;
  final RpsSessionModel? session;

  factory RpsPickSubmitResponse.fromJson(Map<String, dynamic> json) {
    final rw = json['round_winner'];
    return RpsPickSubmitResponse(
      ok: json['ok'] == true,
      error: json['error'] as String?,
      resolvedRound: json['resolved_round'] == true,
      roundWinner: rw == null ? null : (rw as num).toInt(),
      session: json['session'] == null
          ? null
          : RpsSessionModel.fromJson(
              Map<String, dynamic>.from(json['session'] as Map),
            ),
    );
  }
}
