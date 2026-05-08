import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/people_discovery_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';

abstract class HomeDatasource {
  Future<void> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
    bool allowShare = true,
    String postVisibility = 'general',
    String postType = 'post',
    String? adLink,
  });

  /// Deletes a post authored by the signed-in user ([postId] must match).
  Future<void> deleteOwnPost({required String postId});

  /// Updates [post_content] and optionally [post_image] for the signed-in author.
  Future<void> updateOwnPost({
    required String postId,
    required String postContent,
    Uint8List? imageBytes,
    String? imageContentType,
    bool clearImage = false,
    required bool allowShare,
    String postVisibility = 'general',
    String postType = 'post',
    String? adLink,
  });

  Future<void> addComment({required String postId, required String comment});

  /// Sets the current user's reaction, or clears it when [reaction] is null.
  Future<void> setPostReaction({
    required String postId,
    String? reaction,
  });

  Future<List<PostModel>> getPosts({
    required int limit,
    required int offset,
  });

  /// Username search (ilike) for players other than the signed-in user, with friend-request state.
  Future<List<PeopleDiscoveryRow>> searchPeopleDiscovery(String query);

  /// In-app inbox: likes, comments, and friend requests for the signed-in user.
  Future<List<UserFeedNotificationModel>> fetchMyUserNotifications({int limit = 50});

  /// User ids with an accepted `friend_requests` row involving the current user.
  Future<Set<String>> getAcceptedFriendUserIds();

  Future<void> sendFriendRequest(UserModel userModel);

  Future<void> sendChallengeRequest(UserModel userModel, int gameId);

  Future<ProfileDashboardModel> loadProfileDashboard();

  /// Persists whether the user accepts online match invites (see [profiles.accepts_match_invites]).
  Future<void> updateAcceptsMatchInvites(bool accepts);

  /// Persists push preference (see [profiles.push_notifications_enabled]).
  Future<void> updatePushNotificationsEnabled(bool enabled);

  /// Updates [profiles] row and syncs auth user metadata for the current user.
  Future<void> updateMyProfile({
    required String username,
    Uint8List? avatarBytes,
    String? avatarContentType,
  });

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });

  /// Deletes the accepted [friend_requests] row between the signed-in user and [friendUserId].
  Future<void> removeAcceptedFriendship({required String friendUserId});

  Future<TeamCloudSnapshot> fetchTeamCloudSnapshot();

  Future<void> upsertMyTeamSquad(Map<String, dynamic> squadJson);

  Future<Map<String, dynamic>> rpcClaimTeamDailyChallenge(String key);

  Future<Map<String, dynamic>> rpcTrainTeamPlayer({
    required int playerSlot,
    required String statKey,
  });

  Future<Map<String, dynamic>> rpcClaimTeamSquadSpar(String opponentUserId);

  Future<Map<String, dynamic>> rpcClaimTeamAcademyScrim();

  Future<List<LineupRaceBoardRow>> fetchLineupRaceLeaderboard({
    required String raceKey,
    int limit = 40,
  });

  Future<Map<String, dynamic>> rpcSubmitTeamLineupRace(String raceKey);
}
