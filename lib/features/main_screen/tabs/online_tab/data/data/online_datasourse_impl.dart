import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/data/online_datasourse.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rps_session_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineDatasourseImpl implements OnlineDatasourse {
  OnlineDatasourseImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Friends who opted out of match invites are hidden from Online challenge lists.
  static bool _profileAcceptsMatchInvites(dynamic row) {
    if (row == null) return true;
    if (row is! Map) return true;
    final m = Map<String, dynamic>.from(row);
    final raw = m[ProfileCols.acceptsMatchInvites];
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.toLowerCase();
      if (s == 'false' || s == 'f' || s == '0') return false;
    }
    return true;
  }

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
    var challenges = rows
        .map(
          (e) => ChallengeRequestModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);

    final meRow = await supabaseClient
        .from(HomeTable.profiles)
        .select(ProfileCols.acceptsMatchInvites)
        .eq(ProfileCols.id, uid)
        .maybeSingle();

    final acceptIncoming = _profileAcceptsMatchInvites(meRow);
    if (!acceptIncoming) {
      challenges = challenges
          .where(
            (c) =>
                !(c.toId == uid && c.status.toLowerCase() == 'pending'),
          )
          .toList(growable: false);
    }

    challenges = await _mergeChallengeWinnerUserIds(challenges);
    challenges = await _applyFinishedSessionStatusOverrides(challenges);
    return challenges;
  }

  static DateTime? _parseIsoTimestamptz(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// RPS / fantasy used to leave `game_challenges.status` as `accepted` after
  /// the session finished. Profile and history expect `completed` + timestamps.
  Future<List<ChallengeRequestModel>> _applyFinishedSessionStatusOverrides(
    List<ChallengeRequestModel> challenges,
  ) async {
    final rpsIds = <String>[];
    final fantasyIds = <String>[];
    for (final c in challenges) {
      if (c.status.toLowerCase() != 'accepted') continue;
      final id = c.id?.trim();
      if (id == null || id.isEmpty) continue;
      if (c.gameId == 2) rpsIds.add(id);
      if (c.gameId == 3) fantasyIds.add(id);
    }

    final completedAtByChallenge = <String, DateTime>{};

    if (rpsIds.isNotEmpty) {
      final response = await supabaseClient
          .from(HomeTable.rpsSessions)
          .select(
            '${RpsSessionCols.challengeId}, ${RpsSessionCols.status}, '
            '${RpsSessionCols.updatedAt}',
          )
          .inFilter(RpsSessionCols.challengeId, rpsIds);
      for (final e in response as List<dynamic>) {
        final m = Map<String, dynamic>.from(e as Map);
        if ((m[RpsSessionCols.status]?.toString() ?? '').toLowerCase() !=
            'done') {
          continue;
        }
        final cid = m[RpsSessionCols.challengeId]?.toString().trim() ?? '';
        if (cid.isEmpty) continue;
        final at = _parseIsoTimestamptz(m[RpsSessionCols.updatedAt]) ??
            DateTime.now().toUtc();
        completedAtByChallenge[cid] = at;
      }
    }

    if (fantasyIds.isNotEmpty) {
      final response = await supabaseClient
          .from(HomeTable.fantasyDuelSessions)
          .select(
            '${FantasyDuelSessionCols.challengeId}, '
            '${FantasyDuelSessionCols.matchComplete}, '
            '${FantasyDuelSessionCols.updatedAt}',
          )
          .inFilter(FantasyDuelSessionCols.challengeId, fantasyIds);
      for (final e in response as List<dynamic>) {
        final m = Map<String, dynamic>.from(e as Map);
        final rawComplete = m[FantasyDuelSessionCols.matchComplete];
        final complete = rawComplete is bool
            ? rawComplete
            : rawComplete is num && rawComplete != 0;
        if (!complete) continue;
        final cid =
            m[FantasyDuelSessionCols.challengeId]?.toString().trim() ?? '';
        if (cid.isEmpty) continue;
        final at = _parseIsoTimestamptz(
              m[FantasyDuelSessionCols.updatedAt],
            ) ??
            DateTime.now().toUtc();
        completedAtByChallenge[cid] = at;
      }
    }

    if (completedAtByChallenge.isEmpty) return challenges;

    return challenges
        .map((c) {
          final id = c.id?.trim();
          if (id == null || id.isEmpty) return c;
          final at = completedAtByChallenge[id];
          if (at == null) return c;
          if (c.status.toLowerCase() != 'accepted') return c;
          return c.copyWith(
            status: 'completed',
            completedAt: c.completedAt ?? at,
          );
        })
        .toList(growable: false);
  }

  /// Loads [online_challenge_skill_rewards] in one round-trip (embedded selects
  /// can break or omit data depending on PostgREST / RLS).
  Future<List<ChallengeRequestModel>> _mergeChallengeWinnerUserIds(
    List<ChallengeRequestModel> challenges,
  ) async {
    final ids = <String>[];
    for (final c in challenges) {
      final id = c.id?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return challenges;

    final response = await supabaseClient
        .from(HomeTable.onlineChallengeSkillRewards)
        .select(
          '${OnlineChallengeSkillRewardCols.challengeId}, '
          '${OnlineChallengeSkillRewardCols.winnerUserId}',
        )
        .inFilter(OnlineChallengeSkillRewardCols.challengeId, ids);

    final winnerByChallenge = <String, String>{};
    for (final e in response as List<dynamic>) {
      final m = Map<String, dynamic>.from(e as Map);
      final cid =
          m[OnlineChallengeSkillRewardCols.challengeId]?.toString().trim() ??
              '';
      final w =
          m[OnlineChallengeSkillRewardCols.winnerUserId]?.toString().trim() ??
              '';
      if (cid.isNotEmpty && w.isNotEmpty) winnerByChallenge[cid] = w;
    }

    return challenges
        .map((c) {
          final id = c.id?.trim();
          if (id == null || id.isEmpty) return c;
          final w = winnerByChallenge[id];
          if (w == null || w.isEmpty) return c;
          return c.copyWith(winnerUserId: w);
        })
        .toList(growable: false);
  }

  Future<Set<String>> _blockedRelevantUserIds(String uid) async {
    final iBlocked = await supabaseClient
        .from(HomeTable.userBlocks)
        .select(UserBlockCols.blockedUserId)
        .eq(UserBlockCols.blockerUserId, uid);
    final blockedMe = await supabaseClient
        .from(HomeTable.userBlocks)
        .select(UserBlockCols.blockerUserId)
        .eq(UserBlockCols.blockedUserId, uid);
    final out = <String>{};
    for (final e in iBlocked as List<dynamic>) {
      final m = Map<String, dynamic>.from(e as Map);
      final id =
          m[UserBlockCols.blockedUserId]?.toString().trim().toLowerCase() ?? '';
      if (id.isNotEmpty) out.add(id);
    }
    for (final e in blockedMe as List<dynamic>) {
      final m = Map<String, dynamic>.from(e as Map);
      final id =
          m[UserBlockCols.blockerUserId]?.toString().trim().toLowerCase() ?? '';
      if (id.isNotEmpty) out.add(id);
    }
    return out;
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

    final blocked = await _blockedRelevantUserIds(uid);
    friendIds.removeWhere((fid) => blocked.contains(fid.trim().toLowerCase()));

    if (friendIds.isEmpty) return const [];

    final profiles = await supabaseClient
        .from(HomeTable.profiles)
        .select(
          '${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}, ${ProfileCols.acceptsMatchInvites}',
        )
        .inFilter(ProfileCols.id, friendIds.toList());

    final plist = (profiles as List<dynamic>).where((e) {
      return _profileAcceptsMatchInvites(e);
    }).toList(growable: false);

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
    final id = challengeId.trim().toLowerCase();
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
    final id = challengeId.trim().toLowerCase();
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
  }) async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot submit pick while signed out.');
    }
    final id = challengeId.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }

    final payload = <String, dynamic>{
      PenaltyPickCols.challengeId: id,
      PenaltyPickCols.roundIndex: roundIndex,
      PenaltyPickCols.userId: uid,
      PenaltyPickCols.pickKind: pickKind,
      PenaltyPickCols.direction: direction,
      PenaltyPickCols.power: null,
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
    final id = challengeId.trim().toLowerCase();
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
    final id = challengeId.trim().toLowerCase();
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
    final id = challengeId.trim().toLowerCase();
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
  Future<void> ensureRpsSession({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'ensure_rps_session',
      params: {'p_challenge_id': id},
    );
  }

  @override
  Future<RpsSessionModel?> fetchRpsSession({
    required String challengeId,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;

    final row = await supabaseClient
        .from(HomeTable.rpsSessions)
        .select()
        .eq(RpsSessionCols.challengeId, id)
        .maybeSingle();

    if (row == null) return null;
    return RpsSessionModel.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  @override
  Future<RpsPickSubmitResponse> submitRpsPick({
    required String challengeId,
    required bool asFrom,
    required String pick,
  }) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    final raw = await supabaseClient.rpc<dynamic>(
      'submit_rps_pick',
      params: {
        'p_challenge_id': id,
        'p_as_from': asFrom,
        'p_pick': pick,
      },
    );
    if (raw is! Map) {
      throw StateError('submit_rps_pick: expected map, got $raw');
    }
    return RpsPickSubmitResponse.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  @override
  Future<void> resetRpsMatch({required String challengeId}) async {
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(challengeId, 'challengeId', 'must not be empty');
    }
    await supabaseClient.rpc<void>(
      'reset_rps_match',
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
