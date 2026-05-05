import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_challenge_results.dart'
    show
        TeamAcademyScrimResult,
        TeamChallengeClaimResult,
        TeamSquadSparResult,
        TeamTrainPlayerResult;
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';

abstract class HomeRepository {
  Future<Either<Failure, void>> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  });

  Future<Either<Failure, void>> deletePost({required String postId});

  Future<Either<Failure, void>> addComment({
    required String postId,
    required String comment,
  });

  Future<Either<Failure, void>> togglePostLike({required String postId});

  Future<Either<Failure, List<PostModel>>> getPosts();

  Future<Either<Failure, List<UserFeedNotificationModel>>> getMyUserNotifications({
    int limit = 50,
  });

  Future<Either<Failure, Set<String>>> getAcceptedFriendUserIds();

  Future<Either<Failure, void>> sendFriendRequest(UserModel userModel);

  Future<Either<Failure, void>> sendChallengeRequest(
    UserModel userModel,
    int gameId,
  );

  Future<Either<Failure, ProfileDashboardModel>> loadProfileDashboard();

  Future<Either<Failure, void>> updateAcceptsMatchInvites(bool accepts);

  Future<Either<Failure, void>> updatePushNotificationsEnabled(bool enabled);

  Future<Either<Failure, void>> updateMyProfile({
    required String username,
    Uint8List? avatarBytes,
    String? avatarContentType,
  });

  Future<Either<Failure, void>> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });

  Future<Either<Failure, TeamCloudSnapshot>> fetchTeamCloudSnapshot();

  Future<Either<Failure, void>> upsertMyTeamSquad(Map<String, dynamic> squadJson);

  Future<Either<Failure, TeamChallengeClaimResult>> claimTeamDailyChallenge(
    String challengeKey,
  );

  Future<Either<Failure, TeamTrainPlayerResult>> trainTeamPlayerStat({
    required int playerSlot,
    required String statKey,
  });

  Future<Either<Failure, TeamSquadSparResult>> claimTeamSquadSpar(
    String opponentUserId,
  );

  Future<Either<Failure, TeamAcademyScrimResult>> claimTeamAcademyScrim();

  Future<Either<Failure, List<LineupRaceBoardRow>>> fetchLineupRaceLeaderboard({
    required String raceKey,
    int limit = 40,
  });

  Future<Either<Failure, int>> submitLineupRaceEntry(String raceKey);
}
