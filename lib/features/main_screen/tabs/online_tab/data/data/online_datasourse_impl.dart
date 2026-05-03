import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/data/online_datasourse.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rim_shot_session_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineDatasourseImpl implements OnlineDatasourse {
  OnlineDatasourseImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  @override
  Future<List<ChallengeRequestModel>> getChallenges() async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) return const [];

    final response = await supabaseClient
        .from(HomeTable.gameChallenges)
        .select()
        .or(
          '${GameChallengeCols.fromUserId}.eq.$uid,'
          '${GameChallengeCols.toUserId}.eq.$uid',
        )
        .order(PostCols.createdAt, ascending: false);

    final rows = response as List<dynamic>;
    return rows
        .map(
          (e) => ChallengeRequestModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<UserModel>> getFriends() async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) return const [];

    final response = await supabaseClient
        .from(HomeTable.friendRequests)
        .select(
          '${FriendRequestCols.fromUserId}, ${FriendRequestCols.toUserId}',
        )
        .eq(FriendRequestCols.status, FriendRequestStatus.accepted)
        .or(
          '${FriendRequestCols.fromUserId}.eq.$uid,'
          '${FriendRequestCols.toUserId}.eq.$uid',
        );

    final rows = response as List<dynamic>;
    final friendIds = <String>{};
    for (final e in rows) {
      final m = Map<String, dynamic>.from(e as Map);
      final from =
          m[FriendRequestCols.fromUserId]?.toString() ?? '';
      final to = m[FriendRequestCols.toUserId]?.toString() ?? '';
      if (from == uid && to.isNotEmpty) {
        friendIds.add(to);
      } else if (to == uid && from.isNotEmpty) {
        friendIds.add(from);
      }
    }

    if (friendIds.isEmpty) return const [];

    final profiles = await supabaseClient
        .from(HomeTable.profiles)
        .select(
          '${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}',
        )
        .inFilter(ProfileCols.id, friendIds.toList());

    final plist = profiles as List<dynamic>;
    final users = plist
        .map(
          (e) => UserModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);

    users.sort(
      (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
    );
    return users;
  }

  @override
  Future<void> changeChallengeStatus({
    required String challengeId,
    required String status,
  }) async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot update challenge while signed out.');
    }
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final normalized = _normalizeChallengeStatus(status);

    await supabaseClient
        .from(HomeTable.gameChallenges)
        .update({GameChallengeCols.status: normalized})
        .eq(GameChallengeCols.id, id);
  }

  @override
  Future<bool> setChallengeReady({required String challengeId}) async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot update challenge while signed out.');
    }
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final row = await supabaseClient
        .from(HomeTable.gameChallenges)
        .select(
          '${GameChallengeCols.fromUserId}, ${GameChallengeCols.toUserId}',
        )
        .eq(GameChallengeCols.id, id)
        .maybeSingle();

    if (row == null) {
      throw StateError('Challenge not found.');
    }

    final m = Map<String, dynamic>.from(row as Map);
    final from = m[GameChallengeCols.fromUserId]?.toString() ?? '';
    final to = m[GameChallengeCols.toUserId]?.toString() ?? '';

    final patch = <String, dynamic>{};
    if (from == uid) {
      patch[GameChallengeCols.fromReady] = true;
    } else if (to == uid) {
      patch[GameChallengeCols.toReady] = true;
    } else {
      throw StateError('Not a participant in this challenge.');
    }

    await supabaseClient
        .from(HomeTable.gameChallenges)
        .update(patch)
        .eq(GameChallengeCols.id, id);

    final after = await supabaseClient
        .from(HomeTable.gameChallenges)
        .select(
          '${GameChallengeCols.fromReady}, ${GameChallengeCols.toReady}',
        )
        .eq(GameChallengeCols.id, id)
        .single();

    final am = Map<String, dynamic>.from(after as Map);
    final fr = _asBool(am[GameChallengeCols.fromReady]);
    final tr = _asBool(am[GameChallengeCols.toReady]);
    return fr && tr;
  }

  static bool _asBool(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.toLowerCase();
      return s == 'true' || s == 't' || s == '1';
    }
    return false;
  }

  static String _normalizeChallengeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'accept':
      case 'accepted':
        return 'accepted';
      case 'reject':
      case 'rejected':
      case 'decline':
      case 'declined':
        return 'declined';
      case 'pending':
      case 'expired':
      case 'cancelled':
      case 'complete':
      case 'completed':
        return s == 'complete' ? 'completed' : s;
      default:
        throw ArgumentError(
          'Invalid challenge status: $raw '
          '(use accepted, declined, pending, expired, cancelled, or completed)',
        );
    }
  }

  @override
  Future<void> ensurePenaltyShootoutSession({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'ensure_penalty_session',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<PenaltyShootoutSessionModel?> fetchPenaltyShootoutSession({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;

    final row = await supabaseClient
        .from(HomeTable.penaltyShootoutSessions)
        .select()
        .eq(PenaltySessionCols.challengeId, id)
        .maybeSingle();

    if (row == null) return null;
    return PenaltyShootoutSessionModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<void> upsertPenaltyRoundPick({
    required String challengeId,
    required int roundIndex,
    required String pickKind,
    required int direction,
    double? power,
  }) async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot submit pick while signed out.');
    }
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final payload = <String, dynamic>{
      PenaltyPickCols.challengeId: id,
      PenaltyPickCols.roundIndex: roundIndex,
      PenaltyPickCols.userId: uid,
      PenaltyPickCols.pickKind: pickKind,
      PenaltyPickCols.direction: direction,
      PenaltyPickCols.power: power,
    };

    await supabaseClient.from(HomeTable.penaltyRoundPicks).upsert(
      payload,
      onConflict: 'challenge_id,round_index,user_id',
    );
  }

  @override
  Future<List<PenaltyRoundPickModel>> fetchPenaltyRoundPicks({
    required String challengeId,
    required int roundIndex,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return const [];

    final response = await supabaseClient
        .from(HomeTable.penaltyRoundPicks)
        .select()
        .eq(PenaltyPickCols.challengeId, id)
        .eq(PenaltyPickCols.roundIndex, roundIndex);

    final rows = response as List<dynamic>;
    return rows
        .map(
          (e) => PenaltyRoundPickModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> advancePenaltyRound({
    required String challengeId,
    required int expectedRoundIndex,
    required int fromGoalsDelta,
    required int toGoalsDelta,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final raw = await supabaseClient.rpc<dynamic>(
      'advance_penalty_round',
      params: {
        'p_challenge_id': id,
        'p_expected_round': expectedRoundIndex,
        'p_from_delta': fromGoalsDelta,
        'p_to_delta': toGoalsDelta,
      },
    );

    if (raw is bool) return raw;
    if (raw == null) return false;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == 't' || s == '1';
  }

  @override
  Future<GameChallengeSidesModel?> fetchGameChallengeSides({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;

    final row = await supabaseClient
        .from(HomeTable.gameChallenges)
        .select(
          '${GameChallengeCols.fromUserId}, ${GameChallengeCols.toUserId}',
        )
        .eq(GameChallengeCols.id, id)
        .maybeSingle();

    if (row == null) return null;
    return GameChallengeSidesModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<void> finishPenaltyMatchCleanup({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'finish_penalty_match_cleanup',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<void> abandonOnlineGameSession({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'abandon_online_game_session',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<void> ensureRimShotSession({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'ensure_rim_shot_session',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<RimShotSessionModel?> fetchRimShotSession({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;

    final row = await supabaseClient
        .from(HomeTable.rimShotSessions)
        .select()
        .eq(RimShotSessionCols.challengeId, id)
        .maybeSingle();

    if (row == null) return null;
    return RimShotSessionModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<RimShotSessionModel?> tryApplyRimShotTurn({
    required String challengeId,
    required String expectedTurn,
    required double power,
    required double aim,
    required bool made,
    required int nextScoreFrom,
    required int nextScoreTo,
    required String nextTurn,
    required String status,
    required int nextRoundSeq,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final payload = <String, dynamic>{
      RimShotSessionCols.scoreFrom: nextScoreFrom,
      RimShotSessionCols.scoreTo: nextScoreTo,
      RimShotSessionCols.whoseTurn: nextTurn,
      RimShotSessionCols.roundSeq: nextRoundSeq,
      RimShotSessionCols.lastPower: power,
      RimShotSessionCols.lastAim: aim,
      RimShotSessionCols.lastMade: made,
      RimShotSessionCols.status: status,
      RimShotSessionCols.updatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    final row = await supabaseClient
        .from(HomeTable.rimShotSessions)
        .update(payload)
        .eq(RimShotSessionCols.challengeId, id)
        .eq(RimShotSessionCols.whoseTurn, expectedTurn)
        .select()
        .maybeSingle();

    if (row == null) return null;
    return RimShotSessionModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<void> resetRimShotMatch({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'reset_rim_shot_match',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<void> ensureFantasyDuelSession({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'ensure_fantasy_duel_session',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<FantasyDuelSessionModel?> fetchFantasyDuelSession({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;

    final row = await supabaseClient
        .from(HomeTable.fantasyDuelSessions)
        .select()
        .eq(FantasyDuelSessionCols.challengeId, id)
        .maybeSingle();

    if (row == null) return null;
    return FantasyDuelSessionModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<bool> submitFantasyDuelTrio({
    required String challengeId,
    required bool asFrom,
    required List<int> trio,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    if (trio.length != 3) {
      throw ArgumentError.value(trio, 'trio', 'must have length 3');
    }

    final cur = await fetchFantasyDuelSession(challengeId: id);
    if (cur == null) return false;
    if (cur.matchComplete) return false;
    if (asFrom) {
      if (cur.fromTrio != null) return false;
    } else {
      if (cur.toTrio != null) return false;
    }

    final col = asFrom ? FantasyDuelSessionCols.fromTrio : FantasyDuelSessionCols.toTrio;
    await supabaseClient.from(HomeTable.fantasyDuelSessions).update({
      col: trio,
      FantasyDuelSessionCols.updatedAt: DateTime.now().toUtc().toIso8601String(),
    }).eq(FantasyDuelSessionCols.challengeId, id);
    return true;
  }

  @override
  Future<void> finishFantasyDuelRoundAndAdvance({
    required String challengeId,
    required int completedRound,
    required int fromRoundPoints,
    required int toRoundPoints,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'fantasy_duel_finish_round_and_advance',
      params: {
        'p_challenge_id': id,
        'p_completed_round': completedRound,
        'p_from_points': fromRoundPoints,
        'p_to_points': toRoundPoints,
      },
    );
  }

  @override
  Future<void> resetFantasyDuelMatch({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'reset_fantasy_duel_match',
      params: {'p_challenge_id': id},
    );
  }
}
