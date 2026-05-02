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
  });

  final UserModel user;
  final String? email;
  final UserProfileStats stats;
  final List<IncomingFriendRequestModel> incomingFriendRequests;
}
