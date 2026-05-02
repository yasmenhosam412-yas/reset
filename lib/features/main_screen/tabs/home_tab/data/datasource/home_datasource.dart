import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';

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

  Future<void> sendFriendRequest(UserModel userModel);

  Future<void> sendChallengeRequest(UserModel userModel, int gameId);

  Future<ProfileDashboardModel> loadProfileDashboard();

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  });
}
