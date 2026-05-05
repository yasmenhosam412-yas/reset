import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rps_session_model.dart';

abstract class OnlineDatasourse {
  Future<List<UserModel>> getFriends();

  Future<List<ChallengeRequestModel>> getChallenges();

  Future<void> changeChallengeStatus({
    required String challengeId,
    required String status,
  });

  /// Sets ready for the current user (`from_ready` or `to_ready`). Returns
  /// whether both players are ready after the update.
  Future<bool> setChallengeReady({required String challengeId});

  Future<void> ensurePenaltyShootoutSession({required String challengeId});

  Future<PenaltyShootoutSessionModel?> fetchPenaltyShootoutSession({
    required String challengeId,
  });

  Future<void> upsertPenaltyRoundPick({
    required String challengeId,
    required int roundIndex,
    required String pickKind,
    required int direction,
  });

  Future<List<PenaltyRoundPickModel>> fetchPenaltyRoundPicks({
    required String challengeId,
    required int roundIndex,
  });

  /// Returns whether this client performed the advancing update (false if
  /// another device already advanced the same round).
  Future<bool> advancePenaltyRound({
    required String challengeId,
    required int expectedRoundIndex,
    required int fromGoalsDelta,
    required int toGoalsDelta,
  });

  Future<GameChallengeSidesModel?> fetchGameChallengeSides({
    required String challengeId,
  });

  /// Marks the challenge completed and deletes penalty session + picks.
  Future<void> finishPenaltyMatchCleanup({required String challengeId});

  /// Deletes all online session rows for this challenge and sets status to cancelled.
  Future<void> abandonOnlineGameSession({required String challengeId});

  Future<void> ensureRpsSession({required String challengeId});

  Future<RpsSessionModel?> fetchRpsSession({required String challengeId});

  Future<RpsPickSubmitResponse> submitRpsPick({
    required String challengeId,
    required bool asFrom,
    required String pick,
  });

  Future<void> resetRpsMatch({required String challengeId});

  Future<void> ensureFantasyDuelSession({required String challengeId});

  Future<FantasyDuelSessionModel?> fetchFantasyDuelSession({
    required String challengeId,
  });

  /// Writes [fromTrio] or [toTrio] if that column is still null (no overwrite).
  Future<bool> submitFantasyDuelTrio({
    required String challengeId,
    required bool asFrom,
    required List<int> trio,
  });

  /// Applies round points, clears trios, and bumps round + deck (or sets match over).
  /// Idempotent when both clients call after the same round.
  Future<void> finishFantasyDuelRoundAndAdvance({
    required String challengeId,
    required int completedRound,
    required int fromRoundPoints,
    required int toRoundPoints,
  });

  /// Full rematch on the same challenge (new deck seed, scores and trios cleared).
  Future<void> resetFantasyDuelMatch({required String challengeId});
}
