import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/data/online_datasourse.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/game_challenge_sides_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/penalty_shootout_online_models.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/fantasy_duel_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/rim_shot_session_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class OnlineRepositoryImpl implements OnlineRepository {
  final OnlineDatasourse onlineDatasourse;

  OnlineRepositoryImpl({required this.onlineDatasourse});

  @override
  Future<Either<Failure, void>> changeChallengeStatus({
    required String challengeId,
    required String status,
  }) async {
    try {
      await onlineDatasourse.changeChallengeStatus(
        challengeId: challengeId,
        status: status,
      );
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeRequestModel>>> getChallenges() async {
    try {
      final result = await onlineDatasourse.getChallenges();
      return Right(result);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getFriends() async {
    try {
      final result = await onlineDatasourse.getFriends();
      return Right(result);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> setChallengeReady({
    required String challengeId,
  }) async {
    try {
      final bothReady = await onlineDatasourse.setChallengeReady(
        challengeId: challengeId,
      );
      return Right(bothReady);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> ensurePenaltyShootoutSession({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.ensurePenaltyShootoutSession(
        challengeId: challengeId,
      );
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, PenaltyShootoutSessionModel?>>
      fetchPenaltyShootoutSession({
    required String challengeId,
  }) async {
    try {
      final row = await onlineDatasourse.fetchPenaltyShootoutSession(
        challengeId: challengeId,
      );
      return Right(row);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> upsertPenaltyRoundPick({
    required String challengeId,
    required int roundIndex,
    required String pickKind,
    required int direction,
    double? power,
  }) async {
    try {
      await onlineDatasourse.upsertPenaltyRoundPick(
        challengeId: challengeId,
        roundIndex: roundIndex,
        pickKind: pickKind,
        direction: direction,
        power: power,
      );
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<PenaltyRoundPickModel>>> fetchPenaltyRoundPicks({
    required String challengeId,
    required int roundIndex,
  }) async {
    try {
      final list = await onlineDatasourse.fetchPenaltyRoundPicks(
        challengeId: challengeId,
        roundIndex: roundIndex,
      );
      return Right(list);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> advancePenaltyRound({
    required String challengeId,
    required int expectedRoundIndex,
    required int fromGoalsDelta,
    required int toGoalsDelta,
  }) async {
    try {
      final ok = await onlineDatasourse.advancePenaltyRound(
        challengeId: challengeId,
        expectedRoundIndex: expectedRoundIndex,
        fromGoalsDelta: fromGoalsDelta,
        toGoalsDelta: toGoalsDelta,
      );
      return Right(ok);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, GameChallengeSidesModel?>> fetchGameChallengeSides({
    required String challengeId,
  }) async {
    try {
      final row = await onlineDatasourse.fetchGameChallengeSides(
        challengeId: challengeId,
      );
      return Right(row);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> finishPenaltyMatchCleanup({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.finishPenaltyMatchCleanup(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> abandonOnlineGameSession({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.abandonOnlineGameSession(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> ensureRimShotSession({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.ensureRimShotSession(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, RimShotSessionModel?>> fetchRimShotSession({
    required String challengeId,
  }) async {
    try {
      final row = await onlineDatasourse.fetchRimShotSession(
        challengeId: challengeId,
      );
      return Right(row);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
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
  }) async {
    try {
      final row = await onlineDatasourse.tryApplyRimShotTurn(
        challengeId: challengeId,
        expectedTurn: expectedTurn,
        power: power,
        aim: aim,
        made: made,
        nextScoreFrom: nextScoreFrom,
        nextScoreTo: nextScoreTo,
        nextTurn: nextTurn,
        status: status,
        nextRoundSeq: nextRoundSeq,
      );
      return Right(row);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetRimShotMatch({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.resetRimShotMatch(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> ensureFantasyDuelSession({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.ensureFantasyDuelSession(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, FantasyDuelSessionModel?>> fetchFantasyDuelSession({
    required String challengeId,
  }) async {
    try {
      final row = await onlineDatasourse.fetchFantasyDuelSession(
        challengeId: challengeId,
      );
      return Right(row);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> submitFantasyDuelTrio({
    required String challengeId,
    required bool asFrom,
    required List<int> trio,
  }) async {
    try {
      final ok = await onlineDatasourse.submitFantasyDuelTrio(
        challengeId: challengeId,
        asFrom: asFrom,
        trio: trio,
      );
      return Right(ok);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> finishFantasyDuelRoundAndAdvance({
    required String challengeId,
    required int completedRound,
    required int fromRoundPoints,
    required int toRoundPoints,
  }) async {
    try {
      await onlineDatasourse.finishFantasyDuelRoundAndAdvance(
        challengeId: challengeId,
        completedRound: completedRound,
        fromRoundPoints: fromRoundPoints,
        toRoundPoints: toRoundPoints,
      );
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetFantasyDuelMatch({
    required String challengeId,
  }) async {
    try {
      await onlineDatasourse.resetFantasyDuelMatch(challengeId: challengeId);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }
}
