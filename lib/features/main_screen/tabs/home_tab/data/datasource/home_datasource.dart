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
    /// Native file path (e.g. gallery video on Android/iOS); uploads without loading full file into RAM when set.
    String? mediaLocalPath,
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

  /// Deletes a comment authored by the signed-in user ([commentId] must match).
  Future<void> deleteOwnComment({required String commentId});

  /// Blocks [blockedUserId], clears friend links and pending challenges with them.
  Future<void> blockUser({required String blockedUserId});

  /// Removes a row where the signed-in user is the blocker ([blockedUserId] is the other party).
  Future<void> unblockUser({required String blockedUserId});

  /// Profiles for users the signed-in user has blocked (most recent first).
  Future<List<UserModel>> listUsersIBlocked();

  /// Inserts a moderation report row for staff review.
  Future<void> reportUser({
    required String reportedUserId,
    String? reason,
    String? details,
    Map<String, dynamic>? context,
  });

  /// Sets the current user's reaction, or clears it when [reaction] is null.
  Future<void> setPostReaction({
    required String postId,
    String? reaction,
  });

  Future<List<PostModel>> getPosts({
    required int limit,
    required int offset,
  });

  /// Posts by [authorUserId] visible to the signed-in user (same rules as [getPosts]).
  Future<List<PostModel>> getPostsForAuthor({
    required String authorUserId,
    required int limit,
    required int offset,
  });

  /// Username search (ilike) for players other than the signed-in user, with friend-request state.
  Future<List<PeopleDiscoveryRow>> searchPeopleDiscovery(String query);

  /// In-app inbox: likes, comments, and friend requests for the signed-in user.
  Future<List<UserFeedNotificationModel>> fetchMyUserNotifications({int limit = 50});

  /// User ids with an accepted `friend_requests` row involving the current user.
  Future<Set<String>> getAcceptedFriendUserIds();

  /// User ids the signed-in user has a **pending** outgoing `friend_requests` row to.
  Future<Set<String>> getPendingOutgoingFriendUserIds();

  /// Profiles for accepted friends (e.g. @-mentions in comments).
  Future<List<UserModel>> fetchAcceptedFriendsProfiles();

  Future<void> sendFriendRequest(UserModel userModel);

  /// Deletes the pending outgoing request from the signed-in user to [userModel].
  Future<void> withdrawOutgoingFriendRequest(UserModel userModel);

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

  /// Subset of [postIds] that the signed-in user has bookmarked.
  Future<Set<String>> getSavedPostIdsAmong(Iterable<String> postIds);

  /// Adds or removes a bookmark for the signed-in user.
  Future<void> setPostSaved({required String postId, required bool saved});

  /// Saved posts ordered by most recently saved first (visibility rules match [getPosts]).
  Future<List<PostModel>> getSavedPosts({required int limit, required int offset});
}
