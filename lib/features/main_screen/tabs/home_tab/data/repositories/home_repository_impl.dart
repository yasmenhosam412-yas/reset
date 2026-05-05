import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_challenge_results.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDatasource homeDatasource;

  HomeRepositoryImpl({required this.homeDatasource});
  @override
  Future<Either<Failure, void>> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      await homeDatasource.addComment(postId: postId, comment: comment);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> togglePostLike({required String postId}) async {
    try {
      await homeDatasource.togglePostLike(postId: postId);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    try {
      await homeDatasource.addPost(
        postContent: postContent,
        postImage: postImage,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
      );
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost({required String postId}) async {
    try {
      await homeDatasource.deleteOwnPost(postId: postId);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getPosts() async {
    try {
      final result = await homeDatasource.getPosts();
      return Right(result);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getAcceptedFriendUserIds() async {
    try {
      final ids = await homeDatasource.getAcceptedFriendUserIds();
      return Right(ids);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendChallengeRequest(
    UserModel userModel,
    int gameId,
  ) async {
    try {
      await homeDatasource.sendChallengeRequest(
        userModel,
        gameId,
      );
      return Right(null);
    } catch (e) {
      final blob = '$e'.toLowerCase();
      if (blob.contains('recipient_does_not_accept')) {
        return Left(
          ServerFailure(
            message:
                'That player is not accepting match invites right now.',
          ),
        );
      }
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendFriendRequest(UserModel userModel) async {
    try {
      await homeDatasource.sendFriendRequest(userModel);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, ProfileDashboardModel>> loadProfileDashboard() async {
    try {
      final result = await homeDatasource.loadProfileDashboard();
      return Right(result);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateAcceptsMatchInvites(bool accepts) async {
    try {
      await homeDatasource.updateAcceptsMatchInvites(accepts);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updatePushNotificationsEnabled(
    bool enabled,
  ) async {
    try {
      await homeDatasource.updatePushNotificationsEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyProfile({
    required String username,
    Uint8List? avatarBytes,
    String? avatarContentType,
  }) async {
    try {
      await homeDatasource.updateMyProfile(
        username: username,
        avatarBytes: avatarBytes,
        avatarContentType: avatarContentType,
      );
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      await homeDatasource.respondToFriendRequest(
        requestId: requestId,
        accept: accept,
      );
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  String _teamChallengeRpcError(Object? code) {
    switch ('$code') {
      case 'already_claimed':
        return 'You already claimed this reward today.';
      case 'requirements_not_met':
        return 'Finish the challenge requirement first, then try again.';
      case 'unknown_challenge':
        return 'Unknown challenge.';
      case 'not_authenticated':
        return 'Sign in to continue.';
      case 'not_enough_points':
        return 'Not enough skill points.';
      case 'no_squad_saved':
        return 'Save your squad to the cloud first (edit or create a team).';
      case 'bad_squad':
      case 'bad_slot':
      case 'bad_stat':
        return 'Could not apply training.';
      case 'stat_maxed':
        return 'That stat is already maxed out.';
      default:
        return 'Something went wrong.';
    }
  }

  @override
  Future<Either<Failure, TeamCloudSnapshot>> fetchTeamCloudSnapshot() async {
    try {
      final s = await homeDatasource.fetchTeamCloudSnapshot();
      return Right(s);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> upsertMyTeamSquad(
    Map<String, dynamic> squadJson,
  ) async {
    try {
      await homeDatasource.upsertMyTeamSquad(squadJson);
      return const Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, TeamChallengeClaimResult>> claimTeamDailyChallenge(
    String challengeKey,
  ) async {
    try {
      final m = await homeDatasource.rpcClaimTeamDailyChallenge(challengeKey);
      if (m['ok'] == true) {
        return Right(
          TeamChallengeClaimResult(
            pointsAwarded: (m['points_awarded'] as num?)?.toInt() ?? 0,
            balanceAfter: (m['balance'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      return Left(
        ServerFailure(message: _teamChallengeRpcError(m['error'])),
      );
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, TeamTrainPlayerResult>> trainTeamPlayerStat({
    required int playerSlot,
    required String statKey,
  }) async {
    try {
      final m = await homeDatasource.rpcTrainTeamPlayer(
        playerSlot: playerSlot,
        statKey: statKey,
      );
      if (m['ok'] == true) {
        final squadRaw = m['team_squad'];
        if (squadRaw is! Map) {
          return Left(ServerFailure(message: 'Invalid training response.'));
        }
        return Right(
          TeamTrainPlayerResult(
            balanceAfter: (m['balance'] as num?)?.toInt() ?? 0,
            squadJson: Map<String, dynamic>.from(squadRaw),
          ),
        );
      }
      return Left(
        ServerFailure(message: _teamChallengeRpcError(m['error'])),
      );
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  String _sparRpcError(Object? code) {
    switch ('$code') {
      case 'not_authenticated':
        return 'Sign in to continue.';
      case 'cannot_spar_self':
        return 'Pick a friend to spar.';
      case 'not_friends':
        return 'You can only spar accepted friends.';
      case 'already_sparred':
        return 'You two already sparred today (UTC). Try again tomorrow.';
      case 'no_squad_saved':
        return 'Save your squad to the cloud first.';
      case 'opponent_no_squad':
        return 'Their squad is not saved yet — ask them to open Team tab.';
      case 'bad_squad':
        return 'Squad data is invalid. Check both teams have six players.';
      default:
        return 'Could not run squad battle.';
    }
  }

  TeamSquadSparStatDelta? _parseSparStatDelta(dynamic raw) {
    if (raw is! Map) return null;
    final o = Map<String, dynamic>.from(raw);
    return TeamSquadSparStatDelta(
      slotIndex: (o['slot'] as num?)?.toInt() ?? 0,
      statKey: o['stat']?.toString() ?? '',
      before: (o['before'] as num?)?.toInt() ?? 0,
      after: (o['after'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<Either<Failure, TeamSquadSparResult>> claimTeamSquadSpar(
    String opponentUserId,
  ) async {
    try {
      final m = await homeDatasource.rpcClaimTeamSquadSpar(opponentUserId);
      if (m['ok'] == true) {
        Map<String, dynamic>? squadJson;
        final sqRaw = m['team_squad'];
        if (sqRaw is Map) {
          squadJson = Map<String, dynamic>.from(sqRaw);
        }
        return Right(
          TeamSquadSparResult(
            outcome: m['outcome']?.toString() ?? '',
            myScore: (m['my_score'] as num?)?.toInt() ?? 0,
            opponentScore: (m['opponent_score'] as num?)?.toInt() ?? 0,
            pointsAwarded: (m['points_awarded'] as num?)?.toInt() ?? 0,
            balanceAfter: (m['balance'] as num?)?.toInt() ?? 0,
            squadJson: squadJson,
            statBonus: _parseSparStatDelta(m['stat_bonus']),
            statPenalty: _parseSparStatDelta(m['stat_penalty']),
          ),
        );
      }
      return Left(ServerFailure(message: _sparRpcError(m['error'])));
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  String _academyScrimRpcError(Object? code) {
    switch ('$code') {
      case 'not_authenticated':
        return 'Sign in to continue.';
      case 'already_scrimmed':
        return 'You already played the Academy friendly today (UTC). Come back tomorrow!';
      case 'no_squad_saved':
        return 'Save your squad to the cloud first.';
      case 'bad_squad':
        return 'Squad data is invalid. You need six players.';
      default:
        return 'Could not start Academy scrim.';
    }
  }

  @override
  Future<Either<Failure, TeamAcademyScrimResult>> claimTeamAcademyScrim() async {
    try {
      final m = await homeDatasource.rpcClaimTeamAcademyScrim();
      if (m['ok'] == true) {
        return Right(
          TeamAcademyScrimResult(
            outcome: m['outcome']?.toString() ?? '',
            myScore: (m['my_score'] as num?)?.toInt() ?? 0,
            opponentScore: (m['opponent_score'] as num?)?.toInt() ?? 0,
            opponentName: m['opponent_name']?.toString() ?? 'Academy XI',
            pointsAwarded: (m['points_awarded'] as num?)?.toInt() ?? 0,
            balanceAfter: (m['balance'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      return Left(ServerFailure(message: _academyScrimRpcError(m['error'])));
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  String _lineupRaceRpcError(Object? code) {
    switch ('$code') {
      case 'not_authenticated':
        return 'Sign in to continue.';
      case 'bad_race_key':
      case 'unknown_race':
        return 'Invalid race.';
      case 'no_squad_saved':
        return 'Save your squad first, then enter the race.';
      case 'bad_squad':
      case 'bad_score':
        return 'Squad could not be scored.';
      default:
        return 'Could not submit lineup.';
    }
  }

  @override
  Future<Either<Failure, List<LineupRaceBoardRow>>> fetchLineupRaceLeaderboard({
    required String raceKey,
    int limit = 40,
  }) async {
    try {
      final rows = await homeDatasource.fetchLineupRaceLeaderboard(
        raceKey: raceKey,
        limit: limit,
      );
      return Right(rows);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, int>> submitLineupRaceEntry(String raceKey) async {
    try {
      final m = await homeDatasource.rpcSubmitTeamLineupRace(raceKey);
      if (m['ok'] == true) {
        final sc = m['score'];
        final score = sc is int ? sc : (sc is num ? sc.toInt() : 0);
        return Right(score);
      }
      return Left(
        ServerFailure(message: _lineupRaceRpcError(m['error'])),
      );
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<UserFeedNotificationModel>>> getMyUserNotifications({
    int limit = 50,
  }) async {
    try {
      final list = await homeDatasource.fetchMyUserNotifications(limit: limit);
      return Right(list);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }
}
