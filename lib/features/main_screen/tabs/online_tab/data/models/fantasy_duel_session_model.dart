/// Row from `fantasy_duel_sessions` (trio = ordered card ids, length 3).
class FantasyDuelSessionModel {
  const FantasyDuelSessionModel({
    required this.challengeId,
    required this.deckSeed,
    this.fromTrio,
    this.toTrio,
    this.roundNumber = 1,
    this.fromMatchWins = 0,
    this.toMatchWins = 0,
    this.matchComplete = false,
  });

  final String challengeId;
  final int deckSeed;
  final List<int>? fromTrio;
  final List<int>? toTrio;

  /// Current round index (1-based), aligned with server `round_number`.
  final int roundNumber;

  /// Match wins for challenge creator / invitee (first to [k] wins the duel online).
  final int fromMatchWins;
  final int toMatchWins;

  /// When true, no more picks — duel finished.
  final bool matchComplete;

  bool get bothSubmitted =>
      fromTrio != null &&
      fromTrio!.length == 3 &&
      toTrio != null &&
      toTrio!.length == 3;

  factory FantasyDuelSessionModel.fromJson(Map<String, dynamic> json) {
    return FantasyDuelSessionModel(
      challengeId: json['challenge_id'] as String,
      deckSeed: _parseInt(json['deck_seed'], 1),
      fromTrio: _parseTrio(json['from_trio']),
      toTrio: _parseTrio(json['to_trio']),
      roundNumber: _parseInt(json['round_number'], 1),
      fromMatchWins: _parseInt(json['from_match_wins'], 0),
      toMatchWins: _parseInt(json['to_match_wins'], 0),
      matchComplete: json['match_complete'] as bool? ?? false,
    );
  }

  static int _parseInt(Object? v, int d) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return d;
  }

  static List<int>? _parseTrio(Object? v) {
    if (v == null) return null;
    if (v is List) {
      return v.map((e) => (e as num).toInt()).toList(growable: false);
    }
    return null;
  }
}
