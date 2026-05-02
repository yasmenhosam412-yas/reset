import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';

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
    double? power,
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
}
