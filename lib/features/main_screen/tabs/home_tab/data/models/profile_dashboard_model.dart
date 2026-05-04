import 'package:new_project/features/authentication/data/models/user_model.dart';

class UserProfileStats {
  const UserProfileStats({
    required this.postsCount,
    required this.friendsCount,
    required this.challengesCount,
  });

  final int postsCount;
  final int friendsCount;
  final int challengesCount;
}

class IncomingFriendRequestModel {
  const IncomingFriendRequestModel({
    required this.requestId,
    required this.fromUser,
    this.createdAt,
  });

  final String requestId;
  final UserModel fromUser;
  final DateTime? createdAt;
}

class ProfileDashboardModel {
  const ProfileDashboardModel({
    required this.user,
    required this.stats,
    required this.incomingFriendRequests,
    this.email,
    this.acceptsMatchInvites = true,
    this.pushNotificationsEnabled = true,
  });

  final UserModel user;
  final String? email;
  final UserProfileStats stats;
  final List<IncomingFriendRequestModel> incomingFriendRequests;

  /// When false, user does not receive online match invites and is hidden from challengers' friend lists.
  final bool acceptsMatchInvites;

  /// Server-side gate for FCM enqueue ([profiles.push_notifications_enabled]).
  final bool pushNotificationsEnabled;
}
