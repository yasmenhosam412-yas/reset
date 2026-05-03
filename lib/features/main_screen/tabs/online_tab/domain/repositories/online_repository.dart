import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rim_shot_session_model.dart';

abstract class OnlineRepository {
  Future<Either<Failure, List<UserModel>>> getFriends();

  Future<Either<Failure, List<ChallengeRequestModel>>> getChallenges();

  Future<Either<Failure, void>> changeChallengeStatus({
    required String challengeId,
    required String status,
  });

  Future<Either<Failure, bool>> setChallengeReady({
    required String challengeId,
  });

  Future<Either<Failure, void>> ensurePenaltyShootoutSession({
    required String challengeId,
  });

  Future<Either<Failure, PenaltyShootoutSessionModel?>> fetchPenaltyShootoutSession({
    required String challengeId,
  });

  Future<Either<Failure, void>> upsertPenaltyRoundPick({
    required String challengeId,
    required int roundIndex,
    required String pickKind,
    required int direction,
    double? power,
  });

  Future<Either<Failure, List<PenaltyRoundPickModel>>> fetchPenaltyRoundPicks({
    required String challengeId,
    required int roundIndex,
  });

  Future<Either<Failure, bool>> advancePenaltyRound({
    required String challengeId,
    required int expectedRoundIndex,
    required int fromGoalsDelta,
    required int toGoalsDelta,
  });

  Future<Either<Failure, GameChallengeSidesModel?>> fetchGameChallengeSides({
    required String challengeId,
  });

  Future<Either<Failure, void>> finishPenaltyMatchCleanup({
    required String challengeId,
  });

  /// Removes session state and cancels the challenge when the player leaves the match screen.
  Future<Either<Failure, void>> abandonOnlineGameSession({
    required String challengeId,
  });

  Future<Either<Failure, void>> ensureRimShotSession({
    required String challengeId,
  });

  Future<Either<Failure, RimShotSessionModel?>> fetchRimShotSession({
    required String challengeId,
  });

  Future<Either<Failure, RimShotSessionModel?>> tryApplyRimShotTurn({
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
  });

  Future<Either<Failure, void>> resetRimShotMatch({
    required String challengeId,
  });

  Future<Either<Failure, void>> ensureFantasyDuelSession({
    required String challengeId,
  });

  Future<Either<Failure, FantasyDuelSessionModel?>> fetchFantasyDuelSession({
    required String challengeId,
  });

  Future<Either<Failure, bool>> submitFantasyDuelTrio({
    required String challengeId,
    required bool asFrom,
    required List<int> trio,
  });

  Future<Either<Failure, void>> finishFantasyDuelRoundAndAdvance({
    required String challengeId,
    required int completedRound,
    required int fromRoundPoints,
    required int toRoundPoints,
  });

  Future<Either<Failure, void>> resetFantasyDuelMatch({
    required String challengeId,
  });
}
