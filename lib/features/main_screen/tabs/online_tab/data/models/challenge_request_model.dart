import 'package:new_project/features/main_screen/tabs/online_tab/domain/entities/challenge_request_entity.dart';

/// Maps rows from `game_challenges` (Supabase) for the online tab.
class ChallengeRequestModel extends ChallengeRequestEntity {
  const ChallengeRequestModel({
    super.id,
    required super.fromId,
    required super.toId,
    required super.status,
    required super.gameId,
    super.createdAt,
    super.completedAt,
    super.winnerUserId,
    super.fromReady,
    super.toReady,
  });

  factory ChallengeRequestModel.fromJson(Map<String, dynamic> json) {
    return ChallengeRequestModel(
      id: json['id']?.toString(),
      fromId: json['from_user_id']?.toString() ?? '',
      toId: json['to_user_id']?.toString() ?? '',
      status: _normalizeRowStatus(json['status']),
      gameId: (json['game_id'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      completedAt: _parseDateTime(json['completed_at']),
      winnerUserId: _parseWinnerUserId(json['online_challenge_skill_rewards']),
      fromReady: _parseBool(json['from_ready']),
      toReady: _parseBool(json['to_ready']),
    );
  }

  static String _normalizeRowStatus(dynamic raw) {
    final s = raw?.toString().trim().toLowerCase() ?? '';
    return s.isEmpty ? 'pending' : s;
  }

  ChallengeRequestModel copyWith({
    String? id,
    String? fromId,
    String? toId,
    String? status,
    int? gameId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? winnerUserId,
    bool? fromReady,
    bool? toReady,
  }) {
    return ChallengeRequestModel(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      status: status ?? this.status,
      gameId: gameId ?? this.gameId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      winnerUserId: winnerUserId ?? this.winnerUserId,
      fromReady: fromReady ?? this.fromReady,
      toReady: toReady ?? this.toReady,
    );
  }

  static String? _parseWinnerUserId(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      if (raw.isEmpty) return null;
      final first = raw.first;
      if (first is Map) {
        final w = first['winner_user_id']?.toString().trim() ?? '';
        return w.isEmpty ? null : w;
      }
      return null;
    }
    if (raw is Map) {
      final w = raw['winner_user_id']?.toString().trim() ?? '';
      return w.isEmpty ? null : w;
    }
    return null;
  }

  static bool _parseBool(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.toLowerCase();
      return s == 'true' || s == 't' || s == '1';
    }
    return false;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
