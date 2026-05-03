import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';

abstract class HomeDatasource {
  Future<void> addPost({
    required String postContent,
    String postImage,
    Uint8List? imageBytes,
    String? imageContentType,
  });

  Future<void> addComment({required String postId, required String comment});

  Future<void> togglePostLike({required String postId});

  Future<List<PostModel>> getPosts();

  /// User ids with an accepted `friend_requests` row involving the current user.
  Future<Set<String>> getAcceptedFriendUserIds();

  Future<void> sendFriendRequest(UserModel userModel);

  Future<void> sendChallengeRequest(UserModel userModel, int gameId);

  Future<ProfileDashboardModel> loadProfileDashboard();

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });

  Future<TeamCloudSnapshot> fetchTeamCloudSnapshot();

  Future<void> upsertMyTeamSquad(Map<String, dynamic> squadJson);

  Future<Map<String, dynamic>> rpcClaimTeamDailyChallenge(String key);

  Future<Map<String, dynamic>> rpcTrainTeamPlayer({
    required int playerSlot,
    required String statKey,
  });

  Future<List<LineupRaceBoardRow>> fetchLineupRaceLeaderboard({
    required String raceKey,
    int limit = 40,
  });

  Future<Map<String, dynamic>> rpcSubmitTeamLineupRace(String raceKey);
}
